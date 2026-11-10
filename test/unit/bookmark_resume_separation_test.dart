import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:textara/data/database/book_dao.dart';
import 'package:textara/data/services/reading_progress_persister.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/domain/entities/reader_location.dart';
import 'package:textara/core/constants/enums.dart';

class _MockBookDao extends Mock implements BookDao {}

void main() {
  group('bookmark vs auto-resume separation', () {
    test('progress persister only updates book resume fields', () async {
      final bookDao = _MockBookDao();
      when(
        () => bookDao.updateReadingProgress(any(), any(), any(), any()),
      ).thenAnswer((_) async {});

      final persister = ReadingProgressPersister(
        bookDao,
        debounce: const Duration(milliseconds: 1),
      );
      persister.schedule(
        bookId: 'book-1',
        progress: 0.4,
        page: 4,
        chapterId: 'Chapter 5',
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await persister.flush();

      verify(
        () => bookDao.updateReadingProgress('book-1', 0.4, 4, 'Chapter 5'),
      ).called(1);
      verifyNoMoreInteractions(bookDao);
      persister.dispose();
    });

    test('manual bookmark locations stay independent of later resume tokens',
        () {
      const bookmarked = ReaderLocation(
        format: BookFormat.epub,
        pageIndex: 2,
        chapterId: 'Saved chapter',
        progress: 0.2,
      );
      final bookmark = Bookmark(
        id: 'bm-1',
        bookId: 'book-1',
        pageNumber: bookmarked.pageIndex,
        chapterId: bookmarked.chapterId,
        cfiLocation: bookmarked.toStableToken(),
        title: 'Favourite',
        createdAt: DateTime(2026, 1, 1),
      );

      // Auto-resume later moves elsewhere.
      const resume = ReaderLocation(
        format: BookFormat.epub,
        pageIndex: 9,
        chapterId: 'Later chapter',
        progress: 0.9,
      );

      final restored = ReaderLocation.fromBookmark(
        bookmark,
        format: BookFormat.epub,
      );
      expect(restored.pageIndex, 2);
      expect(restored.chapterId, 'Saved chapter');
      expect(restored, isNot(equals(resume)));
    });
  });
}
