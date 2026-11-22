import 'package:sqflite/sqflite.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/data/database/database_helper.dart';
import 'package:textara/domain/entities/reading_stats.dart';
import 'package:uuid/uuid.dart';

class ReadingStatsDao {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  ReadingStatsDao(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Future<String> startSession(String bookId) async {
    final db = await _db;
    final id = _uuid.v4();
    await db.insert('reading_sessions', {
      'id': id,
      'book_id': bookId,
      'started_at': DateTime.now().toIso8601String(),
      'ended_at': null,
      'seconds_read': 0,
    });
    return id;
  }

  Future<void> endSession(String sessionId) async {
    final db = await _db;
    final rows = await db.query(
      'reading_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final started = DateTime.parse(rows.first['started_at'] as String);
    final ended = DateTime.now();
    final seconds = ended.difference(started).inSeconds.clamp(0, 86400);
    await db.update(
      'reading_sessions',
      {'ended_at': ended.toIso8601String(), 'seconds_read': seconds},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<ReadingStats> getStats() async {
    final db = await _db;
    final seconds =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COALESCE(SUM(seconds_read), 0) AS total FROM reading_sessions',
          ),
        ) ??
        0;
    final finished =
        Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM books WHERE reading_status = ?',
            [ReadingStatus.finished.name],
          ),
        ) ??
        0;
    final highlights =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM highlights'),
        ) ??
        0;
    final books =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM books'),
        ) ??
        0;
    return ReadingStats(
      totalSecondsRead: seconds,
      booksFinished: finished,
      highlightCount: highlights,
      booksInLibrary: books,
    );
  }
}
