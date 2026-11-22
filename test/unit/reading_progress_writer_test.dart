import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/repositories/library_repository.dart';
import 'package:textara/presentation/providers/reader_providers.dart';

class _FakeLibraryRepository extends Mock implements LibraryRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(ReadingStatus.notStarted);
    registerFallbackValue(
      Book(
        id: 'fallback',
        title: 't',
        author: 'a',
        filePath: '/t.epub',
        format: BookFormat.epub,
        dateAdded: DateTime(2024),
      ),
    );
  });

  test('coalesces rapid schedule calls into a single flush', () async {
    final repository = _FakeLibraryRepository();
    when(
      () => repository.updateReadingProgress(any(), any(), any(), any()),
    ).thenAnswer((_) async {});

    final writer = ReadingProgressWriter(
      repository,
      delay: const Duration(milliseconds: 50),
    );

    writer.schedule(bookId: 'b1', progress: 0.1, page: 1, chapterId: 'c1');
    writer.schedule(bookId: 'b1', progress: 0.2, page: 2, chapterId: 'c2');
    writer.schedule(bookId: 'b1', progress: 0.3, page: 3, chapterId: 'c3');

    await Future<void>.delayed(const Duration(milliseconds: 80));

    verify(
      () => repository.updateReadingProgress('b1', 0.3, 3, 'c3'),
    ).called(1);
    verifyNever(() => repository.updateReadingProgress('b1', 0.1, 1, 'c1'));

    writer.dispose();
  });

  test('flush writes immediately even if timer pending', () async {
    final repository = _FakeLibraryRepository();
    when(
      () => repository.updateReadingProgress(any(), any(), any(), any()),
    ).thenAnswer((_) async {});

    final writer = ReadingProgressWriter(
      repository,
      delay: const Duration(seconds: 5),
    );

    writer.schedule(bookId: 'b1', progress: 0.5, page: 5, chapterId: 'ch');
    await writer.flush();

    verify(
      () => repository.updateReadingProgress('b1', 0.5, 5, 'ch'),
    ).called(1);
    writer.dispose();
  });
}
