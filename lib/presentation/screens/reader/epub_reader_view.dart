import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/reader_settings.dart';
import 'package:textara/presentation/providers/app_providers.dart';

class EpubReaderView extends ConsumerStatefulWidget {
  final Book book;
  final String? requestedChapterId;
  final void Function(
    int page,
    int total,
    String chapterTitle, {
    String? chapterId,
  })
  onPageChanged;

  const EpubReaderView({
    super.key,
    required this.book,
    this.requestedChapterId,
    required this.onPageChanged,
  });

  @override
  ConsumerState<EpubReaderView> createState() => _EpubReaderViewState();
}

class _EpubReaderViewState extends ConsumerState<EpubReaderView> {
  final PageController _pageController = PageController();
  List<_ChapterContent> _chapters = [];
  List<_ReaderPage> _pages = [];
  bool _isLoading = true;
  String? _error;
  int _currentPageIndex = 0;
  String? _lastHandledRequestedChapterId;
  String? _paginationKey;

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

  @override
  void didUpdateWidget(covariant EpubReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requestedChapterId != null &&
        widget.requestedChapterId != _lastHandledRequestedChapterId) {
      _jumpToChapter(widget.requestedChapterId!);
    }
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
            id: chapter.contentFileName ?? 'chapter_$i',
            title: chapter.title ?? 'Chapter ${i + 1}',
            text: text.trim(),
            htmlContent: html,
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _chapters = loaded;
        _pages = [];
        _paginationKey = null;
        _isLoading = false;
      });

      // Restore position
      if (widget.book.currentPage > 0) {
        _currentPageIndex = widget.book.currentPage - 1;
      }

      if (widget.requestedChapterId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _jumpToChapter(widget.requestedChapterId!);
        });
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
    if (_pages.isEmpty) return;
    final safeIndex = _currentPageIndex.clamp(0, _pages.length - 1).toInt();
    final page = _pages[safeIndex];
    widget.onPageChanged(
      safeIndex + 1,
      _pages.length,
      page.chapterTitle,
      chapterId: page.chapterId,
    );
  }

  void _jumpToChapter(String chapterId) {
    if (_pages.isEmpty) return;
    final index = _pages.indexWhere((page) => page.chapterId == chapterId);
    if (index < 0) return;
    _lastHandledRequestedChapterId = chapterId;
    setState(() => _currentPageIndex = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    }
    _reportProgress();
  }

  TextStyle _getReaderTextStyle() {
    final settings = ref.watch(readerSettingsProvider);
    final dyslexia = ref.watch(dyslexiaModeProvider);

    String fontFamily = settings.fontFamily;
    if (dyslexia) {
      fontFamily = 'OpenDyslexic';
    }

    return TextStyle(
      fontFamily: fontFamily,
      fontSize: settings.fontSize,
      height: settings.lineHeight,
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(readerSettingsProvider);
    final dyslexia = ref.watch(dyslexiaModeProvider);

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

    return LayoutBuilder(
      builder: (context, constraints) {
        final spec = _buildPaginationSpec(
          context,
          constraints,
          settings,
          dyslexia: dyslexia,
        );
        final paginationKey = spec.key;

        if (paginationKey != _paginationKey) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || paginationKey == _paginationKey) return;
            _rebuildPagination(spec);
          });
        }

        if (_pages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return PageView.builder(
          controller: _pageController,
          itemCount: _pages.length,
          onPageChanged: (index) {
            setState(() => _currentPageIndex = index);
            _reportProgress();
          },
          itemBuilder: (context, index) {
            final page = _pages[index];
            return _buildPageView(page, theme, settings);
          },
        );
      },
    );
  }

  _PaginationSpec _buildPaginationSpec(
    BuildContext context,
    BoxConstraints constraints,
    ReaderSettings settings, {
    required bool dyslexia,
  }) {
    final mediaQuery = MediaQuery.of(context);
    final textStyle = _resolveReaderTextStyle(settings, dyslexia: dyslexia);
    final textScaler = mediaQuery.textScaler;
    final pageWidth = (constraints.maxWidth - (settings.horizontalMargin * 2))
        .clamp(240.0, 1200.0);
    final pageHeight =
        (constraints.maxHeight -
                mediaQuery.padding.top -
                mediaQuery.padding.bottom -
                152)
            .clamp(240.0, 1800.0);

    return _PaginationSpec(
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      textStyle: textStyle,
      titleStyle:
          Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700) ??
          textStyle.copyWith(fontSize: textStyle.fontSize! * 1.45),
      textAlign: _textAlignFor(settings.textAlignment),
      textDirection: Directionality.of(context),
      textScaler: textScaler,
      key: _buildPaginationKey(
        settings,
        dyslexia: dyslexia,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        textScale: textScaler.scale(1),
      ),
    );
  }

  void _rebuildPagination(_PaginationSpec spec) {
    if (_chapters.isEmpty) return;

    final currentChapterId = _pages.isNotEmpty
        ? _pages[_currentPageIndex.clamp(0, _pages.length - 1).toInt()]
              .chapterId
        : null;
    final nextPages = _paginateChapters(_chapters, spec);
    var nextIndex = currentChapterId == null
        ? 0
        : nextPages.indexWhere((page) => page.chapterId == currentChapterId);
    final requestedChapterId = widget.requestedChapterId;
    if (requestedChapterId != null &&
        requestedChapterId != _lastHandledRequestedChapterId) {
      final requestedIndex = nextPages.indexWhere(
        (page) => page.chapterId == requestedChapterId,
      );
      if (requestedIndex >= 0) {
        nextIndex = requestedIndex;
        _lastHandledRequestedChapterId = requestedChapterId;
      }
    }

    setState(() {
      _pages = nextPages;
      _paginationKey = spec.key;
      _currentPageIndex = nextIndex < 0
          ? _currentPageIndex.clamp(0, nextPages.length - 1).toInt()
          : nextIndex;
    });

    if (_pageController.hasClients && _pages.isNotEmpty) {
      _pageController.jumpToPage(_currentPageIndex);
    }
    _reportProgress();
  }

  List<_ReaderPage> _paginateChapters(
    List<_ChapterContent> chapters,
    _PaginationSpec spec,
  ) {
    final pages = <_ReaderPage>[];

    for (final chapter in chapters) {
      final pageTexts = _splitChapterIntoPages(chapter, spec);
      for (var index = 0; index < pageTexts.length; index++) {
        pages.add(
          _ReaderPage(
            chapterId: chapter.id,
            chapterTitle: chapter.title,
            text: pageTexts[index],
            chapterPageNumber: index + 1,
            chapterPageCount: pageTexts.length,
          ),
        );
      }
    }

    return pages;
  }

  List<String> _splitChapterIntoPages(
    _ChapterContent chapter,
    _PaginationSpec spec,
  ) {
    final pages = <String>[];
    var remaining = chapter.readingText.trim();
    var isFirstPage = true;

    while (remaining.isNotEmpty) {
      final availableHeight = isFirstPage
          ? (spec.pageHeight - _measureTitleHeight(chapter.title, spec) - 24)
                .clamp(160.0, spec.pageHeight)
          : spec.pageHeight;
      final splitOffset = _textOffsetForPage(remaining, spec, availableHeight);
      final pageText = remaining.substring(0, splitOffset).trim();
      if (pageText.isNotEmpty) pages.add(pageText);

      remaining = remaining.substring(splitOffset).trimLeft();
      isFirstPage = false;
    }

    return pages.isEmpty ? const [''] : pages;
  }

  double _measureTitleHeight(String title, _PaginationSpec spec) {
    final painter = TextPainter(
      text: TextSpan(text: title, style: spec.titleStyle),
      textAlign: spec.textAlign,
      textDirection: spec.textDirection,
      textScaler: spec.textScaler,
      maxLines: 3,
    )..layout(maxWidth: spec.pageWidth);
    return painter.height;
  }

  int _textOffsetForPage(
    String text,
    _PaginationSpec spec,
    double availableHeight,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: spec.textStyle),
      textAlign: spec.textAlign,
      textDirection: spec.textDirection,
      textScaler: spec.textScaler,
    )..layout(maxWidth: spec.pageWidth);

    if (painter.height <= availableHeight) return text.length;

    var offset = painter
        .getPositionForOffset(Offset(spec.pageWidth, availableHeight))
        .offset;
    offset = offset.clamp(1, text.length).toInt();

    final previousParagraph = text.lastIndexOf('\n\n', offset);
    if (previousParagraph > 180) return previousParagraph + 2;

    final previousWhitespace = text.lastIndexOf(RegExp(r'\s'), offset);
    if (previousWhitespace > 80) return previousWhitespace + 1;

    final fallback = (offset * 0.8).round();
    if (fallback > 1) return fallback;
    return offset;
  }

  TextStyle _resolveReaderTextStyle(
    ReaderSettings settings, {
    required bool dyslexia,
  }) {
    String fontFamily = settings.fontFamily;
    if (dyslexia) {
      fontFamily = 'OpenDyslexic';
    }

    return TextStyle(
      fontFamily: fontFamily,
      fontSize: settings.fontSize,
      height: settings.lineHeight,
    );
  }

  TextAlign _textAlignFor(TextAlignment alignment) {
    switch (alignment) {
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

  String _buildPaginationKey(
    ReaderSettings settings, {
    required bool dyslexia,
    required double pageWidth,
    required double pageHeight,
    required double textScale,
  }) {
    return [
      settings.fontSize,
      settings.lineHeight,
      settings.horizontalMargin,
      settings.paragraphSpacing,
      settings.fontFamily,
      settings.textAlignment.name,
      dyslexia,
      pageWidth.round(),
      pageHeight.round(),
      textScale.toStringAsFixed(2),
    ].join('|');
  }

  Widget _buildPageView(
    _ReaderPage page,
    ThemeData theme,
    ReaderSettings settings,
  ) {
    final textStyle = _getReaderTextStyle();
    final textAlign = _getTextAlign();
    final margin = settings.horizontalMargin;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        margin,
        MediaQuery.of(context).padding.top + 64,
        margin,
        MediaQuery.of(context).padding.bottom + 80,
      ),
      children: [
        if (page.isFirstPageInChapter)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              page.chapterTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        SelectableText(
          page.text,
          style: textStyle.copyWith(color: theme.colorScheme.onSurface),
          textAlign: textAlign,
          contextMenuBuilder: (context, editableTextState) {
            return _buildSelectionToolbar(context, editableTextState, page);
          },
        ),
        Padding(
          padding: EdgeInsets.only(top: settings.paragraphSpacing * 2),
          child: SelectableText(
            '${page.chapterTitle} · ${page.chapterPageNumber} of ${page.chapterPageCount}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionToolbar(
    BuildContext context,
    EditableTextState editableTextState,
    _ReaderPage page,
  ) {
    final buttonItems = <ContextMenuButtonItem>[
      ...editableTextState.contextMenuButtonItems,
      ContextMenuButtonItem(
        label: 'Highlight',
        onPressed: () {
          _saveHighlightFromSelection(editableTextState, page);
          editableTextState.hideToolbar();
        },
      ),
    ];

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: editableTextState.contextMenuAnchors,
      buttonItems: buttonItems,
    );
  }

  Future<void> _saveHighlightFromSelection(
    EditableTextState editableTextState,
    _ReaderPage page,
  ) async {
    final selection = editableTextState.textEditingValue.selection;
    if (!selection.isValid || selection.isCollapsed) return;

    final selectedText = selection.textInside(page.text).trim();
    if (selectedText.isEmpty) return;

    final now = DateTime.now();
    final highlight = Highlight(
      id: now.microsecondsSinceEpoch.toString(),
      bookId: widget.book.id,
      chapterId: page.chapterId,
      selectedText: selectedText,
      startOffset: selection.start,
      endOffset: selection.end,
      createdAt: now,
      updatedAt: now,
    );

    await ref.read(annotationDaoProvider).insertHighlight(highlight);
    ref.invalidate(bookHighlightsProvider(widget.book.id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Highlight saved'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

class _ChapterContent {
  final String id;
  final String title;
  final String text;
  final String htmlContent;
  final List<String> paragraphs;
  final String readingText;

  _ChapterContent({
    required this.id,
    required this.title,
    required this.text,
    required this.htmlContent,
  }) : paragraphs = text
           .split('\n')
           .where((paragraph) => paragraph.trim().isNotEmpty)
           .toList(),
       readingText = text
           .split('\n')
           .where((paragraph) => paragraph.trim().isNotEmpty)
           .join('\n\n');
}

class _ReaderPage {
  final String chapterId;
  final String chapterTitle;
  final String text;
  final int chapterPageNumber;
  final int chapterPageCount;

  const _ReaderPage({
    required this.chapterId,
    required this.chapterTitle,
    required this.text,
    required this.chapterPageNumber,
    required this.chapterPageCount,
  });

  bool get isFirstPageInChapter => chapterPageNumber == 1;
}

class _PaginationSpec {
  final double pageWidth;
  final double pageHeight;
  final TextStyle textStyle;
  final TextStyle titleStyle;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final String key;

  const _PaginationSpec({
    required this.pageWidth,
    required this.pageHeight,
    required this.textStyle,
    required this.titleStyle,
    required this.textAlign,
    required this.textDirection,
    required this.textScaler,
    required this.key,
  });
}
