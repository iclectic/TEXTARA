import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/data/services/epub_chapter_cache.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/idea_thread.dart';
import 'package:textara/domain/entities/reader_settings.dart';
import 'package:textara/presentation/providers/app_providers.dart';
import 'package:textara/presentation/screens/reader/epub_reader_controller.dart';
import 'package:textara/presentation/widgets/reader/annotation_editor_sheet.dart';

class EpubReaderView extends ConsumerStatefulWidget {
  final Book book;
  final void Function(
    int page,
    int total,
    String chapterTitle,
    String chapterId,
  )
  onPageChanged;
  final EpubReaderController? controller;
  final int? initialChapterIndex;
  final String? initialChapterId;

  const EpubReaderView({
    super.key,
    required this.book,
    required this.onPageChanged,
    this.controller,
    this.initialChapterIndex,
    this.initialChapterId,
  });

  @override
  ConsumerState<EpubReaderView> createState() => _EpubReaderViewState();
}

class _EpubReaderViewState extends ConsumerState<EpubReaderView> {
  final PageController _pageController = PageController();
  List<CachedChapter> _chapters = [];
  bool _isLoading = true;
  String? _error;
  int _currentChapterIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?.attach(_jumpToChapterIndex);
    _loadEpub();
  }

  @override
  void didUpdateWidget(covariant EpubReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.detach();
      widget.controller?.attach(_jumpToChapterIndex);
    }
  }

  @override
  void dispose() {
    widget.controller?.detach();
    _pageController.dispose();
    super.dispose();
  }

  void _jumpToChapterIndex(int index) {
    if (!_pageController.hasClients || _chapters.isEmpty) return;
    final clamped = index.clamp(0, _chapters.length - 1);
    _pageController.jumpToPage(clamped);
  }

  void jumpToChapterId(String chapterId) {
    final byId = _chapters.indexWhere((c) => c.id == chapterId);
    if (byId >= 0) {
      _jumpToChapterIndex(byId);
      return;
    }
    final byTitle = _chapters.indexWhere((c) => c.title == chapterId);
    if (byTitle >= 0) {
      _jumpToChapterIndex(byTitle);
    }
  }

  Future<void> _loadEpub() async {
    try {
      final cache = ref.read(epubChapterCacheProvider);
      final loaded = await cache.chaptersFor(widget.book.filePath);

      if (!mounted) return;
      setState(() {
        _chapters = loaded;
        _isLoading = false;
      });

      var restoreIndex = widget.book.currentPage;
      if (widget.initialChapterIndex != null) {
        restoreIndex = widget.initialChapterIndex!;
      } else if (widget.initialChapterId != null) {
        final idx = loaded.indexWhere((c) => c.id == widget.initialChapterId);
        if (idx >= 0) restoreIndex = idx;
      }

      if (restoreIndex > 0 && restoreIndex < loaded.length) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(restoreIndex);
          }
        });
        _currentChapterIndex = restoreIndex;
      }

      _reportProgress();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error =
            'Could not open this EPUB file. It may be damaged or in an unsupported format.';
      });
    }
  }

  void _reportProgress() {
    if (_chapters.isEmpty) return;
    final chapter = _chapters[_currentChapterIndex];
    widget.onPageChanged(
      _currentChapterIndex,
      _chapters.length,
      chapter.title,
      chapter.id,
    );
  }

  TextStyle _getReaderTextStyle() {
    final settings = ref.watch(readerSettingsProvider);
    final dyslexia = ref.watch(dyslexiaModeProvider);

    if (dyslexia) {
      // Bundled offline font — never depend on Google Fonts for a11y.
      return const TextStyle(fontFamily: 'OpenDyslexic').copyWith(
        fontSize: settings.fontSize,
        height: settings.lineHeight + 0.15,
      );
    }

    TextStyle base;
    try {
      base = GoogleFonts.getFont(
        settings.fontFamily,
        fontSize: settings.fontSize,
        height: settings.lineHeight,
      );
    } catch (_) {
      base = TextStyle(
        fontSize: settings.fontSize,
        height: settings.lineHeight,
      );
    }

    return base;
  }

  TextAlign _getTextAlign() {
    final settings = ref.watch(readerSettingsProvider);
    switch (settings.textAlignment) {
      case TextAlignment.left:
        return TextAlign.left;
      case TextAlignment.right:
        return TextAlign.right;
      case TextAlignment.centre:
        return TextAlign.center;
      case TextAlignment.justify:
        return TextAlign.justify;
    }
  }

  Color _highlightColourValue(HighlightColour colour) {
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

  Future<void> _createHighlight({
    required String selectedText,
    required CachedChapter chapter,
    required int startOffset,
    required int endOffset,
  }) async {
    final trimmedText = selectedText.trim();
    if (trimmedText.isEmpty) return;

    final draft = await showAnnotationEditorSheet(
      context: context,
      selectedText: trimmedText,
    );
    if (draft == null || !mounted) return;

    final now = DateTime.now();
    final highlight = Highlight(
      id: now.microsecondsSinceEpoch.toString(),
      bookId: widget.book.id,
      chapterId: chapter.id,
      selectedText: trimmedText,
      colour: draft.colour,
      note: draft.note,
      startOffset: startOffset,
      endOffset: endOffset,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await ref.read(annotationDaoProvider).insertHighlight(highlight);
      var threadMessage = '';
      var threadId = draft.threadId;
      if (draft.createNewThread) {
        final thread = IdeaThread(
          id: '${now.microsecondsSinceEpoch}_thread',
          title: draft.newThreadTitle?.trim().isNotEmpty == true
              ? draft.newThreadTitle!.trim()
              : 'Idea from highlight',
          createdAt: now,
          updatedAt: now,
        );
        await ref.read(ideaThreadDaoProvider).insertThread(thread);
        threadId = thread.id;
      }
      if (threadId != null) {
        final inserted = await ref
            .read(ideaThreadDaoProvider)
            .addHighlightToThread(
              threadId: threadId,
              highlightId: highlight.id,
              reflection: draft.threadReflection,
            );
        ref.invalidate(ideaThreadsProvider);
        threadMessage = inserted
            ? ' · added to thread'
            : ' · already in thread';
      }
      ref.invalidate(bookHighlightsProvider(widget.book.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Highlight saved$threadMessage'),
          duration: const Duration(seconds: 2),
          action: threadId == null
              ? null
              : SnackBarAction(
                  label: 'Undo',
                  onPressed: () async {
                    await ref
                        .read(ideaThreadDaoProvider)
                        .removeHighlightFromThread(
                          threadId: threadId!,
                          highlightId: highlight.id,
                        );
                    ref.invalidate(ideaThreadsProvider);
                  },
                ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not save highlight'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _createHighlight(
              selectedText: selectedText,
              chapter: chapter,
              startOffset: startOffset,
              endOffset: endOffset,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(readerSettingsProvider);
    final highlightsAsync = ref.watch(bookHighlightsProvider(widget.book.id));
    final highlights = highlightsAsync.valueOrNull ?? const <Highlight>[];

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to open book',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_chapters.isEmpty) {
      return Center(
        child: Text(
          'This book appears to have no readable content.',
          style: theme.textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: _chapters.length,
      onPageChanged: (index) {
        setState(() => _currentChapterIndex = index);
        _reportProgress();
      },
      itemBuilder: (context, index) {
        final chapter = _chapters[index];
        final chapterHighlights = highlights
            .where(
              (h) => h.chapterId == chapter.id || h.chapterId == chapter.title,
            )
            .toList();
        return _buildChapterView(chapter, theme, settings, chapterHighlights);
      },
    );
  }

  Widget _buildChapterView(
    CachedChapter chapter,
    ThemeData theme,
    ReaderSettings settings,
    List<Highlight> highlights,
  ) {
    final textStyle = _getReaderTextStyle();
    final textAlign = _getTextAlign();
    final margin = ref.watch(readerSettingsProvider).horizontalMargin;
    final paragraphSpacing = ref.watch(readerSettingsProvider).paragraphSpacing;

    final paragraphs = chapter.text
        .split('\n')
        .where((p) => p.trim().isNotEmpty)
        .toList();

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        margin,
        MediaQuery.of(context).padding.top + 64,
        margin,
        MediaQuery.of(context).padding.bottom + 80,
      ),
      itemCount: paragraphs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              chapter.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }
        final paragraph = paragraphs[index - 1];
        return Padding(
          padding: EdgeInsets.only(bottom: paragraphSpacing),
          child: SelectableText.rich(
            TextSpan(
              style: textStyle.copyWith(color: theme.colorScheme.onSurface),
              children: _buildHighlightedSpans(paragraph, highlights, theme),
            ),
            textAlign: textAlign,
            contextMenuBuilder: (context, editableTextState) {
              final value = editableTextState.textEditingValue;
              final selection = value.selection;
              final selectedText = selection.textInside(value.text);
              final buttonItems = <ContextMenuButtonItem>[
                if (selectedText.trim().isNotEmpty)
                  ContextMenuButtonItem(
                    label: 'Highlight',
                    onPressed: () {
                      editableTextState.hideToolbar();
                      _createHighlight(
                        selectedText: selectedText,
                        chapter: chapter,
                        startOffset: selection.start,
                        endOffset: selection.end,
                      );
                    },
                  ),
                ...editableTextState.contextMenuButtonItems,
              ];
              return AdaptiveTextSelectionToolbar.buttonItems(
                anchors: editableTextState.contextMenuAnchors,
                buttonItems: buttonItems,
              );
            },
          ),
        );
      },
    );
  }

  /// Paints highlight colours by matching stored text (tolerant to offset drift).
  List<InlineSpan> _buildHighlightedSpans(
    String paragraph,
    List<Highlight> highlights,
    ThemeData theme,
  ) {
    if (highlights.isEmpty || paragraph.isEmpty) {
      return [TextSpan(text: paragraph)];
    }

    final ranges = <({int start, int end, HighlightColour colour})>[];
    for (final h in highlights) {
      final needle = h.selectedText.trim();
      if (needle.isEmpty) continue;
      var from = 0;
      while (from < paragraph.length) {
        final idx = paragraph.indexOf(needle, from);
        if (idx < 0) break;
        ranges.add((start: idx, end: idx + needle.length, colour: h.colour));
        from = idx + needle.length;
      }
    }
    if (ranges.isEmpty) {
      return [TextSpan(text: paragraph)];
    }
    ranges.sort((a, b) => a.start.compareTo(b.start));

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final range in ranges) {
      if (range.start < cursor) continue;
      if (range.start > cursor) {
        spans.add(TextSpan(text: paragraph.substring(cursor, range.start)));
      }
      spans.add(
        TextSpan(
          text: paragraph.substring(range.start, range.end),
          style: TextStyle(
            backgroundColor: _highlightColourValue(
              range.colour,
            ).withValues(alpha: 0.55),
          ),
        ),
      );
      cursor = range.end;
    }
    if (cursor < paragraph.length) {
      spans.add(TextSpan(text: paragraph.substring(cursor)));
    }
    return spans;
  }
}
