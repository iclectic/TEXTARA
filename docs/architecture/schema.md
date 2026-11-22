# Textara SQLite schema

Database file: `textara.db` in the application documents directory  
Current version: **2** (`DatabaseHelper` in `lib/data/database/database_helper.dart`)

## Tables

### `books`
Primary library entity. Tags are still stored as a comma-joined string; collection membership also has a join table (`book_collections`). Prefer the join table for new collection work.

| Column | Type | Notes |
|---|---|---|
| id | TEXT PK | UUID |
| title, author | TEXT | |
| description | TEXT | nullable |
| file_path | TEXT | under `documents/books/` |
| format | TEXT | `epub` \| `pdf` |
| cover_path | TEXT | under `documents/covers/` |
| reading_status | TEXT | `notStarted` \| `reading` \| `finished` |
| reading_progress | REAL | 0–1 |
| current_page | INTEGER | EPUB: chapter index; PDF: page |
| current_chapter_id | TEXT | |
| total_pages | INTEGER | |
| date_added, last_opened_at | TEXT ISO8601 | |
| is_favourite | INTEGER 0/1 | |
| tags | TEXT | comma-joined (legacy) |
| collection_ids | TEXT | comma-joined (legacy; prefer join table) |
| file_size_bytes | INTEGER | |
| language, publisher, isbn | TEXT | nullable |

### `highlights` / `bookmarks`
FK `book_id` → `books(id)` ON DELETE CASCADE.

### `collections` / `book_collections`
Many-to-many book ↔ collection.

### `full_text_search`
Plain table of chapter text for EPUB (LIKE search today; FTS5 upgrade tracked in PLAN.md).

| Column | Type |
|---|---|
| book_id, chapter_id | TEXT |
| content | TEXT |
| chapter_order | INTEGER |

### `idea_threads` / `thread_highlights`
Added in schema version 2. `thread_highlights` links highlights into threads with optional `reflection` and `sort_order`.

## Migrations

- **v1 → v2:** create Idea Thread tables (`_createIdeaThreadTables`).
- Fresh installs run `_onCreate` at the latest version (must stay schema-equivalent to an upgraded DB).

## Backup JSON

`BackupData` (`lib/domain/entities/backup_data.dart`) exports books, highlights, bookmarks, collections, idea threads, and thread highlight links. Restore must be transactional (all-or-nothing).
