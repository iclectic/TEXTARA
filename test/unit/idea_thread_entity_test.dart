import 'package:flutter_test/flutter_test.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/domain/entities/idea_thread.dart';

void main() {
  group('IdeaThread', () {
    final createdAt = DateTime(2026, 7, 20);
    final thread = IdeaThread(
      id: 'thread-1',
      title: 'How does attention shape creative work?',
      description: 'Passages to develop an essay idea.',
      tags: const ['writing', 'attention'],
      synthesisNote: 'Attention creates the conditions for deep work.',
      createdAt: createdAt,
      updatedAt: createdAt,
      evidenceCount: 2,
    );

    test('round-trips through JSON', () {
      final restored = IdeaThread.fromJson(thread.toJson());

      expect(restored.id, thread.id);
      expect(restored.title, thread.title);
      expect(restored.tags, thread.tags);
      expect(restored.synthesisNote, thread.synthesisNote);
    });

    test('uses safe values for missing optional JSON fields', () {
      final restored = IdeaThread.fromJson({'id': 'thread-2'});

      expect(restored.title, 'Untitled Thread');
      expect(restored.tags, isEmpty);
      expect(restored.description, isNull);
    });

    test('copyWith preserves fields that are not changed', () {
      final updated = thread.copyWith(title: 'A revised question');

      expect(updated.title, 'A revised question');
      expect(updated.tags, thread.tags);
      expect(updated.evidenceCount, thread.evidenceCount);
    });
  });

  group('ThreadEvidence', () {
    test('reports whether a reflection is present', () {
      final highlight = Highlight(
        id: 'highlight-1',
        bookId: 'book-1',
        selectedText: 'Attention is the beginning of devotion.',
        colour: HighlightColour.yellow,
        startOffset: 0,
        endOffset: 39,
        createdAt: DateTime(2026, 7, 20),
        updatedAt: DateTime(2026, 7, 20),
      );
      final evidence = ThreadEvidence(
        threadId: 'thread-1',
        highlight: highlight,
        bookTitle: 'The Practice',
        reflection: 'This supports the thread premise.',
        sortOrder: 0,
        addedAt: DateTime(2026, 7, 20),
      );

      expect(evidence.hasReflection, isTrue);
      expect(
        ThreadEvidence(
          threadId: evidence.threadId,
          highlight: highlight,
          bookTitle: evidence.bookTitle,
          reflection: '  ',
          sortOrder: evidence.sortOrder,
          addedAt: evidence.addedAt,
        ).hasReflection,
        isFalse,
      );
    });
  });
}
