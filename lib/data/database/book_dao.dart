import 'package:sqflite/sqflite.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/search_result.dart';
import 'package:textara/data/database/database_helper.dart';

class BookDao {
  final DatabaseHelper _dbHelper;

  BookDao(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Map<String, dynamic> _bookToMap(Book book) => {
    'id': book.id,
    'title': book.title,
    'author': book.author,
    'description': book.description,
    'file_path': book.filePath,
    'format': book.format.name,
    'cover_path': book.coverPath,
    'reading_status': book.readingStatus.name,
    'reading_progress': book.readingProgress,
    'current_page': book.currentPage,
    'current_chapter_id': book.currentChapterId,
    'total_pages': book.totalPages,
    'date_added': book.dateAdded.toIso8601String(),
    'last_opened_at': book.lastOpenedAt?.toIso8601String(),
    'is_favourite': book.isFavourite ? 1 : 0,
    'tags': book.tags.join(','),
    'collection_ids': book.collectionIds.join(','),
    'file_size_bytes': book.fileSizeBytes,
    'language': book.language,
    'publisher': book.publisher,
    'isbn': book.isbn,
  };

  Book _mapToBook(Map<String, dynamic> map) => Book(
    id: map['id'] as String,
    title: map['title'] as String,
    author: map['author'] as String? ?? 'Unknown Author',
    description: map['description'] as String?,
    filePath: map['file_path'] as String,
    format: BookFormat.values.firstWhere(
      (e) => e.name == map['format'],
      orElse: () => BookFormat.epub,
    ),
    coverPath: map['cover_path'] as String?,
    readingStatus: ReadingStatus.values.firstWhere(
      (e) => e.name == map['reading_status'],
      orElse: () => ReadingStatus.notStarted,
    ),
    readingProgress: (map['reading_progress'] as num?)?.toDouble() ?? 0.0,
    currentPage: map['current_page'] as int? ?? 0,
    currentChapterId: map['current_chapter_id'] as String?,
    totalPages: map['total_pages'] as int? ?? 0,
    dateAdded:
        DateTime.tryParse(map['date_added'] as String? ?? '') ?? DateTime.now(),
    lastOpenedAt: map['last_opened_at'] != null
        ? DateTime.tryParse(map['last_opened_at'] as String)
        : null,
    isFavourite: (map['is_favourite'] as int?) == 1,
    tags: (map['tags'] as String?)?.isNotEmpty == true
        ? (map['tags'] as String).split(',')
        : [],
    collectionIds: (map['collection_ids'] as String?)?.isNotEmpty == true
        ? (map['collection_ids'] as String).split(',')
        : [],
    fileSizeBytes: map['file_size_bytes'] as int? ?? 0,
    language: map['language'] as String?,
    publisher: map['publisher'] as String?,
    isbn: map['isbn'] as String?,
  );

  Future<List<Book>> getAllBooks() async {
    final db = await _db;
    final maps = await db.query('books', orderBy: 'date_added DESC');
    return maps.map(_mapToBook).toList();
  }

  Future<Book?> getBookById(String id) async {
    final db = await _db;
    final maps = await db.query('books', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _mapToBook(maps.first);
  }

  Future<void> insertBook(Book book) async {
    final db = await _db;
    await db.insert(
      'books',
      _bookToMap(book),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateBook(Book book) async {
    final db = await _db;
    await db.update(
      'books',
      _bookToMap(book),
      where: 'id = ?',
      whereArgs: [book.id],
    );
  }

  Future<void> deleteBook(String id) async {
    final db = await _db;
    await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Book>> searchBooks(String query) async {
    final db = await _db;
    final lowerQuery = '%${query.toLowerCase()}%';
    final maps = await db.query(
      'books',
      where:
          'LOWER(title) LIKE ? OR LOWER(author) LIKE ? OR LOWER(tags) LIKE ?',
      whereArgs: [lowerQuery, lowerQuery, lowerQuery],
    );
    return maps.map(_mapToBook).toList();
  }

  Future<List<Book>> getBooksByStatus(ReadingStatus status) async {
    final db = await _db;
    final maps = await db.query(
      'books',
      where: 'reading_status = ?',
      whereArgs: [status.name],
    );
    return maps.map(_mapToBook).toList();
  }

  Future<List<Book>> getFavouriteBooks() async {
    final db = await _db;
    final maps = await db.query('books', where: 'is_favourite = 1');
    return maps.map(_mapToBook).toList();
  }

  Future<List<Book>> getSortedBooks(
    LibrarySortField field,
    SortOrder order,
  ) async {
    final db = await _db;
    String orderByColumn;
    switch (field) {
      case LibrarySortField.recentlyOpened:
        orderByColumn = 'last_opened_at';
      case LibrarySortField.title:
        orderByColumn = 'title';
      case LibrarySortField.author:
        orderByColumn = 'author';
      case LibrarySortField.progress:
        orderByColumn = 'reading_progress';
      case LibrarySortField.lastAdded:
        orderByColumn = 'date_added';
    }
    final orderDir = order == SortOrder.ascending ? 'ASC' : 'DESC';
    final maps = await db.query('books', orderBy: '$orderByColumn $orderDir');
    return maps.map(_mapToBook).toList();
  }

  Future<void> updateReadingProgress(
    String bookId,
    double progress,
    int page,
    String? chapterId,
  ) async {
    final db = await _db;
    final status = progress >= 1.0
        ? ReadingStatus.finished.name
        : progress > 0
        ? ReadingStatus.reading.name
        : ReadingStatus.notStarted.name;
    await db.update(
      'books',
      {
        'reading_progress': progress,
        'current_page': page,
        'current_chapter_id': chapterId,
        'reading_status': status,
        'last_opened_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<void> toggleFavourite(String bookId) async {
    final db = await _db;
    final book = await getBookById(bookId);
    if (book == null) return;
    await db.update(
      'books',
      {'is_favourite': book.isFavourite ? 0 : 1},
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<List<String>> getAllTags() async {
    final db = await _db;
    final maps = await db.query('books', columns: ['tags']);
    final allTags = <String>{};
    for (final map in maps) {
      final tags = (map['tags'] as String?) ?? '';
      if (tags.isNotEmpty) {
        allTags.addAll(tags.split(','));
      }
    }
    return allTags.toList()..sort();
  }

  Future<void> updateLastOpened(String bookId) async {
    final db = await _db;
    await db.update(
      'books',
      {'last_opened_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<List<Book>> fullTextSearch(String query) async {
    final db = await _db;
    final lowerQuery = '%${query.toLowerCase()}%';
    final ftsResults = await db.query(
      'full_text_search',
      columns: ['DISTINCT book_id'],
      where: 'LOWER(content) LIKE ?',
      whereArgs: [lowerQuery],
    );
    if (ftsResults.isEmpty) return [];
    final bookIds = ftsResults.map((r) => r['book_id'] as String).toList();
    final placeholders = List.filled(bookIds.length, '?').join(',');
    final maps = await db.query(
      'books',
      where: 'id IN ($placeholders)',
      whereArgs: bookIds,
    );
    return maps.map(_mapToBook).toList();
  }

  Future<List<SearchResult>> searchLibrary(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return [];

    final db = await _db;
    final lowerQuery = trimmedQuery.toLowerCase();
    final likeQuery = '%$lowerQuery%';
    final resultsByBookId = <String, SearchResult>{};

    final metadataRows = await db.query(
      'books',
      where:
          'LOWER(title) LIKE ? OR LOWER(author) LIKE ? OR LOWER(tags) LIKE ?',
      whereArgs: [likeQuery, likeQuery, likeQuery],
    );
    for (final row in metadataRows) {
      final book = _mapToBook(row);
      resultsByBookId[book.id] = SearchResult(
        book: book,
        matchType: SearchMatchType.metadata,
        rank: _metadataRank(book, lowerQuery),
      );
    }

    final contentRows = await db.rawQuery(
      '''
      SELECT f.book_id, f.chapter_id, f.content, f.chapter_order, b.*
      FROM full_text_search f
      INNER JOIN books b ON b.id = f.book_id
      WHERE LOWER(f.content) LIKE ?
      ORDER BY f.chapter_order ASC
      ''',
      [likeQuery],
    );

    for (final row in contentRows) {
      final book = _mapToBook(row);
      final existing = resultsByBookId[book.id];
      if (existing?.isFullTextMatch == true) continue;

      final content = row['content'] as String? ?? '';
      final fullTextResult = SearchResult(
        book: book,
        matchType: SearchMatchType.fullText,
        chapterId: row['chapter_id'] as String?,
        excerpt: _buildExcerpt(content, lowerQuery),
        rank: existing == null ? 40 : existing.rank + 15,
      );
      resultsByBookId[book.id] = fullTextResult;
    }

    final results = resultsByBookId.values.toList()
      ..sort((a, b) => b.rank.compareTo(a.rank));
    return results;
  }

  double _metadataRank(Book book, String lowerQuery) {
    final title = book.title.toLowerCase();
    final author = book.author.toLowerCase();
    final tags = book.tags.map((tag) => tag.toLowerCase()).toList();
    if (title == lowerQuery) return 100;
    if (title.startsWith(lowerQuery)) return 85;
    if (title.contains(lowerQuery)) return 75;
    if (author.contains(lowerQuery)) return 60;
    if (tags.any((tag) => tag == lowerQuery)) return 55;
    if (tags.any((tag) => tag.contains(lowerQuery))) return 45;
    return 30;
  }

  String _buildExcerpt(String content, String lowerQuery) {
    const excerptRadius = 80;
    final lowerContent = content.toLowerCase();
    final matchIndex = lowerContent.indexOf(lowerQuery);
    if (matchIndex < 0) {
      return content.length <= excerptRadius * 2
          ? content
          : '${content.substring(0, excerptRadius * 2).trim()}...';
    }
    final start = (matchIndex - excerptRadius).clamp(0, content.length);
    final end = (matchIndex + lowerQuery.length + excerptRadius).clamp(
      0,
      content.length,
    );
    final prefix = start == 0 ? '' : '...';
    final suffix = end == content.length ? '' : '...';
    return '$prefix${content.substring(start, end).trim()}$suffix';
  }
}
