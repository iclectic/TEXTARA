import 'package:flutter_test/flutter_test.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/domain/entities/collection.dart';
import 'package:textara/domain/entities/backup_data.dart';
import 'package:textara/domain/entities/idea_thread.dart';

void main() {
  group('BackupData', () {
    late BackupData backup;
    late Book sampleBook;
    late Highlight sampleHighlight;
    late Bookmark sampleBookmark;
    late Collection sampleCollection;
    late IdeaThread sampleThread;
    late ThreadHighlightLink sampleThreadHighlightLink;

    setUp(() {
      sampleBook = Book(
        id: 'book-1',
        title: 'Test Book',
        author: 'Test Author',
        filePath: '/books/test.epub',
        format: BookFormat.epub,
        dateAdded: DateTime(2025, 1, 1),
        tags: ['fiction'],
      );

      sampleHighlight = Highlight(
        id: 'h-1',
        bookId: 'book-1',
        selectedText: 'Highlighted text',
        colour: HighlightColour.yellow,
        startOffset: 0,
        endOffset: 16,
        createdAt: DateTime(2025, 2, 1),
        updatedAt: DateTime(2025, 2, 1),
      );

      sampleBookmark = Bookmark(
        id: 'bm-1',
        bookId: 'book-1',
        pageNumber: 10,
        title: 'Chapter 2',
        createdAt: DateTime(2025, 2, 15),
      );

      sampleCollection = Collection(
        id: 'col-1',
        name: 'Favourites',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      sampleThread = IdeaThread(
        id: 'thread-1',
        title: 'Research question',
        createdAt: DateTime(2025, 2, 20),
        updatedAt: DateTime(2025, 2, 20),
      );
      sampleThreadHighlightLink = ThreadHighlightLink(
        threadId: 'thread-1',
        highlightId: 'h-1',
        sortOrder: 0,
        addedAt: DateTime(2025, 2, 20),
      );

      backup = BackupData(
        version: '1.0.0',
        exportedAt: DateTime(2025, 3, 1),
        books: [sampleBook],
        highlights: [sampleHighlight],
        bookmarks: [sampleBookmark],
        collections: [sampleCollection],
        ideaThreads: [sampleThread],
        threadHighlightLinks: [sampleThreadHighlightLink],
      );
    });

    test('isValid returns true for valid backup', () {
      expect(backup.isValid, true);
    });

    test('isValid returns false for empty version', () {
      final invalid = BackupData(
        version: '',
        exportedAt: DateTime.now(),
        books: [sampleBook],
        highlights: [],
        bookmarks: [],
        collections: [],
      );
      expect(invalid.isValid, false);
    });

    test('isValid returns false when book has empty id', () {
      final badBook = sampleBook.copyWith(id: '');
      final invalid = BackupData(
        version: '1.0.0',
        exportedAt: DateTime.now(),
        books: [badBook],
        highlights: [],
        bookmarks: [],
        collections: [],
      );
      expect(invalid.isValid, false);
    });

    test('isValid returns false when a highlight points at a missing book', () {
      final orphanHighlight = sampleHighlight.copyWith(bookId: 'missing-book');
      final invalid = BackupData(
        version: '1.0.0',
        exportedAt: DateTime.now(),
        books: [sampleBook],
        highlights: [orphanHighlight],
        bookmarks: [],
        collections: [],
      );
      expect(invalid.isValid, false);
      expect(
        invalid.validationErrors,
        contains('Highlight h-1 points at a missing book.'),
      );
    });

    test('isValid returns false when a thread link points at missing data', () {
      final invalid = BackupData(
        version: '1.0.0',
        exportedAt: DateTime.now(),
        books: [sampleBook],
        highlights: [sampleHighlight],
        bookmarks: [],
        collections: [],
        ideaThreads: [],
        threadHighlightLinks: [sampleThreadHighlightLink],
      );
      expect(invalid.isValid, false);
      expect(
        invalid.validationErrors,
        contains('Thread link points at a missing idea thread.'),
      );
    });

    test('toJson produces valid JSON map', () {
      final json = backup.toJson();
      expect(json['version'], '1.0.0');
      expect(json['books'], isList);
      expect((json['books'] as List).length, 1);
      expect(json['highlights'], isList);
      expect((json['highlights'] as List).length, 1);
      expect(json['bookmarks'], isList);
      expect((json['bookmarks'] as List).length, 1);
      expect(json['collections'], isList);
      expect((json['collections'] as List).length, 1);
      expect((json['ideaThreads'] as List).length, 1);
      expect((json['threadHighlightLinks'] as List).length, 1);
    });

    test('fromJson round-trips correctly', () {
      final json = backup.toJson();
      final restored = BackupData.fromJson(json);
      expect(restored.version, '1.0.0');
      expect(restored.books.length, 1);
      expect(restored.books.first.id, 'book-1');
      expect(restored.books.first.title, 'Test Book');
      expect(restored.highlights.length, 1);
      expect(restored.highlights.first.selectedText, 'Highlighted text');
      expect(restored.bookmarks.length, 1);
      expect(restored.bookmarks.first.pageNumber, 10);
      expect(restored.collections.length, 1);
      expect(restored.collections.first.name, 'Favourites');
      expect(restored.ideaThreads.single.title, 'Research question');
      expect(restored.threadHighlightLinks.single.highlightId, 'h-1');
    });

    test('fromJson handles empty JSON gracefully', () {
      final restored = BackupData.fromJson(<String, dynamic>{});
      expect(restored.version, '1.0.0');
      expect(restored.books, isEmpty);
      expect(restored.highlights, isEmpty);
      expect(restored.bookmarks, isEmpty);
      expect(restored.collections, isEmpty);
      expect(restored.ideaThreads, isEmpty);
      expect(restored.threadHighlightLinks, isEmpty);
    });

    test('fromJson handles missing fields gracefully', () {
      final json = <String, dynamic>{
        'version': '1.0.0',
        'exportedAt': '2025-03-01T00:00:00.000',
      };
      final restored = BackupData.fromJson(json);
      expect(restored.books, isEmpty);
      expect(restored.highlights, isEmpty);
    });

    test('fromJson handles malformed book data gracefully', () {
      final json = <String, dynamic>{
        'version': '1.0.0',
        'exportedAt': '2025-03-01T00:00:00.000',
        'books': [
          {'id': 'partial-book', 'filePath': '/test.epub'},
        ],
        'highlights': [],
        'bookmarks': [],
        'collections': [],
      };
      final restored = BackupData.fromJson(json);
      expect(restored.books.length, 1);
      expect(restored.books.first.title, 'Untitled');
      expect(restored.books.first.author, 'Unknown Author');
    });
  });
}
