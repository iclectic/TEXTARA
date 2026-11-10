import 'package:textara/data/services/brightness_service.dart';
import 'package:textara/data/services/reading_progress_persister.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/reader_location.dart';
import 'package:textara/domain/repositories/book_repository.dart';

/// Coordinates reader session side-effects: progress debounce, brightness, and
/// stable [ReaderLocation] snapshots. Keeps [ReaderScreen] thinner.
class ReaderSessionController {
  ReaderSessionController({
    required Book book,
    required BookRepository books,
    required BrightnessService brightness,
    ReadingProgressPersister? progressPersister,
  }) : _book = book,
       _books = books,
       _brightness = brightness,
       _progress =
           progressPersister ?? ReadingProgressPersister.fromRepository(books);

  final Book _book;
  final BookRepository _books;
  final BrightnessService _brightness;
  final ReadingProgressPersister _progress;

  Book get book => _book;

  ReaderLocation currentLocation({
    required int pageIndex,
    required double progress,
    String? chapterTitle,
  }) {
    return ReaderLocation(
      format: _book.format,
      pageIndex: pageIndex,
      chapterId: (chapterTitle == null || chapterTitle.isEmpty)
          ? null
          : chapterTitle,
      progress: progress,
    ).preservedAcrossTypographyChange();
  }

  void scheduleProgress({
    required int page,
    required int totalPages,
    required String chapterTitle,
  }) {
    final progress = totalPages > 0 ? page / totalPages : 0.0;
    _progress.schedule(
      bookId: _book.id,
      progress: progress,
      page: page,
      chapterId: chapterTitle.isEmpty ? null : chapterTitle,
    );
  }

  Future<void> applyBrightness(double value) => _brightness.apply(value);

  Future<void> resetBrightness() => _brightness.reset();

  Future<void> markOpened() => _books.updateLastOpened(_book.id);

  Future<void> flushProgress() => _progress.flush();

  Future<void> dispose() async {
    await flushProgress();
    _progress.dispose();
    await resetBrightness();
  }
}
