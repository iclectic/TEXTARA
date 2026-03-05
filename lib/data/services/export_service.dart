import 'dart:convert';
import 'dart:io';
import 'package:leaf_reader/core/constants/app_constants.dart';
import 'package:leaf_reader/domain/entities/backup_data.dart';
import 'package:leaf_reader/data/database/book_dao.dart';
import 'package:leaf_reader/data/database/annotation_dao.dart';
import 'package:leaf_reader/data/database/collection_dao.dart';
import 'package:leaf_reader/data/database/database_helper.dart';
import 'package:leaf_reader/data/services/file_storage_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportService {
  final BookDao _bookDao;
  final AnnotationDao _annotationDao;
  final CollectionDao _collectionDao;
  final FileStorageService _fileStorage;

  ExportService(
      this._bookDao, this._annotationDao, this._collectionDao, this._fileStorage);

  factory ExportService.create() {
    final dbHelper = DatabaseHelper();
    return ExportService(
      BookDao(dbHelper),
      AnnotationDao(dbHelper),
      CollectionDao(dbHelper),
      FileStorageService(),
    );
  }

  Future<String> exportBackup() async {
    final books = await _bookDao.getAllBooks();
    final highlights = await _annotationDao.getAllHighlights();
    final bookmarks = await _annotationDao.getAllBookmarks();
    final collections = await _collectionDao.getAllCollections();

    final backup = BackupData(
      version: AppConstants.appVersion,
      exportedAt: DateTime.now(),
      books: books,
      highlights: highlights,
      bookmarks: bookmarks,
      collections: collections,
    );

    final jsonString =
        const JsonEncoder.withIndent('  ').convert(backup.toJson());
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final fileName = 'leafreader_backup_$timestamp.json';
    final exportPath = await _fileStorage.getExportPath(fileName);
    final file = File(exportPath);
    await file.writeAsString(jsonString);
    return exportPath;
  }

  Future<BackupData?> importBackup(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final backup = BackupData.fromJson(json);

      if (!backup.isValid) return null;

      for (final book in backup.books) {
        await _bookDao.insertBook(book);
      }
      for (final highlight in backup.highlights) {
        await _annotationDao.insertHighlight(highlight);
      }
      for (final bookmark in backup.bookmarks) {
        await _annotationDao.insertBookmark(bookmark);
      }
      for (final collection in backup.collections) {
        await _collectionDao.insertCollection(collection);
      }

      return backup;
    } catch (e) {
      return null;
    }
  }

  Future<String> exportHighlightsToMarkdown(
      String bookId, String bookTitle) async {
    final highlights = await _annotationDao.getHighlightsForBook(bookId);
    final buffer = StringBuffer();
    buffer.writeln('# Highlights and Notes');
    buffer.writeln('## $bookTitle');
    buffer.writeln();
    buffer.writeln('Exported from LeafReader on ${DateTime.now().toLocal()}');
    buffer.writeln();

    for (final h in highlights) {
      buffer.writeln('---');
      buffer.writeln();
      buffer.writeln('> ${h.selectedText}');
      buffer.writeln();
      if (h.hasNote) {
        buffer.writeln('**Note:** ${h.note}');
        buffer.writeln();
      }
      buffer.writeln(
          '*Highlighted on ${h.createdAt.toLocal().toString().split('.').first}*');
      buffer.writeln();
    }

    final fileName =
        '${bookTitle.replaceAll(RegExp(r'[^\w\s]'), '')}_highlights.md';
    final exportPath = await _fileStorage.getExportPath(fileName);
    final file = File(exportPath);
    await file.writeAsString(buffer.toString());
    return exportPath;
  }

  Future<String> exportHighlightsToPdf(
      String bookId, String bookTitle) async {
    final highlights = await _annotationDao.getHighlightsForBook(bookId);

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          final widgets = <pw.Widget>[
            pw.Header(
              level: 0,
              child: pw.Text('Highlights and Notes',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Text(bookTitle, style: const pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 8),
            pw.Text(
                'Exported from LeafReader on ${DateTime.now().toLocal().toString().split('.').first}',
                style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 20),
          ];

          for (final h in highlights) {
            widgets.add(pw.Divider());
            widgets.add(pw.SizedBox(height: 8));
            widgets.add(
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    left: pw.BorderSide(
                      color: PdfColors.amber,
                      width: 3,
                    ),
                  ),
                ),
                child: pw.Text(h.selectedText,
                    style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
              ),
            );
            if (h.hasNote) {
              widgets.add(pw.SizedBox(height: 4));
              widgets.add(pw.Text('Note: ${h.note}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
            }
            widgets.add(pw.SizedBox(height: 8));
          }

          return widgets;
        },
      ),
    );

    final fileName =
        '${bookTitle.replaceAll(RegExp(r'[^\w\s]'), '')}_highlights.pdf';
    final exportPath = await _fileStorage.getExportPath(fileName);
    final file = File(exportPath);
    await file.writeAsBytes(await pdf.save());
    return exportPath;
  }
}
