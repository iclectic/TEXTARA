import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'textara.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

    await db.execute('''
      CREATE TABLE highlights (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        chapter_id TEXT,
        selected_text TEXT NOT NULL,
        colour TEXT NOT NULL DEFAULT 'yellow',
        note TEXT,
        start_offset INTEGER NOT NULL,
        end_offset INTEGER NOT NULL,
        cfi_range TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE bookmarks (
        id TEXT PRIMARY KEY,
        book_id TEXT NOT NULL,
        chapter_id TEXT,
        page_number INTEGER NOT NULL,
        cfi_location TEXT,
        title TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE collections (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE book_collections (
        book_id TEXT NOT NULL,
        collection_id TEXT NOT NULL,
        PRIMARY KEY (book_id, collection_id),
        FOREIGN KEY (book_id) REFERENCES books(id) ON DELETE CASCADE,
        FOREIGN KEY (collection_id) REFERENCES collections(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE full_text_search (
        book_id TEXT NOT NULL,
        chapter_id TEXT NOT NULL,
        content TEXT NOT NULL,
        chapter_order INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute(
        'CREATE INDEX idx_books_title ON books(title)');
    await db.execute(
        'CREATE INDEX idx_books_author ON books(author)');
    await db.execute(
        'CREATE INDEX idx_books_status ON books(reading_status)');
    await db.execute(
        'CREATE INDEX idx_books_favourite ON books(is_favourite)');
    await db.execute(
        'CREATE INDEX idx_highlights_book ON highlights(book_id)');
    await db.execute(
        'CREATE INDEX idx_bookmarks_book ON bookmarks(book_id)');
    await db.execute(
        'CREATE INDEX idx_fts_book ON full_text_search(book_id)');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
