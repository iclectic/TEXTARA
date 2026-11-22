import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:textara/core/errors/app_failure.dart';
import 'package:textara/data/repositories/sqlite_backup_repository.dart';
import 'package:textara/data/services/export_service.dart';
import 'package:textara/domain/entities/backup_data.dart';

class _FakeExportService extends Mock implements ExportService {}

void main() {
  group('SqliteBackupRepository', () {
    test('exportBackup returns path from ExportService', () async {
      final export = _FakeExportService();
      when(() => export.exportBackup()).thenAnswer((_) async => '/tmp/b.json');
      final repo = SqliteBackupRepository(export);
      expect(await repo.exportBackup(), '/tmp/b.json');
    });

    test('exportBackup maps exceptions to BackupFailure', () async {
      final export = _FakeExportService();
      when(() => export.exportBackup()).thenThrow(Exception('disk full'));
      final repo = SqliteBackupRepository(export);
      expect(() => repo.exportBackup(), throwsA(isA<BackupFailure>()));
    });

    test('importBackup returns BackupData from ExportService', () async {
      final export = _FakeExportService();
      final backup = BackupData(
        version: '1.0.0',
        exportedAt: DateTime(2024, 1, 1),
        books: const [],
        highlights: const [],
        bookmarks: const [],
        collections: const [],
      );
      when(
        () => export.importBackup('/tmp/b.json'),
      ).thenAnswer((_) async => backup);
      final repo = SqliteBackupRepository(export);
      expect(await repo.importBackup('/tmp/b.json'), backup);
    });
  });
}
