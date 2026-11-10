import 'package:flutter_test/flutter_test.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/continue_reading.dart';

Book _book({required String id, required double progress, DateTime? opened}) {
  return Book(
    id: id,
    title: id,
    author: 'Author',
    filePath: '/tmp/$id.epub',
    format: BookFormat.epub,
    dateAdded: DateTime(2026, 1, 1),
    readingProgress: progress,
    lastOpenedAt: opened,
  );
}

void main() {
  group('ContinueReading.select', () {
    test('returns most recently opened in-progress book', () {
      final selected = ContinueReading.select([
        _book(id: 'old', progress: 0.2, opened: DateTime(2026, 1, 1)),
        _book(id: 'recent', progress: 0.5, opened: DateTime(2026, 2, 1)),
        _book(id: 'finished', progress: 1.0, opened: DateTime(2026, 3, 1)),
        _book(id: 'fresh', progress: 0.0, opened: DateTime(2026, 4, 1)),
      ]);
      expect(selected?.id, 'recent');
    });

    test('returns null when nothing is in progress', () {
      expect(
        ContinueReading.select([
          _book(id: 'a', progress: 0.0, opened: DateTime(2026, 1, 1)),
          _book(id: 'b', progress: 1.0, opened: DateTime(2026, 1, 2)),
        ]),
        isNull,
      );
    });
  });
}
