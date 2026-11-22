import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/data/database/book_dao.dart';
import 'package:textara/data/database/database_helper.dart';
import 'package:textara/data/services/epub_parser_service.dart';
import 'package:textara/data/services/file_storage_service.dart';
import 'package:textara/data/services/import_security_policy.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:uuid/uuid.dart';

class ImportResult {
  final bool success;
  final Book? book;
  final String? errorMessage;
  final bool skipped;
  final bool replaced;

  const ImportResult({
    required this.success,
    this.book,
    this.errorMessage,
    this.skipped = false,
    this.replaced = false,
  });
}

typedef DuplicateResolver =
    Future<DuplicateResolution> Function(Book existing, Book incoming);

class ImportService {
  final BookDao _bookDao;
  final FileStorageService _fileStorage;
  final EpubParserService _epubParser;
  final ImportSecurityPolicy _securityPolicy;
  final Uuid _uuid = const Uuid();

  ImportService(
    this._bookDao,
    this._fileStorage,
    this._epubParser, [
    ImportSecurityPolicy? securityPolicy,
  ]) : _securityPolicy = securityPolicy ?? ImportSecurityPolicy();

  factory ImportService.create() {
    final dbHelper = DatabaseHelper();
    return ImportService(
      BookDao(dbHelper),
      FileStorageService(),
      EpubParserService(),
    );
  }

  Future<List<ImportResult>> pickAndImportFiles({
    void Function(int completed, int total, String? fileName)? onProgress,
    bool Function()? isCancelled,
    DuplicateResolver? onDuplicate,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub', 'pdf'],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    final paths = result.files
        .where((f) => f.path != null)
        .map((f) => f.path!)
        .toList();

    return importPaths(
      paths,
      onProgress: onProgress,
      isCancelled: isCancelled,
      onDuplicate: onDuplicate,
    );
  }

  Future<List<ImportResult>> importPaths(
    List<String> paths, {
    void Function(int completed, int total, String? fileName)? onProgress,
    bool Function()? isCancelled,
    DuplicateResolver? onDuplicate,
  }) async {
    final results = <ImportResult>[];
    final batchSize = AppConstants.importBatchSize;

    for (var i = 0; i < paths.length; i++) {
      if (isCancelled?.call() == true) break;

      // Soft batching: yield between batches so the UI can paint progress.
      if (i > 0 && i % batchSize == 0) {
        await Future<void>.delayed(Duration.zero);
      }

      final path = paths[i];
      onProgress?.call(i, paths.length, p.basename(path));
      final importResult = await importFile(path, onDuplicate: onDuplicate);
      results.add(importResult);
      onProgress?.call(i + 1, paths.length, p.basename(path));
    }
    return results;
  }

  Future<ImportResult> importFile(
    String filePath, {
    DuplicateResolver? onDuplicate,
  }) async {
    String? destPath;
    String? coverPath;
    try {
      final validation = await _securityPolicy.validateBookFile(filePath);
      if (!validation.isValid) {
        return ImportResult(
          success: false,
          errorMessage: validation.errorMessage,
        );
      }

      final format = validation.extension == 'epub'
          ? BookFormat.epub
          : BookFormat.pdf;

      var title = _extractFileNameWithoutExtension(filePath);
      var author = 'Unknown Author';
      String? description;
      String? language;
      String? publisher;
      var totalPages = 0;
      final fileSize = validation.fileSizeBytes;

      // Peek metadata before copying when possible (EPUB).
      if (format == BookFormat.epub) {
        try {
          final peek = await _epubParser.parseEpub(filePath);
          title = _epubParser.extractTitle(peek);
          author = _epubParser.extractAuthor(peek);
          description = _epubParser.extractDescription(peek);
          language = _epubParser.extractLanguage(peek);
          publisher = _epubParser.extractPublisher(peek);
          totalPages = _epubParser.estimateTotalPages(peek);
        } catch (_) {
          // Fall through with filename metadata.
        }
      }

      final existing = await _bookDao.findDuplicate(
        title: title,
        author: author,
        fileSizeBytes: fileSize,
      );

      if (existing != null && onDuplicate != null) {
        final incomingStub = Book(
          id: existing.id,
          title: title,
          author: author,
          filePath: filePath,
          format: format,
          dateAdded: DateTime.now(),
          fileSizeBytes: fileSize,
        );
        final resolution = await onDuplicate(existing, incomingStub);
        if (resolution == DuplicateResolution.skip) {
          return ImportResult(success: true, book: existing, skipped: true);
        }
        if (resolution == DuplicateResolution.replace) {
          await _bookDao.deleteBook(existing.id);
          await _fileStorage.deleteBookFile(existing.filePath);
          await _fileStorage.deleteCoverFile(existing.coverPath);
        }
        // keepBoth falls through to insert a new row.
      }

      final bookId = _uuid.v4();
      destPath = await _fileStorage.copyBookToLibrary(filePath, bookId);

      if (format == BookFormat.epub) {
        try {
          final epubBook = await _epubParser.parseEpub(destPath);
          title = _epubParser.extractTitle(epubBook);
          author = _epubParser.extractAuthor(epubBook);
          description = _epubParser.extractDescription(epubBook);
          language = _epubParser.extractLanguage(epubBook);
          publisher = _epubParser.extractPublisher(epubBook);
          totalPages = _epubParser.estimateTotalPages(epubBook);

          final coverData = _epubParser.extractCoverImage(epubBook);
          if (coverData != null && coverData.isNotEmpty) {
            coverPath = await _fileStorage.saveCoverImage(coverData, bookId);
          }

          await _indexEpubContent(bookId, epubBook);
        } catch (_) {
          // Keep the copied file with filename-derived metadata when parse fails.
        }
      }

      final book = Book(
        id: bookId,
        title: title,
        author: author,
        description: description,
        filePath: destPath,
        format: format,
        coverPath: coverPath,
        dateAdded: DateTime.now(),
        fileSizeBytes: fileSize,
        language: language,
        publisher: publisher,
        totalPages: totalPages,
      );

      await _bookDao.insertBook(book);
      return ImportResult(
        success: true,
        book: book,
        replaced: existing != null,
      );
    } catch (e) {
      if (destPath != null) {
        await _fileStorage.deleteBookFile(destPath);
      }
      if (coverPath != null) {
        await _fileStorage.deleteCoverFile(coverPath);
      }
      return ImportResult(
        success: false,
        errorMessage: 'Import failed: ${e.toString()}',
      );
    }
  }

  Future<void> _indexEpubContent(String bookId, dynamic epubBook) async {
    try {
      final chapterTexts = _epubParser.getChapterTexts(epubBook);
      final db = await DatabaseHelper().database;
      final batch = db.batch();
      for (var i = 0; i < chapterTexts.length; i++) {
        batch.insert('full_text_search', {
          'book_id': bookId,
          'chapter_id': chapterTexts[i].key,
          'content': _securityPolicy.boundedIndexContent(chapterTexts[i].value),
          'chapter_order': i,
        });
      }
      await batch.commit(noResult: true);
    } catch (_) {
      // Full text indexing is best-effort
    }
  }

  String _extractFileNameWithoutExtension(String path) {
    final fileName = path.split('/').last.split('\\').last;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex > 0) {
      return fileName.substring(0, dotIndex);
    }
    return fileName;
  }
}
