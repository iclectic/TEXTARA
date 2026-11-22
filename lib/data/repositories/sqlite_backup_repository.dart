import 'package:textara/core/errors/app_failure.dart';
import 'package:textara/data/services/export_service.dart';
import 'package:textara/domain/entities/backup_data.dart';
import 'package:textara/domain/repositories/backup_repository.dart';

class SqliteBackupRepository implements BackupRepository {
  final ExportService _exportService;

  SqliteBackupRepository(this._exportService);

  @override
  Future<String> exportBackup() async {
    try {
      return await _exportService.exportBackup();
    } catch (e) {
      throw BackupFailure(message: 'Could not export backup.', cause: e);
    }
  }

  @override
  Future<BackupData?> importBackup(String filePath) async {
    try {
      return await _exportService.importBackup(filePath);
    } catch (e) {
      throw BackupFailure(message: 'Could not restore backup.', cause: e);
    }
  }
}
