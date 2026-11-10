import 'package:textara/data/database/book_dao.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/search_result.dart';
import 'package:textara/domain/repositories/book_repository.dart';

class BookRepositoryImpl implements BookRepository {
  BookRepositoryImpl(this._dao);

  final BookDao _dao;

  @override
  Future<List<Book>> getAllBooks() => _dao.getAllBooks();

  @override
  Future<Book?> getBookById(String id) => _dao.getBookById(id);

  @override
  Future<void> insertBook(Book book) => _dao.insertBook(book);

  @override
  Future<void> updateBook(Book book) => _dao.updateBook(book);

  @override
  Future<void> deleteBook(String id) => _dao.deleteBook(id);

  @override
  Future<void> toggleFavourite(String id) => _dao.toggleFavourite(id);

  @override
  Future<void> updateLastOpened(String id) => _dao.updateLastOpened(id);

  @override
  Future<void> updateReadingProgress({
    required String bookId,
    required double progress,
    required int page,
    String? chapterId,
  }) {
    return _dao.updateReadingProgress(bookId, progress, page, chapterId);
  }

  @override
  Future<List<SearchResult>> searchLibrary(String query) =>
      _dao.searchLibrary(query);
}
