import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:textara/data/services/import_security_policy.dart';

void main() {
  group('ImportSecurityPolicy', () {
    late Directory tempDir;
    late ImportSecurityPolicy policy;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('textara_import_policy_');
      policy = ImportSecurityPolicy();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('accepts a PDF with a matching file signature', () async {
      final file = File(p.join(tempDir.path, 'sample.pdf'));
      await file.writeAsBytes('%PDF-1.7\ncontent'.codeUnits);

      final result = await policy.validateBookFile(file.path);

      expect(result.isValid, true);
      expect(result.extension, 'pdf');
      expect(result.fileSizeBytes, greaterThan(0));
    });

    test('rejects a spoofed PDF extension', () async {
      final file = File(p.join(tempDir.path, 'sample.pdf'));
      await file.writeAsString('not a pdf');

      final result = await policy.validateBookFile(file.path);

      expect(result.isValid, false);
      expect(
        result.errorMessage,
        'This file does not appear to match its file type.',
      );
    });

    test('rejects unsupported book extensions', () async {
      final file = File(p.join(tempDir.path, 'sample.txt'));
      await file.writeAsString('plain text');

      final result = await policy.validateBookFile(file.path);

      expect(result.isValid, false);
      expect(
        result.errorMessage,
        'Unsupported file format. Textara supports EPUB and PDF files.',
      );
    });

    test('accepts JSON backups under the size limit', () async {
      final file = File(p.join(tempDir.path, 'backup.json'));
      await file.writeAsString('{"version":"1.0.0"}');

      final result = await policy.validateBackupFile(file.path);

      expect(result.isValid, true);
      expect(result.extension, 'json');
    });

    test('bounds indexed content and strips null characters', () {
      final content =
          '${List.filled(ImportSecurityPolicy.maxIndexedChapterChars + 5, 'a').join()}\u0000';

      final bounded = policy.boundedIndexContent(content);

      expect(bounded.length, ImportSecurityPolicy.maxIndexedChapterChars);
      expect(bounded.contains('\u0000'), false);
    });

    test('checks whether a path stays inside a directory', () {
      final inside = p.join(tempDir.path, 'books', 'book.epub');
      final outside = p.join(tempDir.parent.path, 'book.epub');

      expect(policy.isPathInsideDirectory(inside, tempDir.path), true);
      expect(policy.isPathInsideDirectory(outside, tempDir.path), false);
    });
  });
}
