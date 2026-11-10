import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/data/services/brightness_service.dart';
import 'package:textara/data/services/reading_progress_persister.dart';
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
  bool _brightnessGestureActive = false;
  double? _brightnessHudValue;
  Timer? _brightnessHudTimer;
  ReadingProgressPersister? _progressPersister;
  BrightnessService? _brightnessService;
  bool _readerDepsReady = false;
  double _gestureStartBrightness = AppConstants.defaultReaderBrightness;
  double _gestureStartDy = 0;

  static const double _brightnessEdgeWidth = 28;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.book.currentPage;
    _totalPages = widget.book.totalPages > 0 ? widget.book.totalPages : 1;
    _progress = widget.book.readingProgress;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readerDepsReady) return;
    _readerDepsReady = true;
    _progressPersister = ReadingProgressPersister(ref.read(bookDaoProvider));
    _brightnessService = ref.read(brightnessServiceProvider);
    final brightness = ref.read(readerSettingsProvider).brightness;
    unawaited(_brightnessService!.apply(brightness));
  }

  @override
  void dispose() {
    _brightnessHudTimer?.cancel();
    // Best-effort flush so leaving the reader keeps the last page.
    final persister = _progressPersister;
    if (persister != null) {
      unawaited(persister.flush());
      persister.dispose();
    }
    unawaited(_brightnessService?.reset() ?? Future<void>.value());
    super.dispose();
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

    _progressPersister?.schedule(
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

  void _showBrightnessHud(double value) {
    setState(() => _brightnessHudValue = value);
    _brightnessHudTimer?.cancel();
    _brightnessHudTimer = Timer(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _brightnessHudValue = null);
    });
  }

  void _onBrightnessDragStart(DragStartDetails details) {
    _brightnessGestureActive = true;
    _gestureStartDy = details.globalPosition.dy;
    _gestureStartBrightness = ref.read(readerSettingsProvider).brightness;
    HapticFeedback.selectionClick();
  }

  void _onBrightnessDragUpdate(DragUpdateDetails details) {
    if (!_brightnessGestureActive) return;
    final height = MediaQuery.sizeOf(context).height;
    if (height <= 0) return;
    // Drag up = brighter (matches common reader muscle memory).
    final delta = (_gestureStartDy - details.globalPosition.dy) / height;
    final next = (_gestureStartBrightness + delta).clamp(
      AppConstants.minReaderBrightness,
      AppConstants.maxReaderBrightness,
    );
    ref.read(readerSettingsProvider.notifier).setBrightness(next);
    _showBrightnessHud(next);
  }

  void _onBrightnessDragEnd(DragEndDetails details) {
    _brightnessGestureActive = false;
  }

  @override
  Widget build(BuildContext context) {
    final brightnessHud = _brightnessHudValue;

    return Scaffold(
      body: Stack(
        children: [
          // Reader content — tap toggles chrome (ignored while brightness-dragging).
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _brightnessGestureActive ? null : _toggleControls,
            child: widget.book.isEpub
                ? EpubReaderView(
                    book: widget.book,
                    onPageChanged: _onPageChanged,
                  )
                : PdfReaderView(
                    book: widget.book,
                    onPageChanged: _onPageChanged,
                  ),
          ),

          // Right-edge brightness gesture strip (does not block vertical scroll
          // elsewhere on the page).
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            width: _brightnessEdgeWidth,
            child: Semantics(
              label: 'Brightness gesture area. Drag vertically to adjust.',
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragStart: _onBrightnessDragStart,
                onVerticalDragUpdate: _onBrightnessDragUpdate,
                onVerticalDragEnd: _onBrightnessDragEnd,
                onVerticalDragCancel: () => _brightnessGestureActive = false,
              ),
            ),
          ),

          if (brightnessHud != null)
            Center(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: 1,
                  duration: AppConstants.animationFast,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.brightness_6_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '${(brightnessHud * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Top bar
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ReaderAppBar(
                title: widget.book.title,
                onBack: () async {
                  await _progressPersister?.flush();
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
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
    );
  }
}
