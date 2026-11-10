import 'package:textara/domain/entities/parsed_text_book.dart';

/// In-memory LRU cache of normalized chapter text for reopen / theme churn.
///
/// Keys are typically `bookId|filePath|mtimeMs`. Bounded to avoid unbounded
/// growth when browsing a large library in one session.
class ChapterTextCache {
  ChapterTextCache({this.capacity = 8});

  final int capacity;
  final _entries = <String, ParsedTextBook>{};
  final _order = <String>[];

  int get length => _entries.length;

  ParsedTextBook? get(String key) {
    final value = _entries[key];
    if (value == null) return null;
    _order.remove(key);
    _order.add(key);
    return value;
  }

  void put(String key, ParsedTextBook book) {
    if (_entries.containsKey(key)) {
      _order.remove(key);
    }
    _entries[key] = book;
    _order.add(key);
    while (_order.length > capacity) {
      final evicted = _order.removeAt(0);
      _entries.remove(evicted);
    }
  }

  void invalidateBook(String bookIdPrefix) {
    final doomed = _order.where((k) => k.startsWith(bookIdPrefix)).toList();
    for (final key in doomed) {
      _order.remove(key);
      _entries.remove(key);
    }
  }

  void clear() {
    _entries.clear();
    _order.clear();
  }

  static String keyFor({
    required String bookId,
    required String filePath,
    int? modifiedMs,
  }) {
    return '$bookId|$filePath|${modifiedMs ?? 0}';
  }
}
