import 'dart:convert';
import 'dart:io';

import 'package:textara/domain/entities/parsed_text_book.dart';

class TxtParserService {
  Future<ParsedTextBook> parseFile(String filePath, {String? fallbackTitle}) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final text = _decodeBytes(bytes);
    return parseText(
      text,
      fallbackTitle: fallbackTitle ?? _titleFromPath(filePath),
    );
  }

  ParsedTextBook parseText(String raw, {required String fallbackTitle}) {
    final normalized = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final trimmed = normalized.trim();
    if (trimmed.isEmpty) {
      return ParsedTextBook(
        title: fallbackTitle,
        author: 'Unknown Author',
        chapters: const [TextChapter(title: 'Text', text: '')],
      );
    }

    // Form-feed chapter breaks are common in plain-text exports.
    if (trimmed.contains('\f')) {
      final parts = trimmed
          .split('\f')
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
      if (parts.length > 1) {
        return ParsedTextBook(
          title: fallbackTitle,
          author: 'Unknown Author',
          chapters: [
            for (var i = 0; i < parts.length; i++)
              TextChapter(
                title: _chapterTitleFromBody(parts[i], i + 1),
                text: parts[i],
              ),
          ],
        );
      }
    }

    final headingSplit = _splitByHeadings(trimmed);
    if (headingSplit.length > 1) {
      return ParsedTextBook(
        title: fallbackTitle,
        author: 'Unknown Author',
        chapters: headingSplit,
      );
    }

    // Large single files: chunk for resumable chapter paging.
    const chunkSize = 12000;
    if (trimmed.length > chunkSize * 2) {
      final chapters = <TextChapter>[];
      var start = 0;
      var index = 1;
      while (start < trimmed.length) {
        var end = (start + chunkSize).clamp(0, trimmed.length);
        if (end < trimmed.length) {
          final nextBreak = trimmed.indexOf('\n\n', end);
          if (nextBreak != -1 && nextBreak - end < 800) {
            end = nextBreak;
          }
        }
        final slice = trimmed.substring(start, end).trim();
        if (slice.isNotEmpty) {
          chapters.add(TextChapter(title: 'Part $index', text: slice));
          index++;
        }
        start = end;
        while (start < trimmed.length &&
            (trimmed[start] == '\n' || trimmed[start] == ' ')) {
          start++;
        }
      }
      return ParsedTextBook(
        title: fallbackTitle,
        author: 'Unknown Author',
        chapters: chapters,
      );
    }

    return ParsedTextBook(
      title: fallbackTitle,
      author: 'Unknown Author',
      chapters: [TextChapter(title: fallbackTitle, text: trimmed)],
    );
  }

  List<TextChapter> _splitByHeadings(String text) {
    final pattern = RegExp(
      r'^(?:Chapter|CHAPTER|Part|PART|Book|BOOK)\s+[\wIVXLC\d][^\n]*$',
      multiLine: true,
    );
    final matches = pattern.allMatches(text).toList();
    if (matches.length < 2) return const [];

    final chapters = <TextChapter>[];
    if (matches.first.start > 0) {
      final preface = text.substring(0, matches.first.start).trim();
      if (preface.isNotEmpty) {
        chapters.add(TextChapter(title: 'Preface', text: preface));
      }
    }
    for (var i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = i + 1 < matches.length ? matches[i + 1].start : text.length;
      final block = text.substring(start, end).trim();
      if (block.isEmpty) continue;
      final firstLineEnd = block.indexOf('\n');
      final title = firstLineEnd == -1
          ? block
          : block.substring(0, firstLineEnd).trim();
      final body = firstLineEnd == -1 ? '' : block.substring(firstLineEnd).trim();
      chapters.add(
        TextChapter(
          title: title.isEmpty ? 'Chapter ${i + 1}' : title,
          text: body.isEmpty ? block : body,
        ),
      );
    }
    return chapters;
  }

  String _chapterTitleFromBody(String body, int index) {
    final firstLine = body.split('\n').first.trim();
    if (firstLine.length <= 80 &&
        RegExp(r'^(Chapter|CHAPTER|Part|PART)\b').hasMatch(firstLine)) {
      return firstLine;
    }
    return 'Chapter $index';
  }

  String _decodeBytes(List<int> bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }

  String _titleFromPath(String path) {
    final name = path.split('/').last.split('\\').last;
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }
}
