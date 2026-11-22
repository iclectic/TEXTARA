import 'package:textara/core/constants/enums.dart';
import 'package:textara/data/database/book_dao.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/search_result.dart';
import 'package:textara/domain/repositories/library_repository.dart';

class SqliteLibraryRepository implements LibraryRepository {
  final BookDao _bookDao;

  SqliteLibraryRepository(this._bookDao);

  @override
  Future<List<Book>> getAllBooks() => _bookDao.getAllBooks();

  @override
  Future<Book?> getBookById(String id) => _bookDao.getBookById(id);

  @override
  Future<void> updateBook(Book book) => _bookDao.updateBook(book);

  @override
  Future<void> deleteBook(String bookId) => _bookDao.deleteBook(bookId);

  @override
  Future<void> toggleFavourite(String bookId) =>
      _bookDao.toggleFavourite(bookId);

  @override
  Future<void> updateLastOpened(String bookId) =>
      _bookDao.updateLastOpened(bookId);

  @override
  Future<void> updateReadingProgress(
    String bookId,
    double progress,
    int page,
    String? chapterId,
  ) => _bookDao.updateReadingProgress(bookId, progress, page, chapterId);

  @override
  Future<void> updateReadingStatus(String bookId, ReadingStatus status) =>
      _bookDao.updateReadingStatus(bookId, status);

  @override
  Future<List<SearchResult>> search(String query) =>
      _bookDao.searchLibrary(query);
}
