import 'package:flutter_test/flutter_test.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/data/database/book_dao.dart';
import 'package:textara/data/database/database_helper.dart';
import 'package:textara/domain/entities/book.dart';

void main() {
  final dao = BookDao(DatabaseHelper());

  Book book({
    String title = 'Title',
    String author = 'Author',
    List<String> tags = const [],
  }) {
    return Book(
      id: '1',
      title: title,
      author: author,
      filePath: '/tmp/1.epub',
      format: BookFormat.epub,
      dateAdded: DateTime(2024),
      tags: tags,
    );
  }

  group('BookDao ranking helpers', () {
    test('exact title ranks highest', () {
      expect(dao.metadataRankForTest(book(title: 'Moby'), 'moby'), 100);
    });

    test('title prefix beats contains', () {
      final prefix = dao.metadataRankForTest(book(title: 'Moby Dick'), 'moby');
      final contains = dao.metadataRankForTest(
        book(title: 'Call me Moby'),
        'moby',
      );
      expect(prefix, greaterThan(contains));
    });

    test('buildExcerpt surrounds the match', () {
      final excerpt = dao.buildExcerptForTest(
        'alpha beta gamma delta epsilon zeta',
        'gamma',
      );
      expect(excerpt.contains('gamma'), isTrue);
    });
  });
}
