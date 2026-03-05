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

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  bool _showControls = true;
  int _currentPage = 0;
  int _totalPages = 1;
  String _currentChapterTitle = '';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.book.currentPage;
    _totalPages = widget.book.totalPages > 0 ? widget.book.totalPages : 1;
    _progress = widget.book.readingProgress;
  }

  void _toggleControls() {
    HapticFeedback.lightImpact();
    setState(() => _showControls = !_showControls);
  }

  void _onPageChanged(int page, int total, String chapterTitle) {
    setState(() {
      _currentPage = page;
      _totalPages = total > 0 ? total : 1;
      _currentChapterTitle = chapterTitle;
      _progress = total > 0 ? page / total : 0.0;
    });

    ref.read(bookDaoProvider).updateReadingProgress(
          widget.book.id,
          _progress,
          page,
          chapterTitle,
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
        builder: (_, controller) => ReaderSettingsSheet(
          scrollController: controller,
        ),
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
            // Chapter navigation handled by child view
          },
        ),
      ),
    );
  }

  void _addBookmark() {
    HapticFeedback.mediumImpact();
    final dao = ref.read(annotationDaoProvider);
    final bookmark = Bookmark(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: widget.book.id,
      pageNumber: _currentPage,
      chapterId: _currentChapterTitle,
      title: '$_currentChapterTitle - Page $_currentPage',
      createdAt: DateTime.now(),
    );
    dao.insertBookmark(bookmark);
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
    return (pagesLeft * 1.2).round(); // ~1.2 min per page estimate
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Reader content
            widget.book.isEpub
                ? EpubReaderView(
                    book: widget.book,
                    onPageChanged: _onPageChanged,
                  )
                : PdfReaderView(
                    book: widget.book,
                    onPageChanged: _onPageChanged,
                  ),

            // Top bar
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: ReaderAppBar(
                  title: widget.book.title,
                  onBack: () => Navigator.of(context).pop(),
                  onBookmark: _addBookmark,
                  onSettings: _showSettings,
                ),
              ),

            // Bottom bar
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
    );
  }
}
