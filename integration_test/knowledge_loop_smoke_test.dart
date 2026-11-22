import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/domain/entities/backup_data.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/idea_thread.dart';
import 'package:textara/domain/services/thread_insights.dart';

/// Headless smoke of the knowledge loop contracts (import → annotate → thread → backup).
/// Full UI driver coverage belongs on a device/emulator job; CI runs this as a Dart smoke.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('knowledge loop entities round-trip through BackupData', (
    tester,
  ) async {
    final now = DateTime(2024, 6, 1);
    final book = Book(
      id: 'b1',
      title: 'Sample',
      author: 'Author',
      filePath: '/tmp/sample.epub',
      format: BookFormat.epub,
      dateAdded: now,
    );
    final highlight = Highlight(
      id: 'h1',
      bookId: book.id,
      selectedText: 'Attention is a skill',
      colour: HighlightColour.yellow,
      startOffset: 0,
      endOffset: 20,
      createdAt: now,
      updatedAt: now,
      chapterId: 'ch_0',
    );
    final thread = IdeaThread(
      id: 't1',
      title: 'What is attention?',
      createdAt: now,
      updatedAt: now,
      evidenceCount: 1,
    );
    final link = ThreadHighlightLink(
      threadId: thread.id,
      highlightId: highlight.id,
      sortOrder: 0,
      addedAt: now,
      reflection: 'Core claim',
    );

    final backup = BackupData(
      version: '1.0.0',
      exportedAt: now,
      books: [book],
      highlights: [highlight],
      bookmarks: const [],
      collections: const [],
      ideaThreads: [thread],
      threadHighlightLinks: [link],
    );

    expect(backup.isValid, isTrue);
    final roundTrip = BackupData.fromJson(backup.toJson());
    expect(roundTrip.books.single.title, 'Sample');
    expect(roundTrip.highlights.single.selectedText, contains('Attention'));
    expect(roundTrip.ideaThreads.single.title, contains('attention'));
    expect(roundTrip.threadHighlightLinks.single.reflection, 'Core claim');

    final emptyInsights = const ThreadInsightGenerator().generate(
      thread: thread,
      evidence: const [],
    );
    expect(emptyInsights.first.kind, ThreadInsightKind.needsEvidence);

    final highlight2 = Highlight(
      id: 'h2',
      bookId: book.id,
      selectedText: 'Attention compounds over years',
      colour: HighlightColour.green,
      startOffset: 0,
      endOffset: 10,
      createdAt: now,
      updatedAt: now,
    );
    final insights = const ThreadInsightGenerator().generate(
      thread: thread,
      evidence: [
        ThreadEvidence(
          threadId: thread.id,
          highlight: highlight,
          bookTitle: book.title,
          reflection: link.reflection,
          sortOrder: 0,
          addedAt: now,
        ),
        ThreadEvidence(
          threadId: thread.id,
          highlight: highlight2,
          bookTitle: book.title,
          sortOrder: 1,
          addedAt: now,
        ),
      ],
    );
    expect(
      insights.any((i) => i.kind == ThreadInsightKind.recurringTerm),
      isTrue,
    );
  });
}
