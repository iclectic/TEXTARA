import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/idea_thread.dart';
import 'package:textara/presentation/providers/app_providers.dart';

class AnnotationEditorResult {
  final HighlightColour colour;
  final String? note;
  final String? threadId;

  const AnnotationEditorResult({
    required this.colour,
    this.note,
    this.threadId,
  });
}

/// Colour / note / optional Idea Thread picker shown when creating a highlight.
Future<AnnotationEditorResult?> showAnnotationEditorSheet({
  required BuildContext context,
  required String selectedText,
  HighlightColour initialColour = HighlightColour.yellow,
}) {
  return showModalBottomSheet<AnnotationEditorResult>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _AnnotationEditorSheet(
      selectedText: selectedText,
      initialColour: initialColour,
    ),
  );
}

class _AnnotationEditorSheet extends ConsumerStatefulWidget {
  final String selectedText;
  final HighlightColour initialColour;

  const _AnnotationEditorSheet({
    required this.selectedText,
    required this.initialColour,
  });

  @override
  ConsumerState<_AnnotationEditorSheet> createState() =>
      _AnnotationEditorSheetState();
}

class _AnnotationEditorSheetState
    extends ConsumerState<_AnnotationEditorSheet> {
  late HighlightColour _colour;
  final _noteController = TextEditingController();
  String? _threadId;
  List<IdeaThread> _threads = const [];

  @override
  void initState() {
    super.initState();
    _colour = widget.initialColour;
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    final threads = await ref.read(ideaThreadDaoProvider).getAllThreads();
    if (!mounted) return;
    setState(() => _threads = threads);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Color _swatch(HighlightColour colour) {
    switch (colour) {
      case HighlightColour.yellow:
        return const Color(0xFFFFF176);
      case HighlightColour.green:
        return const Color(0xFFA5D6A7);
      case HighlightColour.blue:
        return const Color(0xFF90CAF9);
      case HighlightColour.pink:
        return const Color(0xFFF48FB1);
      case HighlightColour.orange:
        return const Color(0xFFFFCC80);
      case HighlightColour.purple:
        return const Color(0xFFCE93D8);
      case HighlightColour.red:
        return const Color(0xFFEF9A9A);
      case HighlightColour.teal:
        return const Color(0xFF80CBC4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Save highlight',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '"${widget.selectedText}"',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Colour', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: HighlightColour.values.map((c) {
                  final selected = c == _colour;
                  return GestureDetector(
                    onTap: () => setState(() => _colour = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _swatch(c),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.dividerColor,
                          width: selected ? 3 : 1,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Note (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_threads.isNotEmpty) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String?>(
                  initialValue: _threadId,
                  decoration: const InputDecoration(
                    labelText: 'Add to Idea Thread',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('None'),
                    ),
                    ..._threads.map(
                      (t) => DropdownMenuItem<String?>(
                        value: t.id,
                        child: Text(t.title),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _threadId = v),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  final note = _noteController.text.trim();
                  Navigator.of(context).pop(
                    AnnotationEditorResult(
                      colour: _colour,
                      note: note.isEmpty ? null : note,
                      threadId: _threadId,
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
