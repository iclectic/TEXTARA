import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/parsed_text_book.dart';
import 'package:textara/domain/entities/reader_location.dart';
import 'package:textara/domain/entities/reader_settings.dart';
import 'package:textara/presentation/providers/app_providers.dart';
import 'package:textara/presentation/widgets/reader/dictionary_sheet.dart';

/// Shared chapter reader for TXT / FB2 / unprotected MOBI.
class TextReaderView extends ConsumerStatefulWidget {
  final Book book;
  final void Function(int page, int total, String chapterTitle) onPageChanged;

  const TextReaderView({
    super.key,
    required this.book,
    required this.onPageChanged,
  });

  @override
  ConsumerState<TextReaderView> createState() => _TextReaderViewState();
}

class _TextReaderViewState extends ConsumerState<TextReaderView> {
  final PageController _pageController = PageController();
  List<TextChapter> _chapters = [];
  bool _isLoading = true;
  String? _error;
  int _currentChapterIndex = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      late final ParsedTextBook parsed;
      switch (widget.book.format) {
        case BookFormat.txt:
          parsed = await ref.read(txtParserProvider).parseFile(
                widget.book.filePath,
                fallbackTitle: widget.book.title,
              );
        case BookFormat.fb2:
          parsed = await ref.read(fb2ParserProvider).parseFile(
                widget.book.filePath,
                fallbackTitle: widget.book.title,
              );
        case BookFormat.mobi:
          parsed = await ref.read(mobiImportProvider).convertFile(
                widget.book.filePath,
                fallbackTitle: widget.book.title,
              );
        default:
          throw StateError('TextReaderView cannot open ${widget.book.format}');
      }

      if (!mounted) return;
      setState(() {
        _chapters = parsed.chapters;
        _isLoading = false;
      });

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
            'Could not open this ${widget.book.formatBadgeLabel} file. It may be damaged or unsupported.';
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
    if (location.format != widget.book.format) return;
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

    try {
      return GoogleFonts.getFont(
        fontFamily,
        fontSize: settings.fontSize,
        height: settings.lineHeight,
      );
    } catch (_) {
      return TextStyle(
        fontSize: settings.fontSize,
        height: settings.lineHeight,
      );
    }
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
        const SnackBar(
          content: Text('Highlight saved'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save highlight')),
      );
    }
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
          child: Text(
            _error!,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
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
        return _buildChapterView(_chapters[index], theme, settings);
      },
    );
  }

  Widget _buildChapterView(
    TextChapter chapter,
    ThemeData theme,
    ReaderSettings settings,
  ) {
    final textStyle = _getReaderTextStyle();
    final textAlign = _getTextAlign();
    final margin = settings.horizontalMargin;
    final paragraphSpacing = settings.paragraphSpacing;

    final paragraphs = chapter.text
        .split('\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
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
                      showDictionarySheet(context, selection: selectedText);
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
