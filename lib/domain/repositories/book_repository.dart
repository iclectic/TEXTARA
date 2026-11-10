import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/search_result.dart';

/// Library persistence boundary. Presentation should prefer this over DAOs
/// when coordinating book lifecycle (list, mutate, resume fields).
abstract class BookRepository {
  Future<List<Book>> getAllBooks();

  Future<Book?> getBookById(String id);

  Future<void> insertBook(Book book);

  Future<void> updateBook(Book book);

  Future<void> deleteBook(String id);

  Future<void> toggleFavourite(String id);

  Future<void> updateLastOpened(String id);

  Future<void> updateReadingProgress({
    required String bookId,
    required double progress,
    required int page,
    String? chapterId,
  });

  Future<List<SearchResult>> searchLibrary(String query);
}
