import 'package:sqflite/sqflite.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/data/database/database_helper.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/domain/entities/idea_thread.dart';

class IdeaThreadDao {
  final DatabaseHelper _dbHelper;

  IdeaThreadDao(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Map<String, dynamic> _threadToMap(IdeaThread thread) => {
    'id': thread.id,
    'title': thread.title,
    'description': thread.description,
    'tags': thread.tags.join(','),
    'synthesis_note': thread.synthesisNote,
    'created_at': thread.createdAt.toIso8601String(),
    'updated_at': thread.updatedAt.toIso8601String(),
  };

  IdeaThread _mapToThread(Map<String, dynamic> map, {int evidenceCount = 0}) {
    final tags = (map['tags'] as String?) ?? '';
    return IdeaThread(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      tags: tags.isEmpty ? const [] : tags.split(','),
      synthesisNote: map['synthesis_note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      evidenceCount: evidenceCount,
    );
  }

  Future<List<IdeaThread>> getAllThreads() async {
    final db = await _db;
    final maps = await db.rawQuery('''
      SELECT idea_threads.*, COUNT(thread_highlights.highlight_id) AS evidence_count
      FROM idea_threads
      LEFT JOIN thread_highlights ON thread_highlights.thread_id = idea_threads.id
      GROUP BY idea_threads.id
      ORDER BY idea_threads.updated_at DESC
    ''');
    return maps
        .map(
          (map) => _mapToThread(
            map,
            evidenceCount: (map['evidence_count'] as int?) ?? 0,
          ),
        )
        .toList();
  }

  Future<IdeaThread?> getThreadById(String id) async {
    final db = await _db;
    final maps = await db.query(
      'idea_threads',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    final count =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM thread_highlights WHERE thread_id = ?',
            [id],
          ),
        ) ??
        0;
    return _mapToThread(maps.first, evidenceCount: count);
  }

  Future<void> insertThread(IdeaThread thread) async {
    final db = await _db;
    await db.insert(
      'idea_threads',
      _threadToMap(thread),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateThread(IdeaThread thread) async {
    final db = await _db;
    await db.update(
      'idea_threads',
      _threadToMap(thread),
      where: 'id = ?',
      whereArgs: [thread.id],
    );
  }

  Future<void> deleteThread(String id) async {
    final db = await _db;
    await db.delete('idea_threads', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addHighlightToThread({
    required String threadId,
    required String highlightId,
    String? reflection,
  }) async {
    final db = await _db;
    final now = DateTime.now().toIso8601String();
    final maxOrder =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT MAX(sort_order) FROM thread_highlights WHERE thread_id = ?',
            [threadId],
          ),
        ) ??
        -1;
    await db.insert('thread_highlights', {
      'thread_id': threadId,
      'highlight_id': highlightId,
      'reflection': reflection,
      'sort_order': maxOrder + 1,
      'added_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.update(
      'idea_threads',
      {'updated_at': now},
      where: 'id = ?',
      whereArgs: [threadId],
    );
  }

  Future<void> removeHighlightFromThread({
    required String threadId,
    required String highlightId,
  }) async {
    final db = await _db;
    await db.delete(
      'thread_highlights',
      where: 'thread_id = ? AND highlight_id = ?',
      whereArgs: [threadId, highlightId],
    );
    await db.update(
      'idea_threads',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [threadId],
    );
  }

  Future<void> updateEvidenceReflection({
    required String threadId,
    required String highlightId,
    String? reflection,
  }) async {
    final db = await _db;
    await db.update(
      'thread_highlights',
      {'reflection': reflection},
      where: 'thread_id = ? AND highlight_id = ?',
      whereArgs: [threadId, highlightId],
    );
    await db.update(
      'idea_threads',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [threadId],
    );
  }

  Future<List<ThreadHighlightLink>> getAllHighlightLinks() async {
    final db = await _db;
    final maps = await db.query('thread_highlights', orderBy: 'sort_order ASC');
    return maps
        .map(
          (map) => ThreadHighlightLink(
            threadId: map['thread_id'] as String,
            highlightId: map['highlight_id'] as String,
            reflection: map['reflection'] as String?,
            sortOrder: map['sort_order'] as int,
            addedAt: DateTime.parse(map['added_at'] as String),
          ),
        )
        .toList();
  }

  Future<void> insertHighlightLink(ThreadHighlightLink link) async {
    final db = await _db;
    await db.insert('thread_highlights', {
      'thread_id': link.threadId,
      'highlight_id': link.highlightId,
      'reflection': link.reflection,
      'sort_order': link.sortOrder,
      'added_at': link.addedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ThreadEvidence>> getEvidenceForThread(String threadId) async {
    final db = await _db;
    final maps = await db.rawQuery(
      '''
      SELECT
        thread_highlights.thread_id,
        thread_highlights.reflection,
        thread_highlights.sort_order,
        thread_highlights.added_at,
        highlights.id AS highlight_id,
        highlights.book_id,
        highlights.chapter_id,
        highlights.selected_text,
        highlights.colour,
        highlights.note,
        highlights.start_offset,
        highlights.end_offset,
        highlights.cfi_range,
        highlights.created_at,
        highlights.updated_at,
        books.title AS book_title
      FROM thread_highlights
      JOIN highlights ON highlights.id = thread_highlights.highlight_id
      JOIN books ON books.id = highlights.book_id
      WHERE thread_highlights.thread_id = ?
      ORDER BY thread_highlights.sort_order ASC
    ''',
      [threadId],
    );
    return maps.map((map) {
      final highlight = Highlight(
        id: map['highlight_id'] as String,
        bookId: map['book_id'] as String,
        chapterId: map['chapter_id'] as String?,
        selectedText: map['selected_text'] as String,
        colour: HighlightColour.values.firstWhere(
          (colour) => colour.name == map['colour'],
          orElse: () => HighlightColour.yellow,
        ),
        note: map['note'] as String?,
        startOffset: map['start_offset'] as int,
        endOffset: map['end_offset'] as int,
        cfiRange: map['cfi_range'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
      return ThreadEvidence(
        threadId: map['thread_id'] as String,
        highlight: highlight,
        bookTitle: map['book_title'] as String,
        reflection: map['reflection'] as String?,
        sortOrder: map['sort_order'] as int,
        addedAt: DateTime.parse(map['added_at'] as String),
      );
    }).toList();
  }
}
