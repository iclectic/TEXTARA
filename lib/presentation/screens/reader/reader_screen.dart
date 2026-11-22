import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/core/theme/leaf_tokens.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/reader_location.dart';
import 'package:textara/presentation/providers/app_providers.dart';
import 'package:textara/presentation/screens/reader/epub_reader_controller.dart';
import 'package:textara/presentation/screens/reader/epub_reader_view.dart';
import 'package:textara/presentation/screens/reader/pdf_reader_view.dart';
import 'package:textara/presentation/widgets/reader/annotations_sheet.dart';
import 'package:textara/presentation/widgets/reader/reader_app_bar.dart';
import 'package:textara/presentation/widgets/reader/reader_bottom_bar.dart';
import 'package:textara/presentation/widgets/reader/reader_settings_sheet.dart';
import 'package:textara/presentation/widgets/reader/toc_sheet.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final Book book;
  final String? initialChapterId;

  const ReaderScreen({super.key, required this.book, this.initialChapterId});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  bool _showControls = true;
  late ReaderLocation _location;
  late final ReadingProgressWriter _progressWriter;
  final EpubReaderController _epubController = EpubReaderController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _location = ReaderLocation(
      pageIndex: widget.book.currentPage,
      totalPages: widget.book.totalPages > 0 ? widget.book.totalPages : 1,
      chapterId: widget.book.currentChapterId,
      chapterTitle: widget.book.currentChapterId,
      isEpub: widget.book.isEpub,
    );
    _progressWriter = ReadingProgressWriter(
      ref.read(libraryRepositoryProvider),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_progressWriter.flush());
    _progressWriter.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      unawaited(_progressWriter.flush());
    }
  }

  void _toggleControls() {
    if (!ref.read(lowStimulationProvider)) {
      unawaited(HapticFeedback.lightImpact());
    }
    setState(() => _showControls = !_showControls);
  }

  void _onPageChanged(
    int page,
    int total,
    String chapterTitle, [
    String? chapterId,
  ]) {
    setState(() {
      _location = ReaderLocation(
        pageIndex: page,
        totalPages: total > 0 ? total : 1,
        chapterId: chapterId ?? chapterTitle,
        chapterTitle: chapterTitle,
        isEpub: widget.book.isEpub,
      );
    });

    _progressWriter.schedule(
      bookId: widget.book.id,
      progress: _location.progress,
      page: page,
      chapterId: chapterId ?? chapterTitle,
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (_, controller) =>
            ReaderSettingsSheet(scrollController: controller),
      ),
    );
  }

  void _showAnnotations() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (_, controller) => AnnotationsSheet(
          bookId: widget.book.id,
          bookTitle: widget.book.title,
          scrollController: controller,
          onJumpToBookmark: (bookmark) {
            Navigator.pop(context);
            _epubController.jumpToChapter(bookmark.pageNumber);
          },
        ),
      ),
    );
  }

  void _showTableOfContents() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (_, controller) => TocSheet(
          book: widget.book,
          scrollController: controller,
          onChapterSelected: (chapterId) {
            Navigator.pop(context);
            // Prefer order index encoded in TOC; fall back to id match via index 0 jump then id.
            final orderMatch = int.tryParse(
              chapterId.replaceFirst('chapter_', ''),
            );
            if (orderMatch != null && chapterId.startsWith('chapter_')) {
              _epubController.jumpToChapter(orderMatch);
            } else {
              // Jump by scanning: controller only takes index; encode via cached order.
              // TocSheet ids are contentFileName — resolve by reloading cache index.
              unawaited(_jumpByChapterId(chapterId));
            }
          },
        ),
      ),
    );
  }

  Future<void> _jumpByChapterId(String chapterId) async {
    final chapters = await ref
        .read(epubChapterCacheProvider)
        .chaptersFor(widget.book.filePath);
    final idx = chapters.indexWhere((c) => c.id == chapterId);
    if (idx >= 0) {
      _epubController.jumpToChapter(idx);
    }
  }

  Future<void> _addBookmark() async {
    if (!ref.read(lowStimulationProvider)) {
      unawaited(HapticFeedback.mediumImpact());
    }
    final dao = ref.read(annotationDaoProvider);
    final bookmark = Bookmark(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: widget.book.id,
      pageNumber: _location.pageIndex,
      chapterId: _location.chapterId,
      title:
          '${_location.chapterTitle ?? 'Chapter'} — ${_location.positionLabel}',
      createdAt: DateTime.now(),
    );
    await dao.insertBookmark(bookmark);
    ref.invalidate(bookBookmarksProvider(widget.book.id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark added'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  int _estimateMinutesLeft() {
    if (_location.progress <= 0 || _location.progress >= 1.0) return 0;
    final pagesLeft = _location.totalPages - _location.pageIndex;
    return (pagesLeft * 1.2).round();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          await _progressWriter.flush();
        }
      },
      child: Scaffold(
        body: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            children: [
              widget.book.isEpub
                  ? EpubReaderView(
                      book: widget.book,
                      controller: _epubController,
                      initialChapterId: widget.initialChapterId,
                      onPageChanged: _onPageChanged,
                    )
                  : PdfReaderView(
                      book: widget.book,
                      onPageChanged: (page, total, title) =>
                          _onPageChanged(page, total, title),
                    ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _ChromeFade(
                  visible: _showControls,
                  child: ReaderAppBar(
                    title: widget.book.title,
                    onBack: () async {
                      await _progressWriter.flush();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    onBookmark: _addBookmark,
                    onSettings: _showSettings,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _ChromeFade(
                  visible: _showControls,
                  child: ReaderBottomBar(
                    positionLabel: _location.positionLabel,
                    chapterTitle: _location.chapterTitle ?? '',
                    progress: _location.progress,
                    minutesLeft: _estimateMinutesLeft(),
                    onToc: _showTableOfContents,
                    onAnnotations: _showAnnotations,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChromeFade extends ConsumerWidget {
  final bool visible;
  final Widget child;

  const _ChromeFade({required this.visible, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduced = ref.watch(reducedMotionProvider);
    final duration = LeafTokens.motion(
      context,
      preferred: LeafTokens.motionFast,
      forceReduce: reduced,
    );
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: duration,
        curve: LeafTokens.curve(reduced),
        child: child,
      ),
    );
  }
}
