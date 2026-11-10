import 'package:textara/domain/entities/book.dart';

/// Picks the library "Continue reading" target: most recently opened
/// in-progress book. Finished and unopened books are ignored.
class ContinueReading {
  ContinueReading._();

  static Book? select(List<Book> books) {
    final inProgress = books
        .where(
          (book) =>
              book.lastOpenedAt != null &&
              book.readingProgress > 0 &&
              book.readingProgress < 1.0,
        )
        .toList()
      ..sort((a, b) => b.lastOpenedAt!.compareTo(a.lastOpenedAt!));
    if (inProgress.isEmpty) return null;
    return inProgress.first;
  }
}
