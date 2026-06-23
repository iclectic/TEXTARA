import 'package:flutter_test/flutter_test.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/book.dart';

void main() {
  group('Book entity', () {
    late Book book;

    setUp(() {
      book = Book(
        id: 'test-id-1',
        title: 'Pride and Prejudice',
        author: 'Jane Austen',
        description: 'A classic novel.',
        filePath: '/books/pride.epub',
        format: BookFormat.epub,
        readingStatus: ReadingStatus.reading,
        readingProgress: 0.45,
        currentPage: 12,
        totalPages: 27,
        dateAdded: DateTime(2025, 1, 15),
        lastOpenedAt: DateTime(2025, 3, 1),
        isFavourite: true,
        tags: ['classics', 'romance'],
        fileSizeBytes: 512000,
      );
    });

    test('formattedProgress returns correct percentage string', () {
      expect(book.formattedProgress, '45%');
    });

    test('formattedProgress returns 0% for new book', () {
      final newBook = book.copyWith(readingProgress: 0.0);
      expect(newBook.formattedProgress, '0%');
    });

    test('formattedProgress returns 100% for finished book', () {
      final finished = book.copyWith(readingProgress: 1.0);
      expect(finished.formattedProgress, '100%');
    });

    test('isEpub returns true for EPUB books', () {
      expect(book.isEpub, true);
      expect(book.isPdf, false);
    });

    test('isPdf returns true for PDF books', () {
      final pdf = book.copyWith(format: BookFormat.pdf);
      expect(pdf.isPdf, true);
      expect(pdf.isEpub, false);
    });

    test('copyWith preserves unchanged fields', () {
      final updated = book.copyWith(title: 'New Title');
      expect(updated.title, 'New Title');
      expect(updated.author, 'Jane Austen');
      expect(updated.id, 'test-id-1');
      expect(updated.readingProgress, 0.45);
      expect(updated.isFavourite, true);
      expect(updated.tags, ['classics', 'romance']);
    });

    test('toJson produces valid JSON map', () {
      final json = book.toJson();
      expect(json['id'], 'test-id-1');
      expect(json['title'], 'Pride and Prejudice');
      expect(json['author'], 'Jane Austen');
      expect(json['format'], 'epub');
      expect(json['readingStatus'], 'reading');
      expect(json['readingProgress'], 0.45);
      expect(json['isFavourite'], true);
      expect(json['tags'], ['classics', 'romance']);
    });

    test('fromJson round-trips correctly', () {
      final json = book.toJson();
      final restored = Book.fromJson(json);
      expect(restored.id, book.id);
      expect(restored.title, book.title);
      expect(restored.author, book.author);
      expect(restored.format, book.format);
      expect(restored.readingStatus, book.readingStatus);
      expect(restored.readingProgress, book.readingProgress);
      expect(restored.isFavourite, book.isFavourite);
      expect(restored.tags, book.tags);
    });

    test('fromJson handles missing fields gracefully', () {
      final json = <String, dynamic>{
        'id': 'minimal-id',
        'filePath': '/books/test.epub',
      };
      final restored = Book.fromJson(json);
      expect(restored.id, 'minimal-id');
      expect(restored.title, 'Untitled');
      expect(restored.author, 'Unknown Author');
      expect(restored.format, BookFormat.epub);
      expect(restored.readingStatus, ReadingStatus.notStarted);
      expect(restored.readingProgress, 0.0);
      expect(restored.isFavourite, false);
      expect(restored.tags, isEmpty);
    });

    test('fromJson handles malformed date gracefully', () {
      final json = book.toJson();
      json['dateAdded'] = 'not-a-date';
      final restored = Book.fromJson(json);
      expect(restored.dateAdded, isNotNull);
    });

    test('equatable compares by id', () {
      final sameid = book.copyWith(title: 'Different Title');
      expect(book, equals(sameid));

      final differentId = book.copyWith(id: 'other-id');
      expect(book, isNot(equals(differentId)));
    });
  });

  group('Reading progress persistence', () {
    test('progress clamps to valid range in formattedProgress', () {
      final overProgress = Book(
        id: 'over',
        title: 'Test',
        author: 'Test',
        filePath: '/test.epub',
        format: BookFormat.epub,
        readingProgress: 1.5,
        dateAdded: DateTime.now(),
      );
      expect(overProgress.formattedProgress, '100%');

      final negativeProgress = Book(
        id: 'neg',
        title: 'Test',
        author: 'Test',
        filePath: '/test.epub',
        format: BookFormat.epub,
        readingProgress: -0.1,
        dateAdded: DateTime.now(),
      );
      expect(negativeProgress.formattedProgress, '0%');
    });
  });
}
