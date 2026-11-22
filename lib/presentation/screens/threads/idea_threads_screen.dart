import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/domain/entities/idea_thread.dart';
import 'package:textara/domain/services/thread_insights.dart';
import 'package:textara/presentation/providers/app_providers.dart';
import 'package:textara/presentation/screens/reader/reader_screen.dart';
import 'package:uuid/uuid.dart';

class IdeaThreadsScreen extends ConsumerWidget {
  final bool embeddedInShell;

  const IdeaThreadsScreen({super.key, this.embeddedInShell = false});

  Future<void> _createThread(BuildContext context, WidgetRef ref) async {
    final thread = await showDialog<IdeaThread>(
      context: context,
      builder: (_) => const _ThreadEditorDialog(),
    );
    if (thread == null) return;
    await ref.read(ideaThreadDaoProvider).insertThread(thread);
    ref.invalidate(ideaThreadsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(ideaThreadsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Idea Threads'),
        automaticallyImplyLeading: !embeddedInShell,
      ),
      body: threadsAsync.when(
        data: (threads) => threads.isEmpty
            ? _EmptyThreadsState(onCreate: () => _createThread(context, ref))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: threads.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final thread = threads[index];
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        foregroundColor: theme.colorScheme.primary,
                        child: const Icon(Icons.account_tree_outlined),
                      ),
                      title: Text(
                        thread.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _threadSummary(thread),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      trailing: Text(
                        '${thread.evidenceCount}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                IdeaThreadDetailScreen(thread: thread),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            const Center(child: Text('Could not load your idea threads.')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createThread(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New thread'),
      ),
    );
  }

  String _threadSummary(IdeaThread thread) {
    if (thread.description?.trim().isNotEmpty == true) {
      return thread.description!;
    }
    if (thread.synthesisNote?.trim().isNotEmpty == true) {
      return thread.synthesisNote!;
    }
    return thread.evidenceCount == 0
        ? 'Start with a question, then add supporting passages.'
        : '${thread.evidenceCount} source-linked passages';
  }
}

class IdeaThreadDetailScreen extends ConsumerStatefulWidget {
  final IdeaThread thread;

  const IdeaThreadDetailScreen({super.key, required this.thread});

  @override
  ConsumerState<IdeaThreadDetailScreen> createState() =>
      _IdeaThreadDetailScreenState();
}

