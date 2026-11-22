import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/search_result.dart';
import 'package:textara/core/constants/enums.dart';

/// Contract for library persistence and search.
///
/// Presentation code should depend on this interface rather than [BookDao]
/// when workflows need fakes in tests or cross-cutting behaviour.
abstract class LibraryRepository {
  Future<List<Book>> getAllBooks();

  Future<Book?> getBookById(String id);

  Future<void> updateBook(Book book);

  Future<void> deleteBook(String bookId);

  Future<void> toggleFavourite(String bookId);

  Future<void> updateLastOpened(String bookId);

  Future<void> updateReadingProgress(
    String bookId,
    double progress,
    int page,
    String? chapterId,
  );

  Future<void> updateReadingStatus(String bookId, ReadingStatus status);

  /// Ranked metadata + full-text search across the local library index.
  Future<List<SearchResult>> search(String query);
}
