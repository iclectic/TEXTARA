import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/reader_location.dart';
import 'package:textara/domain/entities/reader_settings.dart';
import 'package:textara/presentation/providers/app_providers.dart';
import 'package:textara/presentation/widgets/reader/dictionary_sheet.dart';

class EpubReaderView extends ConsumerStatefulWidget {
  final Book book;
  final void Function(int page, int total, String chapterTitle) onPageChanged;

  const EpubReaderView({
    super.key,
    required this.book,
    required this.onPageChanged,
  });

  @override
  ConsumerState<EpubReaderView> createState() => _EpubReaderViewState();
}

class _EpubReaderViewState extends ConsumerState<EpubReaderView> {
  final PageController _pageController = PageController();
  List<_ChapterContent> _chapters = [];
  bool _isLoading = true;
  String? _error;
  int _currentChapterIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadEpub();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadEpub() async {
    try {
      final parser = ref.read(epubParserProvider);
      final epubBook = await parser.parseEpub(widget.book.filePath);
      final chapters = epubBook.chapters;
      final loaded = <_ChapterContent>[];

      for (int i = 0; i < chapters.length; i++) {
        final chapter = chapters[i];
        final html = chapter.htmlContent ?? '';
        if (html.isEmpty) continue;

        final document = html_parser.parse(html);
        final text = document.body?.text ?? '';
        if (text.trim().isEmpty) continue;

        loaded.add(
          _ChapterContent(
            title: chapter.title ?? 'Chapter ${i + 1}',
            text: text.trim(),
            htmlContent: html,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _chapters = loaded;
        _isLoading = false;
      });

      // Restore auto-resume position (chapter index is typography-stable).
      final resume = ReaderLocation.fromBook(widget.book)
          .preservedAcrossTypographyChange();
      if (resume.pageIndex > 0 && resume.pageIndex < _chapters.length) {
        _pageController.jumpToPage(resume.pageIndex);
        _currentChapterIndex = resume.pageIndex;
      }

      _reportProgress();
    } catch (e) {
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
    final title = _currentChapterIndex < _chapters.length
        ? _chapters[_currentChapterIndex].title
        : '';
    widget.onPageChanged(_currentChapterIndex, _chapters.length, title);
  }

  void _handlePendingJump(ReaderLocation? location) {
    if (location == null || _chapters.isEmpty) return;
    if (location.format != BookFormat.epub) return;
    final target = location.pageIndex.clamp(0, _chapters.length - 1);
    if (!_pageController.hasClients) return;
    _pageController.jumpToPage(target);
    setState(() => _currentChapterIndex = target);
    _reportProgress();
    ref.read(pendingReaderJumpProvider.notifier).state = null;
  }

  TextStyle _getReaderTextStyle() {
    final settings = ref.watch(readerSettingsProvider);
    final dyslexia = ref.watch(dyslexiaModeProvider);

    String fontFamily = settings.fontFamily;
    if (dyslexia) {
      fontFamily = 'OpenDyslexic';
    }

    TextStyle base;
    try {
      base = GoogleFonts.getFont(
        fontFamily,
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

  Future<void> _createHighlight({
    required String selectedText,
    required String chapterTitle,
    required int startOffset,
    required int endOffset,
  }) async {
    final trimmedText = selectedText.trim();
    if (trimmedText.isEmpty) return;

    final now = DateTime.now();
    final highlight = Highlight(
      id: now.microsecondsSinceEpoch.toString(),
      bookId: widget.book.id,
      chapterId: chapterTitle,
      selectedText: trimmedText,
      startOffset: startOffset,
      endOffset: endOffset,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await ref.read(annotationDaoProvider).insertHighlight(highlight);
      ref.invalidate(bookHighlightsProvider(widget.book.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Highlight saved'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Add note',
            onPressed: () => _promptHighlightNote(highlight),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not save highlight')));
    }
  }

  Future<void> _promptHighlightNote(Highlight highlight) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 5,
          minLines: 3,
          decoration: const InputDecoration(
            hintText: 'Your thoughts on this passage…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (note == null || note.trim().isEmpty) return;

    final updated = Highlight(
      id: highlight.id,
      bookId: highlight.bookId,
      chapterId: highlight.chapterId,
      selectedText: highlight.selectedText,
      colour: highlight.colour,
      note: note.trim(),
      startOffset: highlight.startOffset,
      endOffset: highlight.endOffset,
      cfiRange: highlight.cfiRange,
      createdAt: highlight.createdAt,
      updatedAt: DateTime.now(),
    );
    await ref.read(annotationDaoProvider).updateHighlight(updated);
    ref.invalidate(bookHighlightsProvider(widget.book.id));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(readerSettingsProvider);
    ref.listen<ReaderLocation?>(pendingReaderJumpProvider, (previous, next) {
      _handlePendingJump(next);
    });

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
        return _buildChapterView(chapter, theme, settings);
      },
    );
  }

  Widget _buildChapterView(
    _ChapterContent chapter,
    ThemeData theme,
    ReaderSettings settings,
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
        return Padding(
          padding: EdgeInsets.only(bottom: paragraphSpacing),
          child: SelectableText(
            paragraphs[index - 1],
            style: textStyle.copyWith(color: theme.colorScheme.onSurface),
            textAlign: textAlign,
            contextMenuBuilder: (context, editableTextState) {
              final value = editableTextState.textEditingValue;
              final selection = value.selection;
              final selectedText = selection.textInside(value.text);
              final buttonItems = <ContextMenuButtonItem>[
                if (selectedText.trim().isNotEmpty) ...[
                  ContextMenuButtonItem(
                    label: 'Look up',
                    onPressed: () {
                      editableTextState.hideToolbar();
                      showDictionarySheet(
                        context,
                        selection: selectedText,
                      );
                    },
                  ),
                  ContextMenuButtonItem(
                    label: 'Highlight',
                    onPressed: () {
                      editableTextState.hideToolbar();
                      _createHighlight(
                        selectedText: selectedText,
                        chapterTitle: chapter.title,
                        startOffset: selection.start,
                        endOffset: selection.end,
                      );
                    },
                  ),
                ],
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
}

class _ChapterContent {
  final String title;
  final String text;
  final String htmlContent;

  const _ChapterContent({
    required this.title,
    required this.text,
    required this.htmlContent,
  });
}
