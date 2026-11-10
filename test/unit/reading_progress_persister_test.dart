import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:textara/data/database/book_dao.dart';
import 'package:textara/data/services/reading_progress_persister.dart';

class _MockBookDao extends Mock implements BookDao {}

void main() {
  group('ReadingProgressPersister', () {
    late _MockBookDao bookDao;

    setUp(() {
      bookDao = _MockBookDao();
      when(
        () => bookDao.updateReadingProgress(
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenAnswer((_) async {});
    });

    test('coalesces rapid schedule calls into a single write after debounce',
        () async {
      final persister = ReadingProgressPersister(
        bookDao,
        debounce: const Duration(milliseconds: 40),
      );

      persister.schedule(
        bookId: 'book-1',
        progress: 0.1,
        page: 1,
        chapterId: 'c1',
      );
      persister.schedule(
        bookId: 'book-1',
        progress: 0.2,
        page: 2,
        chapterId: 'c2',
      );
      persister.schedule(
        bookId: 'book-1',
        progress: 0.3,
        page: 3,
        chapterId: 'c3',
      );

      await Future<void>.delayed(const Duration(milliseconds: 80));

      verify(
        () => bookDao.updateReadingProgress('book-1', 0.3, 3, 'c3'),
      ).called(1);
      verifyNoMoreInteractions(bookDao);

      persister.dispose();
    });

    test('flush writes pending progress immediately', () async {
      final persister = ReadingProgressPersister(
        bookDao,
        debounce: const Duration(seconds: 5),
      );

      persister.schedule(
        bookId: 'book-2',
        progress: 0.5,
        page: 10,
        chapterId: 'Chapter 10',
      );

      await persister.flush();

      verify(
        () => bookDao.updateReadingProgress('book-2', 0.5, 10, 'Chapter 10'),
      ).called(1);

      persister.dispose();
    });

    test('flush is a no-op when nothing is pending', () async {
      final persister = ReadingProgressPersister(bookDao);
      await persister.flush();
      verifyZeroInteractions(bookDao);
      persister.dispose();
    });
  });
}
