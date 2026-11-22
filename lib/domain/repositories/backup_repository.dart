import 'package:textara/domain/entities/backup_data.dart';

/// Contract for backup export/restore workflows.
abstract class BackupRepository {
  /// Writes a JSON backup to disk and returns the file path.
  Future<String> exportBackup();

  /// Restores a backup transactionally. Returns null when validation fails
  /// or the transaction rolls back.
  Future<BackupData?> importBackup(String filePath);
}
