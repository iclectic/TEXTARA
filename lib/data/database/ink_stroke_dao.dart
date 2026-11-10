import 'package:sqflite/sqflite.dart';
import 'package:textara/data/database/database_helper.dart';
import 'package:textara/domain/entities/ink_stroke.dart';

class InkStrokeDao {
  InkStrokeDao(this._dbHelper);

  final DatabaseHelper _dbHelper;

  Future<Database> get _db => _dbHelper.database;

  Map<String, dynamic> _toMap(InkStroke stroke) => {
    'id': stroke.id,
    'book_id': stroke.bookId,
    'location_key': stroke.locationKey,
    'tool': stroke.tool.name,
    'color_value': stroke.colorValue,
    'base_width': stroke.baseWidth,
    'points_json': stroke.encodePoints(),
    'created_at': stroke.createdAt.toIso8601String(),
  };

  InkStroke _fromMap(Map<String, dynamic> map) => InkStroke(
    id: map['id'] as String,
    bookId: map['book_id'] as String,
    locationKey: map['location_key'] as String? ?? '',
    tool: InkTool.values.firstWhere(
      (e) => e.name == map['tool'],
      orElse: () => InkTool.pen,
    ),
    colorValue: map['color_value'] as int? ?? 0xFF1A1A2E,
    baseWidth: (map['base_width'] as num?)?.toDouble() ?? 2.5,
    points: InkStroke.decodePoints(map['points_json'] as String? ?? '[]'),
    createdAt:
        DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
  );

  Future<List<InkStroke>> getStrokesForLocation({
    required String bookId,
    required String locationKey,
  }) async {
    final db = await _db;
    final maps = await db.query(
      'ink_strokes',
      where: 'book_id = ? AND location_key = ?',
      whereArgs: [bookId, locationKey],
      orderBy: 'created_at ASC',
    );
    return maps.map(_fromMap).toList();
  }

  Future<void> insertStroke(InkStroke stroke) async {
    final db = await _db;
    await db.insert(
      'ink_strokes',
      _toMap(stroke),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteStroke(String id) async {
    final db = await _db;
    await db.delete('ink_strokes', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteStrokes(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return;
    final db = await _db;
    final placeholders = List.filled(list.length, '?').join(',');
    await db.delete(
      'ink_strokes',
      where: 'id IN ($placeholders)',
      whereArgs: list,
    );
  }

  Future<void> clearLocation({
    required String bookId,
    required String locationKey,
  }) async {
    final db = await _db;
    await db.delete(
      'ink_strokes',
      where: 'book_id = ? AND location_key = ?',
      whereArgs: [bookId, locationKey],
    );
  }
}
