import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/parsed_text_book.dart';
import 'package:textara/data/database/book_dao.dart';
import 'package:textara/data/database/database_helper.dart';
import 'package:textara/data/services/file_storage_service.dart';
import 'package:textara/data/services/epub_parser_service.dart';
import 'package:textara/data/services/fb2_parser_service.dart';
import 'package:textara/data/services/import_security_policy.dart';
import 'package:textara/data/services/mobi_import_service.dart';
import 'package:textara/data/services/txt_parser_service.dart';

class ImportResult {
  final bool success;
  final Book? book;
  final String? errorMessage;
  final String? sourceFileName;

  const ImportResult({
    required this.success,
    this.book,
    this.errorMessage,
    this.sourceFileName,
  });
}

class ImportService {
  final BookDao _bookDao;
  final FileStorageService _fileStorage;
  final EpubParserService _epubParser;
  final TxtParserService _txtParser;
  final Fb2ParserService _fb2Parser;
  final MobiImportService _mobiImport;
  final ImportSecurityPolicy _securityPolicy;
  final Uuid _uuid = const Uuid();

  ImportService(
    this._bookDao,
    this._fileStorage,
    this._epubParser, {
    TxtParserService? txtParser,
    Fb2ParserService? fb2Parser,
    MobiImportService? mobiImport,
    ImportSecurityPolicy? securityPolicy,
  })  : _txtParser = txtParser ?? TxtParserService(),
        _fb2Parser = fb2Parser ?? Fb2ParserService(),
        _mobiImport = mobiImport ?? MobiImportService(),
        _securityPolicy = securityPolicy ?? ImportSecurityPolicy();

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
      allowedExtensions: AppConstants.supportedExtensions,
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) {
      return [];
    }

    final results = <ImportResult>[];
    for (final file in result.files) {
      if (file.path == null) {
        results.add(
          ImportResult(
            success: false,
            sourceFileName: file.name,
            errorMessage:
                'Could not access “${file.name}”. Try copying it into local storage first.',
          ),
        );
        continue;
      }
      final importResult = await importFile(file.path!);
      results.add(
        ImportResult(
          success: importResult.success,
          book: importResult.book,
          errorMessage: importResult.errorMessage,
          sourceFileName: file.name,
        ),
      );
    }
    return results;
  }

  Future<ImportResult> importFile(String filePath) async {
    final sourceName = filePath.split('/').last.split('\\').last;
    try {
      final validation = await _securityPolicy.validateBookFile(filePath);
      if (!validation.isValid) {
        return ImportResult(
          success: false,
          sourceFileName: sourceName,
          errorMessage: validation.errorMessage,
        );
      }

      final bookId = _uuid.v4();
      final format = _formatForExtension(validation.extension);
      final fallbackTitle = _extractFileNameWithoutExtension(filePath);

      final destPath = await _fileStorage.copyBookToLibrary(filePath, bookId);
      final fileSize = validation.fileSizeBytes;

      String title = fallbackTitle;
      String author = 'Unknown Author';
      String? description;
      String? coverPath;
      String? language;
      String? publisher;
      int totalPages = 0;
      ParsedTextBook? textBook;

      try {
        switch (format) {
          case BookFormat.epub:
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
            break;

          case BookFormat.pdf:
            // pdfrx opens on demand; page count filled when first read.
            break;

          case BookFormat.txt:
            textBook = await _txtParser.parseFile(
              destPath,
              fallbackTitle: fallbackTitle,
            );
            break;

          case BookFormat.fb2:
            textBook = await _fb2Parser.parseFile(
              destPath,
              fallbackTitle: fallbackTitle,
            );
            break;

          case BookFormat.mobi:
            textBook = await _mobiImport.convertFile(
              destPath,
              fallbackTitle: fallbackTitle,
            );
            break;
        }
      } on MobiImportException catch (e) {
        await _fileStorage.deleteBookFile(destPath);
        return ImportResult(
          success: false,
          sourceFileName: sourceName,
          errorMessage: e.message,
        );
      } catch (e) {
        if (format == BookFormat.txt ||
            format == BookFormat.fb2 ||
            format == BookFormat.mobi) {
          await _fileStorage.deleteBookFile(destPath);
          return ImportResult(
            success: false,
            sourceFileName: sourceName,
            errorMessage: _friendlyParseError(format, e),
          );
        }
        // EPUB parse failure still keeps the file for best-effort open later.
      }

      if (textBook != null) {
        title = textBook.title;
        author = textBook.author;
        language = textBook.language ?? language;
        totalPages = textBook.chapters.length;
        await _indexTextChapters(bookId, textBook);
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
        sourceFileName: sourceName,
      );
    } catch (e) {
      return ImportResult(
        success: false,
        sourceFileName: sourceName,
        errorMessage: 'Import failed: ${e.toString()}',
      );
    }
  }

  BookFormat _formatForExtension(String extension) {
    switch (extension) {
      case 'epub':
        return BookFormat.epub;
      case 'pdf':
        return BookFormat.pdf;
      case 'txt':
        return BookFormat.txt;
      case 'fb2':
        return BookFormat.fb2;
      case 'mobi':
      case 'azw':
      case 'azw3':
        return BookFormat.mobi;
      default:
        return BookFormat.epub;
    }
  }

  String _friendlyParseError(BookFormat format, Object error) {
    switch (format) {
      case BookFormat.txt:
        return 'Could not read this TXT file. Check encoding and try again.';
      case BookFormat.fb2:
        return 'Could not parse this FB2 file. It may be damaged or incomplete.';
      case BookFormat.mobi:
        return 'Could not convert this MOBI/AZW file. '
            'If it is DRM-free classic MOBI, try again; otherwise convert to EPUB.';
      default:
        return 'Could not import this file: $error';
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

  Future<void> _indexTextChapters(String bookId, ParsedTextBook book) async {
    try {
      final db = await DatabaseHelper().database;
      final batch = db.batch();
      for (var i = 0; i < book.chapters.length; i++) {
        final chapter = book.chapters[i];
        batch.insert('full_text_search', {
          'book_id': bookId,
          'chapter_id': chapter.title,
          'content': _securityPolicy.boundedIndexContent(chapter.text),
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
