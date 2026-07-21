import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/data/database/book_dao.dart';
import 'package:textara/data/database/database_helper.dart';
import 'package:textara/data/services/file_storage_service.dart';
import 'package:textara/data/services/epub_parser_service.dart';
import 'package:textara/data/services/import_security_policy.dart';

class ImportResult {
  final bool success;
  final Book? book;
  final String? errorMessage;

  const ImportResult({required this.success, this.book, this.errorMessage});
}

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

  Future<List<ImportResult>> pickAndImportFiles() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub', 'pdf'],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    final results = <ImportResult>[];
    for (final file in result.files) {
      if (file.path == null) continue;
      final importResult = await importFile(file.path!);
      results.add(importResult);
    }
    return results;
  }

  Future<ImportResult> importFile(String filePath) async {
    try {
      final validation = await _securityPolicy.validateBookFile(filePath);
      if (!validation.isValid) {
        return ImportResult(
          success: false,
          errorMessage: validation.errorMessage,
        );
      }

      final bookId = _uuid.v4();
      final format = validation.extension == 'epub'
          ? BookFormat.epub
          : BookFormat.pdf;

      final destPath = await _fileStorage.copyBookToLibrary(filePath, bookId);
      final fileSize = validation.fileSizeBytes;

      String title = _extractFileNameWithoutExtension(filePath);
      String author = 'Unknown Author';
      String? description;
      String? coverPath;
      String? language;
      String? publisher;
      int totalPages = 0;

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
        } catch (e) {
          // Parsing failed but we still have the file
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
      return ImportResult(success: true, book: book);
    } catch (e) {
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
      for (int i = 0; i < chapterTexts.length; i++) {
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
