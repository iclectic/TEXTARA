import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/data/services/mobi_import_service.dart';

class ImportSecurityValidation {
  final bool isValid;
  final String? errorMessage;
  final String extension;
  final int fileSizeBytes;

  const ImportSecurityValidation._({
    required this.isValid,
    this.errorMessage,
    required this.extension,
    required this.fileSizeBytes,
  });

  const ImportSecurityValidation.valid({
    required String extension,
    required int fileSizeBytes,
  }) : this._(
         isValid: true,
         extension: extension,
         fileSizeBytes: fileSizeBytes,
       );

  const ImportSecurityValidation.invalid(String errorMessage)
    : this._(
        isValid: false,
        errorMessage: errorMessage,
        extension: '',
        fileSizeBytes: 0,
      );
}

class ImportSecurityPolicy {
  static const int maxBookFileBytes = AppConstants.maxImportFileBytes;
  static const int maxBackupFileBytes = 50 * 1024 * 1024;
  static const int maxIndexedChapterChars = 250000;

  static const supportedBookExtensions = {
    'epub',
    'pdf',
    'txt',
    'fb2',
    'mobi',
    'azw',
    'azw3',
  };

  final MobiImportService _mobiImport;

  ImportSecurityPolicy({MobiImportService? mobiImport})
    : _mobiImport = mobiImport ?? MobiImportService();

  Future<ImportSecurityValidation> validateBookFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return const ImportSecurityValidation.invalid(
        'File not found. It may have been moved or deleted.',
      );
    }

    final stat = await file.stat();
    if (stat.type != FileSystemEntityType.file) {
      return const ImportSecurityValidation.invalid(
        'Choose a file, not a folder.',
      );
    }

    final extension = _extensionWithoutDot(filePath);
    if (!supportedBookExtensions.contains(extension)) {
      return ImportSecurityValidation.invalid(
        'Unsupported file format (.$extension). '
        'Textara supports ${AppConstants.supportedFormatsLabel}.',
      );
    }

    if (stat.size <= 0) {
      return const ImportSecurityValidation.invalid(
        'This file is empty and cannot be imported.',
      );
    }

    if (stat.size > maxBookFileBytes) {
      final limitMb = (maxBookFileBytes / (1024 * 1024)).round();
      return ImportSecurityValidation.invalid(
        'This file is too large to import safely '
        '(limit $limitMb MB).',
      );
    }

    if (!await _hasExpectedSignature(file, extension)) {
      return const ImportSecurityValidation.invalid(
        'This file does not appear to match its file type.',
      );
    }

    // Early DRM gate for Kindle containers so users get clear copy before
    // library copy / indexing work.
    if (extension == 'mobi' || extension == 'azw' || extension == 'azw3') {
      final headerBytes = await _readPrefix(file, 256 * 1024);
      if (_mobiImport.hasDrm(headerBytes)) {
        return const ImportSecurityValidation.invalid(
          'This MOBI/AZW file is DRM-protected. Textara never removes or '
          'bypasses DRM. Use a DRM-free EPUB, PDF, TXT, or FB2 instead.',
        );
      }
    }

    return ImportSecurityValidation.valid(
      extension: extension,
      fileSizeBytes: stat.size,
    );
  }

  Future<ImportSecurityValidation> validateBackupFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return const ImportSecurityValidation.invalid('Backup file not found.');
    }

    final stat = await file.stat();
    if (stat.type != FileSystemEntityType.file) {
      return const ImportSecurityValidation.invalid(
        'Choose a backup file, not a folder.',
      );
    }

    final extension = _extensionWithoutDot(filePath);
    if (extension != 'json') {
      return const ImportSecurityValidation.invalid(
        'Textara backups must be JSON files.',
      );
    }

    if (stat.size <= 0) {
      return const ImportSecurityValidation.invalid('This backup is empty.');
    }

    if (stat.size > maxBackupFileBytes) {
      return const ImportSecurityValidation.invalid(
        'This backup is too large to import safely.',
      );
    }

    return ImportSecurityValidation.valid(
      extension: extension,
      fileSizeBytes: stat.size,
    );
  }

  String boundedIndexContent(String content) {
    final normalized = sanitizeExportText(content);
    if (normalized.length <= maxIndexedChapterChars) return normalized;
    return normalized.substring(0, maxIndexedChapterChars);
  }

  String sanitizeExportText(String value) {
    return value.replaceAll('\u0000', '').replaceAll('\r\n', '\n');
  }

  bool isPathInsideDirectory(String filePath, String directoryPath) {
    final normalizedFile = p.normalize(p.absolute(filePath));
    final normalizedDirectory = p.normalize(p.absolute(directoryPath));
    return p.equals(normalizedFile, normalizedDirectory) ||
        p.isWithin(normalizedDirectory, normalizedFile);
  }

  String _extensionWithoutDot(String filePath) {
    return p.extension(filePath).replaceFirst('.', '').toLowerCase();
  }

  Future<Uint8List> _readPrefix(File file, int maxBytes) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.openRead(0, maxBytes)) {
      builder.add(chunk);
      if (builder.length >= maxBytes) break;
    }
    return builder.takeBytes();
  }

  Future<bool> _hasExpectedSignature(File file, String extension) async {
    final bytes = await _readPrefix(file, 16);
    switch (extension) {
      case 'pdf':
        return bytes.length >= 5 &&
            String.fromCharCodes(bytes.take(5)).startsWith('%PDF-');
      case 'epub':
        return bytes.length >= 4 &&
            bytes[0] == 0x50 &&
            bytes[1] == 0x4b &&
            (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07) &&
            (bytes[3] == 0x04 || bytes[3] == 0x06 || bytes[3] == 0x08);
      case 'txt':
        // Reject obvious binary blobs; allow UTF-8/latin text.
        return !_looksBinary(bytes);
      case 'fb2':
        final head = String.fromCharCodes(bytes).toLowerCase();
        return head.contains('<?xml') ||
            head.contains('<fictionbook') ||
            head.contains('<fiction');
      case 'mobi':
      case 'azw':
      case 'azw3':
        // Full PalmDB check needs offsets 60–68; read a larger prefix.
        final prefix = await _readPrefix(file, 80);
        return _mobiImport.looksLikeMobi(prefix);
      default:
        return false;
    }
  }

  bool _looksBinary(Uint8List bytes) {
    if (bytes.isEmpty) return true;
    var weird = 0;
    final sample = bytes.length < 16 ? bytes.length : 16;
    for (var i = 0; i < sample; i++) {
      final b = bytes[i];
      if (b == 0) return true;
      if (b < 7 || (b > 14 && b < 32)) weird++;
    }
    return weird > sample ~/ 2;
  }
}
