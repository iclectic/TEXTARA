import 'dart:async';

import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/data/database/book_dao.dart';
import 'package:textara/domain/repositories/book_repository.dart';

typedef ReadingProgressWrite =
    Future<void> Function(
      String bookId,
      double progress,
      int page,
      String? chapterId,
    );

/// Debounces SQLite writing of reading progress during rapid page changes.
///
/// Writes only to the `books` auto-resume fields. Manual bookmarks live in the
/// separate `bookmarks` table and are never modified here.
class ReadingProgressPersister {
  ReadingProgressPersister(
    BookDao bookDao, {
    this.debounce = AppConstants.readingProgressDebounce,
  }) : _write = bookDao.updateReadingProgress;

  factory ReadingProgressPersister.fromRepository(
    BookRepository books, {
    Duration debounce = AppConstants.readingProgressDebounce,
  }) {
    return ReadingProgressPersister._((bookId, progress, page, chapterId) {
      return books.updateReadingProgress(
        bookId: bookId,
        progress: progress,
        page: page,
        chapterId: chapterId,
      );
    }, debounce: debounce);
  }

  ReadingProgressPersister._(
    this._write, {
    this.debounce = AppConstants.readingProgressDebounce,
  });

  final ReadingProgressWrite _write;
  final Duration debounce;

  Timer? _timer;
  _PendingProgress? _pending;

  void schedule({
    required String bookId,
    required double progress,
    required int page,
    String? chapterId,
  }) {
    _pending = _PendingProgress(
      bookId: bookId,
      progress: progress,
      page: page,
      chapterId: chapterId,
    );
    _timer?.cancel();
    _timer = Timer(debounce, () {
      unawaited(flush());
    });
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    final pending = _pending;
    if (pending == null) return;
    _pending = null;
    await _write(
      pending.bookId,
      pending.progress,
      pending.page,
      pending.chapterId,
    );
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

class _PendingProgress {
  const _PendingProgress({
    required this.bookId,
    required this.progress,
    required this.page,
    required this.chapterId,
  });

  final String bookId;
  final double progress;
  final int page;
  final String? chapterId;
}
