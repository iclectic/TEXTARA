import 'package:textara/domain/entities/idea_thread.dart';

enum ThreadInsightKind { needsEvidence, recurringTerm, orphanNote }

class ThreadInsight {
  final ThreadInsightKind kind;
  final String title;
  final String reason;
  final String? term;

  const ThreadInsight({
    required this.kind,
    required this.title,
    required this.reason,
    this.term,
  });
}

/// Purely local, offline suggestions for Idea Threads (no network).
class ThreadInsightGenerator {
  const ThreadInsightGenerator();

  List<ThreadInsight> generate({
    required IdeaThread thread,
    required List<ThreadEvidence> evidence,
  }) {
    final insights = <ThreadInsight>[];

    if (evidence.isEmpty) {
      insights.add(
        const ThreadInsight(
          kind: ThreadInsightKind.needsEvidence,
          title: 'This thread needs evidence',
          reason:
              'Add a highlight from a book so the synthesis is grounded in sources.',
        ),
      );
      return insights;
    }

    final orphanNotes = evidence
        .where(
          (e) =>
              e.highlight.hasNote &&
              (e.reflection == null || e.reflection!.trim().isEmpty),
        )
        .length;
    if (orphanNotes > 0) {
      insights.add(
        ThreadInsight(
          kind: ThreadInsightKind.orphanNote,
          title:
              '$orphanNotes reading note${orphanNotes == 1 ? '' : 's'} without a thread reflection',
          reason:
              'These passages have book notes but no thread-level reflection yet.',
        ),
      );
    }

    final term = _mostCommonTerm(evidence);
    if (term != null) {
      insights.add(
        ThreadInsight(
          kind: ThreadInsightKind.recurringTerm,
          title: 'Recurring term: “$term”',
          reason:
              'This word appears across multiple evidence passages in this thread.',
          term: term,
        ),
      );
    }

    return insights;
  }

  String? _mostCommonTerm(List<ThreadEvidence> evidence) {
    if (evidence.length < 2) return null;
    final counts = <String, int>{};
    final stop = {
      'the',
      'and',
      'a',
      'an',
      'to',
      'of',
      'in',
      'on',
      'for',
      'is',
      'it',
      'that',
      'this',
      'with',
      'as',
      'be',
      'are',
      'was',
      'were',
      'or',
      'by',
      'from',
      'at',
      'not',
      'but',
      'have',
      'has',
      'had',
      'you',
      'your',
      'we',
      'they',
      'their',
      'his',
      'her',
      'its',
      'our',
    };
    for (final item in evidence) {
      final words = item.highlight.selectedText
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 3 && !stop.contains(w));
      final seen = <String>{};
      for (final w in words) {
        if (seen.add(w)) {
          counts[w] = (counts[w] ?? 0) + 1;
        }
      }
    }
    final recurring = counts.entries.where((e) => e.value >= 2).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (recurring.isEmpty) return null;
    return recurring.first.key;
  }
}
