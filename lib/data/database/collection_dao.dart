import 'package:sqflite/sqflite.dart';
import 'package:leaf_reader/domain/entities/collection.dart';
import 'package:leaf_reader/data/database/database_helper.dart';

class CollectionDao {
  final DatabaseHelper _dbHelper;

  CollectionDao(this._dbHelper);

  Future<Database> get _db => _dbHelper.database;

  Map<String, dynamic> _collectionToMap(Collection c) => {
        'id': c.id,
        'name': c.name,
        'description': c.description,
        'created_at': c.createdAt.toIso8601String(),
        'updated_at': c.updatedAt.toIso8601String(),
      };

  Collection _mapToCollection(Map<String, dynamic> map, {int bookCount = 0}) =>
      Collection(
        id: map['id'] as String,
        name: map['name'] as String,
        description: map['description'] as String?,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
        bookCount: bookCount,
      );

  Future<List<Collection>> getAllCollections() async {
    final db = await _db;
    final maps = await db.query('collections', orderBy: 'name ASC');
    final collections = <Collection>[];
    for (final map in maps) {
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM book_collections WHERE collection_id = ?',
        [map['id']],
      );
      final count = countResult.first['cnt'] as int? ?? 0;
      collections.add(_mapToCollection(map, bookCount: count));
    }
    return collections;
  }

  Future<Collection?> getCollectionById(String id) async {
    final db = await _db;
    final maps =
        await db.query('collections', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return _mapToCollection(maps.first);
  }

  Future<void> insertCollection(Collection collection) async {
    final db = await _db;
    await db.insert('collections', _collectionToMap(collection),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateCollection(Collection collection) async {
    final db = await _db;
    await db.update('collections', _collectionToMap(collection),
        where: 'id = ?', whereArgs: [collection.id]);
  }

  Future<void> deleteCollection(String id) async {
    final db = await _db;
    await db.delete('book_collections',
        where: 'collection_id = ?', whereArgs: [id]);
    await db.delete('collections', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addBookToCollection(
      String bookId, String collectionId) async {
    final db = await _db;
    await db.insert(
      'book_collections',
      {'book_id': bookId, 'collection_id': collectionId},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeBookFromCollection(
      String bookId, String collectionId) async {
    final db = await _db;
    await db.delete(
      'book_collections',
      where: 'book_id = ? AND collection_id = ?',
      whereArgs: [bookId, collectionId],
    );
  }

  Future<List<String>> getBookIdsForCollection(String collectionId) async {
    final db = await _db;
    final maps = await db.query('book_collections',
        where: 'collection_id = ?', whereArgs: [collectionId]);
    return maps.map((m) => m['book_id'] as String).toList();
  }
}