class _IdeaThreadDetailScreenState
    extends ConsumerState<IdeaThreadDetailScreen> {
  late IdeaThread _thread;
  late TextEditingController _synthesisController;
  final Set<String> _dismissedInsights = {};
  String? _bookFilter;

  @override
  void initState() {
    super.initState();
    _thread = widget.thread;
    _synthesisController = TextEditingController(
      text: _thread.synthesisNote ?? '',
    );
  }

  @override
  void dispose() {
    _synthesisController.dispose();
    super.dispose();
  }

  Future<void> _saveSynthesis() async {
    final updated = _thread.copyWith(
      synthesisNote: _synthesisController.text.trim(),
      updatedAt: DateTime.now(),
    );
    await ref.read(ideaThreadDaoProvider).updateThread(updated);
    if (!mounted) return;
    setState(() => _thread = updated);
    ref.invalidate(ideaThreadsProvider);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Synthesis saved')));
  }

  Future<void> _editThread() async {
    final updated = await showDialog<IdeaThread>(
      context: context,
      builder: (_) => _ThreadEditorDialog(thread: _thread),
    );
    if (updated == null) return;
    await ref.read(ideaThreadDaoProvider).updateThread(updated);
    if (!mounted) return;
    setState(() => _thread = updated);
    ref.invalidate(ideaThreadsProvider);
  }

  Future<void> _exportThread(List<ThreadEvidence> evidence) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export thread'),
        content: Text(
          'Export “${_thread.title}” with ${evidence.length} evidence '
          'passage${evidence.length == 1 ? '' : 's'}'
          '${_thread.synthesisNote?.trim().isNotEmpty == true ? ' and your synthesis' : ''} '
          'as Markdown?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Export'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final path = await ref
        .read(exportServiceProvider)
        .exportThreadToMarkdown(_thread);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Exported to: $path')));
  }

  Future<void> _openEvidence(ThreadEvidence item) async {
    final book = await ref
        .read(libraryRepositoryProvider)
        .getBookById(item.highlight.bookId);
    if (book == null || !mounted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Source book is no longer in your library.'),
          ),
        );
      }
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          book: book,
          initialChapterId: item.highlight.chapterId,
        ),
      ),
    );
  }

  Future<void> _editReflection(ThreadEvidence item) async {
    final controller = TextEditingController(text: item.reflection ?? '');
    final saved = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thread reflection'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Why does this passage belong in the thread?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == null) return;
    await ref
        .read(ideaThreadDaoProvider)
        .updateEvidenceReflection(
          threadId: _thread.id,
          highlightId: item.highlight.id,
          reflection: saved.isEmpty ? null : saved,
        );
    ref.invalidate(threadEvidenceProvider(_thread.id));
  }

  Future<void> _reorder(
    List<ThreadEvidence> evidence,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final items = [...evidence];
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    await ref
        .read(ideaThreadDaoProvider)
        .reorderEvidence(
          threadId: _thread.id,
          highlightIdsInOrder: items.map((e) => e.highlight.id).toList(),
        );
    ref.invalidate(threadEvidenceProvider(_thread.id));
  }

  Future<void> _deleteThread() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete thread?'),
        content: const Text(
          'This removes the thread but keeps your original highlights.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(ideaThreadDaoProvider).deleteThread(_thread.id);
    if (!mounted) return;
    ref.invalidate(ideaThreadsProvider);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final evidenceAsync = ref.watch(threadEvidenceProvider(_thread.id));
    final insightsEnabled = ref.watch(threadInsightsEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_thread.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded),
            tooltip: 'Export Markdown',
            onPressed: () {
              final evidence = evidenceAsync.valueOrNull ?? const [];
              _exportThread(evidence);
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit thread',
            onPressed: _editThread,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete thread',
            onPressed: _deleteThread,
          ),
        ],
      ),
      body: evidenceAsync.when(
        data: (allEvidence) {
          final books = allEvidence.map((e) => e.bookTitle).toSet().toList()
            ..sort();
          final evidence = _bookFilter == null
              ? allEvidence
              : allEvidence.where((e) => e.bookTitle == _bookFilter).toList();
          final insights = insightsEnabled
              ? const ThreadInsightGenerator()
                    .generate(thread: _thread, evidence: allEvidence)
                    .where((i) => !_dismissedInsights.contains(i.title))
                    .toList()
              : const <ThreadInsight>[];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_thread.description?.trim().isNotEmpty == true) ...[
                Text(_thread.description!, style: theme.textTheme.bodyLarge),
                const SizedBox(height: 20),
              ],
              if (insights.isNotEmpty) ...[
                Text('Suggestions', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                ...insights.map(
                  (insight) => Card(
                    child: ListTile(
                      title: Text(insight.title),
                      subtitle: Text(insight.reason),
                      trailing: IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Dismiss',
                        onPressed: () => setState(
                          () => _dismissedInsights.add(insight.title),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text('Your synthesis', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              TextField(
                controller: _synthesisController,
                minLines: 4,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText:
                      'What is the question, argument, or insight taking shape?',
                  border: OutlineInputBorder(),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _saveSynthesis,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save'),
                ),
              ),
              const Divider(height: 32),
              Row(
                children: [
                  Text('Evidence', style: theme.textTheme.titleMedium),
                  const Spacer(),
                  if (books.length > 1)
                    DropdownButton<String?>(
                      value: _bookFilter,
                      hint: const Text('All books'),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All books'),
                        ),
                        ...books.map(
                          (b) => DropdownMenuItem<String?>(
                            value: b,
                            child: Text(b),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _bookFilter = v),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Drag to reorder · tap to open source · long-press to reflect',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 8),
              if (evidence.isEmpty)
                const _EvidenceEmptyState()
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: evidence.length,
                  onReorder: (oldIndex, newIndex) =>
                      _reorder(evidence, oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final item = evidence[index];
                    return _EvidenceCard(
                      key: ValueKey(item.highlight.id),
                      evidence: item,
                      onOpen: () => _openEvidence(item),
                      onEditReflection: () => _editReflection(item),
                      onRemove: () async {
                        await ref
                            .read(ideaThreadDaoProvider)
                            .removeHighlightFromThread(
                              threadId: _thread.id,
                              highlightId: item.highlight.id,
                            );
                        ref.invalidate(threadEvidenceProvider(_thread.id));
                        ref.invalidate(ideaThreadsProvider);
                      },
                    );
                  },
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(
          child: Text('Could not load evidence for this thread.'),
        ),
      ),
    );
  }
}

class _ThreadEditorDialog extends StatefulWidget {
  final IdeaThread? thread;

  const _ThreadEditorDialog({this.thread});

  @override
  State<_ThreadEditorDialog> createState() => _ThreadEditorDialogState();
}

class _ThreadEditorDialogState extends State<_ThreadEditorDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.thread?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.thread?.description ?? '',
    );
    _tagsController = TextEditingController(
      text: widget.thread?.tags.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Give this thread a title or question.');
      return;
    }
    final now = DateTime.now();
    final tags = _tagsController.text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
    Navigator.of(context).pop(
      IdeaThread(
        id: widget.thread?.id ?? const Uuid().v4(),
        title: title,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        tags: tags,
        synthesisNote: widget.thread?.synthesisNote,
        createdAt: widget.thread?.createdAt ?? now,
        updatedAt: now,
        evidenceCount: widget.thread?.evidenceCount ?? 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.thread == null ? 'New idea thread' : 'Edit idea thread',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Question or title',
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'What are you trying to understand?',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags',
                hintText: 'research, writing, attention',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

class _EmptyThreadsState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyThreadsState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_tree_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Turn reading into ideas', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Create a question or thought, then collect source-linked highlights from across your library.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create your first thread'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EvidenceEmptyState extends StatelessWidget {
  const _EvidenceEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Text(
        'No evidence yet. Open a book, select a highlight, choose a colour and Idea Thread, then save. You can add a reflection when you capture.',
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  final ThreadEvidence evidence;
  final Future<void> Function() onRemove;
  final VoidCallback onOpen;
  final VoidCallback onEditReflection;

  const _EvidenceCard({
    super.key,
    required this.evidence,
    required this.onRemove,
    required this.onOpen,
    required this.onEditReflection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onOpen,
        onLongPress: onEditReflection,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      evidence.bookTitle,
                      style: theme.textTheme.labelLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_note_outlined),
                    tooltip: 'Edit reflection',
                    onPressed: onEditReflection,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Remove from thread',
                    onPressed: () => onRemove(),
                  ),
                ],
              ),
              Text(
                '“${evidence.highlight.selectedText}”',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.45,
                ),
              ),
              if (evidence.highlight.hasNote) ...[
                const SizedBox(height: 8),
                Text(
                  'Note: ${evidence.highlight.note}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (evidence.hasReflection) ...[
                const SizedBox(height: 8),
                Text(
                  'Reflection: ${evidence.reflection}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
