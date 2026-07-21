import 'dart:io';

import 'package:path/path.dart' as p;

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
  static const int maxBookFileBytes = 500 * 1024 * 1024;
  static const int maxBackupFileBytes = 50 * 1024 * 1024;
  static const int maxIndexedChapterChars = 250000;

  static const _supportedBookExtensions = {'epub', 'pdf'};

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
    if (!_supportedBookExtensions.contains(extension)) {
      return const ImportSecurityValidation.invalid(
        'Unsupported file format. Textara supports EPUB and PDF files.',
      );
    }

    if (stat.size <= 0) {
      return const ImportSecurityValidation.invalid(
        'This file is empty and cannot be imported.',
      );
    }

    if (stat.size > maxBookFileBytes) {
      return const ImportSecurityValidation.invalid(
        'This file is too large to import safely.',
      );
    }

    if (!await _hasExpectedSignature(file, extension)) {
      return const ImportSecurityValidation.invalid(
        'This file does not appear to match its file type.',
      );
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

  Future<bool> _hasExpectedSignature(File file, String extension) async {
    final bytes = await file
        .openRead(0, 8)
        .fold<List<int>>(<int>[], (buffer, chunk) => buffer..addAll(chunk));
    if (extension == 'pdf') {
      return bytes.length >= 5 &&
          String.fromCharCodes(bytes.take(5)).startsWith('%PDF-');
    }
    if (extension == 'epub') {
      return bytes.length >= 4 &&
          bytes[0] == 0x50 &&
          bytes[1] == 0x4b &&
          (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07) &&
          (bytes[3] == 0x04 || bytes[3] == 0x06 || bytes[3] == 0x08);
    }
    return false;
  }
}
