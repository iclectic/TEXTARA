import 'package:flutter_test/flutter_test.dart';
import 'package:textara/data/services/chapter_text_cache.dart';
import 'package:textara/domain/entities/parsed_text_book.dart';

void main() {
  test('ChapterTextCache evicts least-recently-used entries', () {
    final cache = ChapterTextCache(capacity: 2);
    final a = ParsedTextBook(
      title: 'A',
      author: 'x',
      chapters: const [TextChapter(title: '1', text: 'a')],
    );
    final b = ParsedTextBook(
      title: 'B',
      author: 'x',
      chapters: const [TextChapter(title: '1', text: 'b')],
    );
    final c = ParsedTextBook(
      title: 'C',
      author: 'x',
      chapters: const [TextChapter(title: '1', text: 'c')],
    );

    cache.put('a', a);
    cache.put('b', b);
    expect(cache.length, 2);

    // Touch a so b becomes LRU.
    expect(cache.get('a')?.title, 'A');
    cache.put('c', c);

    expect(cache.get('a')?.title, 'A');
    expect(cache.get('b'), isNull);
    expect(cache.get('c')?.title, 'C');
  });

  test('keyFor includes book, path, and mtime', () {
    expect(
      ChapterTextCache.keyFor(
        bookId: '1',
        filePath: '/tmp/a.epub',
        modifiedMs: 9,
      ),
      '1|/tmp/a.epub|9',
    );
  });
}
