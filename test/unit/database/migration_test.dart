import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:textara/data/database/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<Set<String>> tableNames(Database db) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'",
    );
    return rows.map((r) => r['name'] as String).toSet();
  }

  test('fresh onCreate at latest version creates expected tables', () async {
    final path =
        '${Directory.systemTemp.path}/textara_fresh_${DateTime.now().microsecondsSinceEpoch}.db';
    addTearDown(() {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    });

    final helper = DatabaseHelper();
    final db = await helper.openAtPath(path);
    final tables = await tableNames(db);
    expect(
      tables,
      containsAll({
        'books',
        'highlights',
        'bookmarks',
        'collections',
        'book_collections',
        'full_text_search',
        'idea_threads',
        'thread_highlights',
        'reading_sessions',
      }),
    );
    expect(await db.getVersion(), DatabaseHelper.schemaVersion);
    await db.close();
  });

  test('upgrade from v1 to latest adds idea threads and sessions', () async {
    final path =
        '${Directory.systemTemp.path}/textara_upgrade_${DateTime.now().microsecondsSinceEpoch}.db';
    addTearDown(() {
      final f = File(path);
      if (f.existsSync()) f.deleteSync();
    });

    final helper = DatabaseHelper();

    final v1 = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE books (
              id TEXT PRIMARY KEY,
              title TEXT NOT NULL,
              author TEXT NOT NULL DEFAULT 'Unknown Author',
              description TEXT,
              file_path TEXT NOT NULL,
              format TEXT NOT NULL,
              cover_path TEXT,
              reading_status TEXT NOT NULL DEFAULT 'notStarted',
              reading_progress REAL NOT NULL DEFAULT 0.0,
              current_page INTEGER NOT NULL DEFAULT 0,
              current_chapter_id TEXT,
              total_pages INTEGER NOT NULL DEFAULT 0,
              date_added TEXT NOT NULL,
              last_opened_at TEXT,
              is_favourite INTEGER NOT NULL DEFAULT 0,
              tags TEXT NOT NULL DEFAULT '',
              collection_ids TEXT NOT NULL DEFAULT '',
              file_size_bytes INTEGER NOT NULL DEFAULT 0,
              language TEXT,
              publisher TEXT,
              isbn TEXT
            )
          ''');
        },
      ),
    );
    await v1.close();

    final upgraded = await helper.openAtPath(path);
    final tables = await tableNames(upgraded);
    expect(
      tables,
      containsAll({'idea_threads', 'thread_highlights', 'reading_sessions'}),
    );
    expect(await upgraded.getVersion(), DatabaseHelper.schemaVersion);
    await upgraded.close();
  });
}
