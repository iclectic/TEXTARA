import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/presentation/providers/app_providers.dart';
import 'package:textara/presentation/screens/reader/epub_reader_view.dart';
import 'package:textara/presentation/screens/reader/pdf_reader_view.dart';
import 'package:textara/presentation/widgets/reader/reader_app_bar.dart';
import 'package:textara/presentation/widgets/reader/reader_bottom_bar.dart';
import 'package:textara/presentation/widgets/reader/reader_settings_sheet.dart';
import 'package:textara/presentation/widgets/reader/annotations_sheet.dart';
import 'package:textara/presentation/widgets/reader/toc_sheet.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  final Book book;

  const ReaderScreen({super.key, required this.book});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  bool _showControls = true;
  int _currentPage = 0;
  int _totalPages = 1;
  String _currentChapterTitle = '';
  double _progress = 0.0;
  late final ReadingProgressWriter _progressWriter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentPage = widget.book.currentPage;
    _totalPages = widget.book.totalPages > 0 ? widget.book.totalPages : 1;
    _progress = widget.book.readingProgress;
    _progressWriter = ReadingProgressWriter(
      ref.read(libraryRepositoryProvider),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Fire-and-forget final flush; [dispose] cannot be async.
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

  void _onPageChanged(int page, int total, String chapterTitle) {
    setState(() {
      _currentPage = page;
      _totalPages = total > 0 ? total : 1;
      _currentChapterTitle = chapterTitle;
      _progress = total > 0 ? page / total : 0.0;
    });

    _progressWriter.schedule(
      bookId: widget.book.id,
      progress: _progress,
      page: page,
      chapterId: chapterTitle,
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
          },
        ),
      ),
    );
  }

  Future<void> _addBookmark() async {
    if (!ref.read(lowStimulationProvider)) {
      unawaited(HapticFeedback.mediumImpact());
    }
    final dao = ref.read(annotationDaoProvider);
    final bookmark = Bookmark(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: widget.book.id,
      pageNumber: _currentPage,
      chapterId: _currentChapterTitle,
      title: '$_currentChapterTitle - Page $_currentPage',
      createdAt: DateTime.now(),
    );
    await dao.insertBookmark(bookmark);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark added'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  int _estimateMinutesLeft() {
    if (_progress <= 0 || _progress >= 1.0) return 0;
    final pagesLeft = _totalPages - _currentPage;
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
                      onPageChanged: _onPageChanged,
                    )
                  : PdfReaderView(
                      book: widget.book,
                      onPageChanged: _onPageChanged,
                    ),
              if (_showControls)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
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
              if (_showControls)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ReaderBottomBar(
                    currentPage: _currentPage,
                    totalPages: _totalPages,
                    chapterTitle: _currentChapterTitle,
                    progress: _progress,
                    minutesLeft: _estimateMinutesLeft(),
                    onToc: _showTableOfContents,
                    onAnnotations: _showAnnotations,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
