import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:html/parser.dart' as html_parser;
import 'package:textara/domain/entities/parsed_text_book.dart';

enum MobiImportFailureKind {
  notMobi,
  drmProtected,
  unsupportedCompression,
  unreadable,
}

class MobiImportException implements Exception {
  final MobiImportFailureKind kind;
  final String message;

  const MobiImportException(this.kind, this.message);

  @override
  String toString() => message;
}

/// Probes PalmDB MOBI/AZW containers. Never decrypts DRM.
///
/// Unprotected PalmDOC-compressed (or uncompressed) books can be converted
/// into chaptered text for the shared text reader. HUFF/CDIC Kindle compression
/// and DRM-protected files are rejected with clear copy.
class MobiImportService {
  Future<ParsedTextBook> convertFile(
    String filePath, {
    String? fallbackTitle,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    return convertBytes(
      bytes,
      fallbackTitle: fallbackTitle ?? _titleFromPath(filePath),
    );
  }

  ParsedTextBook convertBytes(
    Uint8List bytes, {
    required String fallbackTitle,
  }) {
    if (bytes.length < 80) {
      throw const MobiImportException(
        MobiImportFailureKind.notMobi,
        'This file is too small to be a MOBI/AZW book.',
      );
    }

    final type = ascii.decoder.convert(bytes.sublist(60, 64));
    final creator = ascii.decoder.convert(bytes.sublist(64, 68));
    if (type != 'BOOK' || (creator != 'MOBI' && creator != 'READ')) {
      throw const MobiImportException(
        MobiImportFailureKind.notMobi,
        'This file does not look like a MOBI/AZW book.',
      );
    }

    final recordCount = _u16(bytes, 76);
    if (recordCount < 1 || bytes.length < 78 + recordCount * 8) {
      throw const MobiImportException(
        MobiImportFailureKind.unreadable,
        'This MOBI file appears damaged.',
      );
    }

    final recordOffsets = <int>[];
    for (var i = 0; i < recordCount; i++) {
      recordOffsets.add(_u32(bytes, 78 + i * 8));
    }

    final firstStart = recordOffsets.first;
    final firstEnd = recordCount > 1 ? recordOffsets[1] : bytes.length;
    if (firstStart < 0 || firstEnd > bytes.length || firstEnd <= firstStart) {
      throw const MobiImportException(
        MobiImportFailureKind.unreadable,
        'This MOBI file appears damaged.',
      );
    }

    final header = bytes.sublist(firstStart, firstEnd);
    if (header.length < 16) {
      throw const MobiImportException(
        MobiImportFailureKind.unreadable,
        'This MOBI header is truncated.',
      );
    }

    final compression = _u16(header, 0);
    final encryption = _u16(header, 12);

    if (encryption != 0) {
      throw const MobiImportException(
        MobiImportFailureKind.drmProtected,
        'This MOBI/AZW file is DRM-protected. Textara never removes or bypasses '
        'DRM. Use a DRM-free EPUB, PDF, TXT, or FB2 export instead.',
      );
    }

    if (compression != 1 && compression != 2) {
      throw const MobiImportException(
        MobiImportFailureKind.unsupportedCompression,
        'This Kindle/MOBI file uses compression Textara cannot unpack yet '
        '(often AZW3/KF8). Convert it to EPUB or TXT, or use a classic '
        'DRM-free MOBI.',
      );
    }

    final textRecordCount = _u16(header, 8);
    if (textRecordCount <= 0 || textRecordCount >= recordCount) {
      throw const MobiImportException(
        MobiImportFailureKind.unreadable,
        'Could not locate MOBI text records.',
      );
    }

    final buffer = StringBuffer();
    for (var i = 1; i <= textRecordCount && i < recordOffsets.length; i++) {
      final start = recordOffsets[i];
      final end = i + 1 < recordOffsets.length
          ? recordOffsets[i + 1]
          : bytes.length;
      if (start >= end || end > bytes.length) continue;
      final record = bytes.sublist(start, end);
      final payload = compression == 2 ? _palmDocDecompress(record) : record;
      buffer.write(utf8.decode(payload, allowMalformed: true));
    }

    final rawHtml = buffer.toString();
    if (rawHtml.trim().isEmpty) {
      throw const MobiImportException(
        MobiImportFailureKind.unreadable,
        'No readable text was found in this MOBI file.',
      );
    }

    final title = _mobiTitle(header, fallbackTitle);
    final author = _mobiAuthor(header) ?? 'Unknown Author';
    final chapters = _chaptersFromHtml(rawHtml, title);

    return ParsedTextBook(
      title: title,
      author: author,
      chapters: chapters,
    );
  }

  /// Lightweight DRM / container probe used by import validation messaging.
  MobiImportFailureKind? probeFailure(Uint8List bytes) {
    try {
      convertBytes(bytes, fallbackTitle: 'probe');
      return null;
    } on MobiImportException catch (e) {
      return e.kind;
    } catch (_) {
      return MobiImportFailureKind.unreadable;
    }
  }

  bool looksLikeMobi(Uint8List bytes) {
    if (bytes.length < 68) return false;
    final type = ascii.decoder.convert(bytes.sublist(60, 64));
    final creator = ascii.decoder.convert(bytes.sublist(64, 68));
    return type == 'BOOK' && (creator == 'MOBI' || creator == 'READ');
  }

  bool hasDrm(Uint8List bytes) {
    if (!looksLikeMobi(bytes) || bytes.length < 90) return false;
    try {
      final recordCount = _u16(bytes, 76);
      if (recordCount < 1) return false;
      final firstStart = _u32(bytes, 78);
      if (firstStart + 14 >= bytes.length) return false;
      final encryption = _u16(bytes, firstStart + 12);
      return encryption != 0;
    } catch (_) {
      return false;
    }
  }

  List<TextChapter> _chaptersFromHtml(String rawHtml, String fallbackTitle) {
    final document = html_parser.parse(rawHtml);
    final text = (document.body?.text ?? rawHtml)
        .replaceAll('\r\n', '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
    if (text.isEmpty) {
      return [TextChapter(title: fallbackTitle, text: '')];
    }

    // Prefer explicit page-break markers when present.
    final breakSplit = text
        .split(RegExp(r'\n\s*(?:\*{3,}|_{3,})\s*\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    if (breakSplit.length > 1) {
      return [
        for (var i = 0; i < breakSplit.length; i++)
          TextChapter(title: 'Chapter ${i + 1}', text: breakSplit[i]),
      ];
    }

    const chunk = 10000;
    if (text.length <= chunk * 2) {
      return [TextChapter(title: fallbackTitle, text: text)];
    }

    final chapters = <TextChapter>[];
    var start = 0;
    var index = 1;
    while (start < text.length) {
      var end = (start + chunk).clamp(0, text.length);
      if (end < text.length) {
        final nl = text.indexOf('\n\n', end);
        if (nl != -1 && nl - end < 1000) end = nl;
      }
      final slice = text.substring(start, end).trim();
      if (slice.isNotEmpty) {
        chapters.add(TextChapter(title: 'Part $index', text: slice));
        index++;
      }
      start = end;
      while (start < text.length && text[start] == '\n') {
        start++;
      }
    }
    return chapters.isEmpty
        ? [TextChapter(title: fallbackTitle, text: text)]
        : chapters;
  }

  String _mobiTitle(Uint8List header, String fallback) {
    if (header.length < 0x58) return fallback;
    final magic = ascii.decoder.convert(header.sublist(16, 20));
    if (magic != 'MOBI') return fallback;
    final fullNameOffset = _u32(header, 0x54);
    final fullNameLength = _u32(header, 0x58);
    final start = fullNameOffset;
    final end = start + fullNameLength;
    if (start < 0 || end > header.length || fullNameLength <= 0) {
      return fallback;
    }
    final title = utf8.decode(header.sublist(start, end), allowMalformed: true)
        .trim();
    return title.isEmpty ? fallback : title;
  }

  String? _mobiAuthor(Uint8List header) {
    // Author usually lives in EXTH; skip full EXTH parse for this tranche.
    return null;
  }

  /// PalmDOC LZ77-style decompress (Mobipocket compression type 2).
  Uint8List _palmDocDecompress(Uint8List data) {
    final out = <int>[];
    var i = 0;
    while (i < data.length) {
      final b = data[i++];
      if (b == 0) {
        out.add(0);
      } else if (b <= 8) {
        final end = (i + b).clamp(0, data.length);
        out.addAll(data.sublist(i, end));
        i = end;
      } else if (b >= 0x80 && b < 0xC0) {
        if (i >= data.length) break;
        final b2 = data[i++];
        final distance = (((b << 8) | b2) >> 3) & 0x7FF;
        final length = (b2 & 0x7) + 3;
        for (var n = 0; n < length; n++) {
          final idx = out.length - distance;
          out.add(idx >= 0 && idx < out.length ? out[idx] : 0x20);
        }
      } else if (b >= 0xC0) {
        out.add(0x20);
        out.add(b ^ 0x80);
      } else {
        out.add(b);
      }
    }
    return Uint8List.fromList(out);
  }

  int _u16(Uint8List bytes, int offset) =>
      (bytes[offset] << 8) | bytes[offset + 1];

  int _u32(Uint8List bytes, int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];

  String _titleFromPath(String path) {
    final name = path.split('/').last.split('\\').last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }
}
