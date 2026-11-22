import 'package:flutter_test/flutter_test.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/domain/entities/idea_thread.dart';
import 'package:textara/domain/services/thread_insights.dart';

void main() {
  const generator = ThreadInsightGenerator();

  ThreadEvidence evidence({
    required String text,
    String? note,
    String? reflection,
  }) {
    final now = DateTime(2024);
    return ThreadEvidence(
      threadId: 't1',
      bookTitle: 'Book',
      reflection: reflection,
      sortOrder: 0,
      addedAt: now,
      highlight: Highlight(
        id: text.hashCode.toString(),
        bookId: 'b1',
        selectedText: text,
        colour: HighlightColour.yellow,
        note: note,
        startOffset: 0,
        endOffset: text.length,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  test('empty evidence yields needsEvidence insight', () {
    final thread = IdeaThread(
      id: 't1',
      title: 'Q',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
    final insights = generator.generate(thread: thread, evidence: const []);
    expect(insights, hasLength(1));
    expect(insights.first.kind, ThreadInsightKind.needsEvidence);
  });

  test('recurring term is detected across passages', () {
    final thread = IdeaThread(
      id: 't1',
      title: 'Q',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
    final insights = generator.generate(
      thread: thread,
      evidence: [
        evidence(text: 'Attention is scarce in modern life'),
        evidence(text: 'Deep attention requires practice'),
      ],
    );
    expect(
      insights.any((i) => i.kind == ThreadInsightKind.recurringTerm),
      isTrue,
    );
  });

  test('orphan notes without reflection are flagged', () {
    final thread = IdeaThread(
      id: 't1',
      title: 'Q',
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );
    final insights = generator.generate(
      thread: thread,
      evidence: [
        evidence(text: 'A unique passage about gardens', note: 'Interesting'),
      ],
    );
    expect(insights.any((i) => i.kind == ThreadInsightKind.orphanNote), isTrue);
  });
}
