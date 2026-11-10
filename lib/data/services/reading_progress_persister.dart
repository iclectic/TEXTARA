import 'dart:async';

import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/data/database/book_dao.dart';

/// Debounces SQLite writing of reading progress during rapid page changes.
class ReadingProgressPersister {
  ReadingProgressPersister(
    this._bookDao, {
    this.debounce = AppConstants.readingProgressDebounce,
  });

  final BookDao _bookDao;
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
    await _bookDao.updateReadingProgress(
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
