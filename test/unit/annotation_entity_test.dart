import 'package:flutter_test/flutter_test.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/annotation.dart';

void main() {
  group('Highlight entity', () {
    late Highlight highlight;

    setUp(() {
      highlight = Highlight(
        id: 'h-1',
        bookId: 'book-1',
        chapterId: 'ch-3',
        selectedText: 'It is a truth universally acknowledged',
        colour: HighlightColour.yellow,
        note: 'Famous opening line',
        startOffset: 0,
        endOffset: 38,
        createdAt: DateTime(2025, 2, 10),
        updatedAt: DateTime(2025, 2, 10),
      );
    });

    test('hasNote returns true when note is present', () {
      expect(highlight.hasNote, true);
    });

    test('hasNote returns false when note is null', () {
      final noNote = Highlight(
        id: 'h-no-note',
        bookId: 'book-1',
        selectedText: 'Some text',
        colour: HighlightColour.yellow,
        startOffset: 0,
        endOffset: 9,
        createdAt: DateTime(2025, 2, 10),
        updatedAt: DateTime(2025, 2, 10),
      );
      expect(noNote.hasNote, false);
    });

    test('hasNote returns false when note is empty', () {
      final emptyNote = highlight.copyWith(note: '');
      expect(emptyNote.hasNote, false);
    });

    test('toJson produces valid JSON map', () {
      final json = highlight.toJson();
      expect(json['id'], 'h-1');
      expect(json['bookId'], 'book-1');
      expect(json['selectedText'], 'It is a truth universally acknowledged');
      expect(json['colour'], 'yellow');
      expect(json['note'], 'Famous opening line');
      expect(json['startOffset'], 0);
      expect(json['endOffset'], 38);
    });

    test('fromJson round-trips correctly', () {
      final json = highlight.toJson();
      final restored = Highlight.fromJson(json);
      expect(restored.id, highlight.id);
      expect(restored.bookId, highlight.bookId);
      expect(restored.selectedText, highlight.selectedText);
      expect(restored.colour, highlight.colour);
      expect(restored.note, highlight.note);
      expect(restored.startOffset, highlight.startOffset);
      expect(restored.endOffset, highlight.endOffset);
    });

    test('fromJson handles missing colour gracefully', () {
      final json = highlight.toJson();
      json['colour'] = 'nonexistent';
      final restored = Highlight.fromJson(json);
      expect(restored.colour, HighlightColour.yellow);
    });

    test('copyWith updates specific fields', () {
      final updated = highlight.copyWith(
        colour: HighlightColour.blue,
        note: 'Updated note',
      );
      expect(updated.colour, HighlightColour.blue);
      expect(updated.note, 'Updated note');
      expect(updated.selectedText, highlight.selectedText);
      expect(updated.id, highlight.id);
    });

    test('equatable compares by id', () {
      final same = highlight.copyWith(note: 'Different');
      expect(highlight, equals(same));

      final different = highlight.copyWith(id: 'h-2');
      expect(highlight, isNot(equals(different)));
    });
  });

  group('Bookmark entity', () {
    late Bookmark bookmark;

    setUp(() {
      bookmark = Bookmark(
        id: 'b-1',
        bookId: 'book-1',
        chapterId: 'ch-5',
        pageNumber: 42,
        title: 'Chapter 5 - The Ball',
        createdAt: DateTime(2025, 3, 1),
      );
    });

    test('toJson produces valid JSON map', () {
      final json = bookmark.toJson();
      expect(json['id'], 'b-1');
      expect(json['bookId'], 'book-1');
      expect(json['pageNumber'], 42);
      expect(json['title'], 'Chapter 5 - The Ball');
    });

    test('fromJson round-trips correctly', () {
      final json = bookmark.toJson();
      final restored = Bookmark.fromJson(json);
      expect(restored.id, bookmark.id);
      expect(restored.bookId, bookmark.bookId);
      expect(restored.pageNumber, bookmark.pageNumber);
      expect(restored.title, bookmark.title);
    });

    test('fromJson handles missing fields gracefully', () {
      final json = <String, dynamic>{
        'id': 'b-minimal',
        'bookId': 'book-1',
      };
      final restored = Bookmark.fromJson(json);
      expect(restored.id, 'b-minimal');
      expect(restored.pageNumber, 0);
      expect(restored.title, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      final updated = bookmark.copyWith(pageNumber: 99);
      expect(updated.pageNumber, 99);
      expect(updated.title, 'Chapter 5 - The Ball');
      expect(updated.bookId, 'book-1');
    });
  });

  group('Highlight export formatting', () {
    test('markdown format includes selected text and note', () {
      final highlight = Highlight(
        id: 'h-export',
        bookId: 'book-1',
        selectedText: 'The quick brown fox',
        colour: HighlightColour.green,
        note: 'A test note',
        startOffset: 0,
        endOffset: 19,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      final markdown = _formatHighlightAsMarkdown(highlight);
      expect(markdown, contains('> The quick brown fox'));
      expect(markdown, contains('**Note:** A test note'));
    });

    test('markdown format omits note when absent', () {
      final highlight = Highlight(
        id: 'h-export-2',
        bookId: 'book-1',
        selectedText: 'Some highlighted text',
        colour: HighlightColour.pink,
        startOffset: 0,
        endOffset: 21,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      );

      final markdown = _formatHighlightAsMarkdown(highlight);
      expect(markdown, contains('> Some highlighted text'));
      expect(markdown, isNot(contains('**Note:**')));
    });
  });
}

String _formatHighlightAsMarkdown(Highlight h) {
  final buffer = StringBuffer();
  buffer.writeln('> ${h.selectedText}');
  buffer.writeln();
  if (h.hasNote) {
    buffer.writeln('**Note:** ${h.note}');
    buffer.writeln();
  }
  return buffer.toString();
}
