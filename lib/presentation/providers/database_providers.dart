import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/data/database/annotation_dao.dart';
import 'package:textara/data/database/book_dao.dart';
import 'package:textara/data/database/collection_dao.dart';
import 'package:textara/data/database/database_helper.dart';
import 'package:textara/data/database/idea_thread_dao.dart';
import 'package:textara/data/repositories/sqlite_backup_repository.dart';
import 'package:textara/data/repositories/sqlite_library_repository.dart';
import 'package:textara/data/services/epub_parser_service.dart';
import 'package:textara/data/services/export_service.dart';
import 'package:textara/data/services/file_storage_service.dart';
import 'package:textara/data/services/import_service.dart';
import 'package:textara/domain/repositories/backup_repository.dart';
import 'package:textara/domain/repositories/library_repository.dart';

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

final bookDaoProvider = Provider<BookDao>((ref) {
  return BookDao(ref.watch(databaseHelperProvider));
});

final annotationDaoProvider = Provider<AnnotationDao>((ref) {
  return AnnotationDao(ref.watch(databaseHelperProvider));
});

final collectionDaoProvider = Provider<CollectionDao>((ref) {
  return CollectionDao(ref.watch(databaseHelperProvider));
});

final ideaThreadDaoProvider = Provider<IdeaThreadDao>((ref) {
  return IdeaThreadDao(ref.watch(databaseHelperProvider));
});

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) {
  return SqliteLibraryRepository(ref.watch(bookDaoProvider));
});

final fileStorageProvider = Provider<FileStorageService>((ref) {
  return FileStorageService();
});

final epubParserProvider = Provider<EpubParserService>((ref) {
  return EpubParserService();
});

final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService(
    ref.watch(bookDaoProvider),
    ref.watch(fileStorageProvider),
    ref.watch(epubParserProvider),
  );
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(
    ref.watch(bookDaoProvider),
    ref.watch(annotationDaoProvider),
    ref.watch(collectionDaoProvider),
    ref.watch(ideaThreadDaoProvider),
    ref.watch(fileStorageProvider),
  );
});

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return SqliteBackupRepository(ref.watch(exportServiceProvider));
});
