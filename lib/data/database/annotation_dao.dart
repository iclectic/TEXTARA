import 'package:sqflite/sqflite.dart';
import 'package:leaf_reader/core/constants/enums.dart';
import 'package:leaf_reader/domain/entities/annotation.dart';
import 'package:leaf_reader/data/database/database_helper.dart';

class AnnotationDao {
  final DatabaseHelper _dbHelper;

  AnnotationDao(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Map<String, dynamic> _highlightToMap(Highlight h) => {
        'id': h.id,
        'book_id': h.bookId,
        'chapter_id': h.chapterId,
        'selected_text': h.selectedText,
        'colour': h.colour.name,
        'note': h.note,
        'start_offset': h.startOffset,
        'end_offset': h.endOffset,
        'cfi_range': h.cfiRange,
        'created_at': h.createdAt.toIso8601String(),
        'updated_at': h.updatedAt.toIso8601String(),
      };

  Highlight _mapToHighlight(Map<String, dynamic> map) => Highlight(
        id: map['id'] as String,
        bookId: map['book_id'] as String,
        chapterId: map['chapter_id'] as String?,
        selectedText: map['selected_text'] as String,
        colour: HighlightColour.values.firstWhere(
          (e) => e.name == map['colour'],
          orElse: () => HighlightColour.yellow,
        ),
        note: map['note'] as String?,
        startOffset: map['start_offset'] as int,
        endOffset: map['end_offset'] as int,
        cfiRange: map['cfi_range'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> _bookmarkToMap(Bookmark b) => {
        'id': b.id,
        'book_id': b.bookId,
        'chapter_id': b.chapterId,
        'page_number': b.pageNumber,
        'cfi_location': b.cfiLocation,
        'title': b.title,
        'created_at': b.createdAt.toIso8601String(),
      };

  Bookmark _mapToBookmark(Map<String, dynamic> map) => Bookmark(
        id: map['id'] as String,
        bookId: map['book_id'] as String,
        chapterId: map['chapter_id'] as String?,
        pageNumber: map['page_number'] as int,
        cfiLocation: map['cfi_location'] as String?,
        title: map['title'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  Future<List<Highlight>> getHighlightsForBook(String bookId) async {
    final db = await _db;
    final maps = await db.query('highlights',
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'created_at DESC');
    return maps.map(_mapToHighlight).toList();
  }

  Future<List<Highlight>> getAllHighlights() async {
    final db = await _db;
    final maps = await db.query('highlights', orderBy: 'created_at DESC');
    return maps.map(_mapToHighlight).toList();
  }

  Future<void> insertHighlight(Highlight highlight) async {
    final db = await _db;
    await db.insert('highlights', _highlightToMap(highlight),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateHighlight(Highlight highlight) async {
    final db = await _db;
    await db.update('highlights', _highlightToMap(highlight),
        where: 'id = ?', whereArgs: [highlight.id]);
  }

  Future<void> deleteHighlight(String id) async {
    final db = await _db;
    await db.delete('highlights', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Bookmark>> getBookmarksForBook(String bookId) async {
    final db = await _db;
    final maps = await db.query('bookmarks',
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'page_number ASC');
    return maps.map(_mapToBookmark).toList();
  }

  Future<List<Bookmark>> getAllBookmarks() async {
    final db = await _db;
    final maps = await db.query('bookmarks', orderBy: 'created_at DESC');
    return maps.map(_mapToBookmark).toList();
  }

  Future<void> insertBookmark(Bookmark bookmark) async {
    final db = await _db;
    await db.insert('bookmarks', _bookmarkToMap(bookmark),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteBookmark(String id) async {
    final db = await _db;
    await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }
}
