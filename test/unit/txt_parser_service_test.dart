import 'package:flutter_test/flutter_test.dart';
import 'package:textara/data/services/txt_parser_service.dart';

void main() {
  final parser = TxtParserService();

  test('parses a single-chapter txt', () {
    final book = parser.parseText(
      'Hello world.\n\nSecond paragraph.',
      fallbackTitle: 'Demo',
    );
    expect(book.title, 'Demo');
    expect(book.chapters, hasLength(1));
    expect(book.chapters.first.text, contains('Hello world'));
  });

  test('splits on chapter headings', () {
    final book = parser.parseText(
      'Preface words.\n\nChapter 1 Dawn\nOnce upon a time.\n\nChapter 2 Noon\nLater that day.',
      fallbackTitle: 'Story',
    );
    expect(book.chapters.length, greaterThanOrEqualTo(2));
    expect(book.chapters.any((c) => c.title.contains('Chapter 1')), isTrue);
  });

  test('splits on form feed', () {
    final book = parser.parseText(
      'Part one text\fPart two text',
      fallbackTitle: 'FF',
    );
    expect(book.chapters, hasLength(2));
  });
}
