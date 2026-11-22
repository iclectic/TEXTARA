import 'package:flutter_test/flutter_test.dart';
import 'package:textara/core/errors/app_failure.dart';

void main() {
  group('AppFailure', () {
    test('ObjectAsAppFailure preserves AppFailure instances', () {
      const failure = ImportFailure(message: 'bad file', fileName: 'a.epub');
      expect(failure.toAppFailure(), same(failure));
    });

    test('ObjectAsAppFailure wraps unknown objects', () {
      final failure = Exception('boom').toAppFailure(fallback: 'Import failed');
      expect(failure, isA<UnknownFailure>());
      expect(failure.message, 'Import failed');
      expect(failure.cause, isA<Exception>());
    });

    test('equality uses message and cause', () {
      const a = BackupFailure(message: 'restore failed');
      const b = BackupFailure(message: 'restore failed');
      const c = BackupFailure(message: 'other');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
