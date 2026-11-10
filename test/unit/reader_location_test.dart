import 'package:flutter_test/flutter_test.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/reader_location.dart';

void main() {
  group('ReaderLocation', () {
    test('stable token round-trips', () {
      const original = ReaderLocation(
        format: BookFormat.epub,
        pageIndex: 4,
        chapterId: 'Chapter 5',
        progress: 0.4,
      );
      final restored = ReaderLocation.fromStableToken(
        original.toStableToken(),
        fallbackFormat: BookFormat.pdf,
      );
      expect(restored.format, BookFormat.epub);
      expect(restored.pageIndex, 4);
      expect(restored.chapterId, 'Chapter 5');
      expect(restored.progress, 0.4);
    });

    test('fromBook maps resume fields', () {
      final book = Book(
        id: '1',
        title: 'Demo',
        author: 'Author',
        filePath: '/tmp/a.epub',
        format: BookFormat.epub,
        dateAdded: DateTime(2026, 1, 1),
        currentPage: 3,
        currentChapterId: 'Storm',
        readingProgress: 0.25,
      );
      final location = ReaderLocation.fromBook(book);
      expect(location.pageIndex, 3);
      expect(location.chapterId, 'Storm');
      expect(location.displayLabel, 'Storm');
    });

    test('fromBookmark prefers stable token over loose page fields', () {
      const location = ReaderLocation(
        format: BookFormat.pdf,
        pageIndex: 12,
        chapterId: 'Page 12',
        progress: 0.5,
      );
      final bookmark = Bookmark(
        id: 'b1',
        bookId: '1',
        pageNumber: 1,
        chapterId: 'stale',
        cfiLocation: location.toStableToken(),
        title: 'Midpoint',
        createdAt: DateTime(2026, 1, 1),
      );
      final restored = ReaderLocation.fromBookmark(
        bookmark,
        format: BookFormat.pdf,
      );
      expect(restored.pageIndex, 12);
      expect(restored.chapterId, 'Page 12');
      expect(restored.progress, 0.5);
    });

    test('legacy bookmarks without token still resolve by pageNumber', () {
      final bookmark = Bookmark(
        id: 'b2',
        bookId: '1',
        pageNumber: 7,
        chapterId: 'Old chapter',
        createdAt: DateTime(2026, 1, 1),
      );
      final restored = ReaderLocation.fromBookmark(
        bookmark,
        format: BookFormat.epub,
      );
      expect(restored.pageIndex, 7);
      expect(restored.chapterId, 'Old chapter');
    });

    test('typography preservation keeps chapter index stable', () {
      const location = ReaderLocation(
        format: BookFormat.epub,
        pageIndex: 2,
        chapterId: 'Two',
        progress: 0.2,
      );
      expect(location.preservedAcrossTypographyChange(), location);
    });

    test('clamps progress from JSON', () {
      final restored = ReaderLocation.fromJson({
        'format': 'epub',
        'pageIndex': 1,
        'progress': 1.5,
      });
      expect(restored.progress, 1.0);
    });
  });
}
