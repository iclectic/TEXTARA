import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/domain/entities/ink_stroke.dart';
import 'package:textara/domain/entities/reader_location.dart';
import 'package:textara/presentation/providers/app_providers.dart';
import 'package:textara/presentation/screens/reader/epub_reader_view.dart';
import 'package:textara/presentation/screens/reader/pdf_reader_view.dart';
import 'package:textara/presentation/screens/reader/text_reader_view.dart';
import 'package:textara/presentation/view_models/reader_session_controller.dart';
import 'package:textara/presentation/widgets/reader/ink_canvas.dart';
import 'package:textara/presentation/widgets/reader/ink_toolbar.dart';
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
  ReaderSessionController? _session;
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
    _session = ReaderSessionController(
      book: widget.book,
      books: ref.read(bookRepositoryProvider),
      brightness: ref.read(brightnessServiceProvider),
    );
    final brightness = ref.read(readerSettingsProvider).brightness;
    unawaited(_session!.applyBrightness(brightness));
    unawaited(_session!.markOpened());
  }

  @override
  void dispose() {
    _brightnessHudTimer?.cancel();
    final session = _session;
    if (session != null) {
      unawaited(session.dispose());
    }
    // Ensure next reader open starts with scroll-friendly ink-off.
    try {
      ref.read(inkToolProvider.notifier).state = InkTool.off;
    } catch (_) {
      // Provider may already be disposed during teardown.
    }
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

    _session?.scheduleProgress(
      page: page,
      totalPages: total,
      chapterTitle: chapterTitle,
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

  ReaderLocation _currentLocation() {
    final session = _session;
    if (session != null) {
      return session.currentLocation(
        pageIndex: _currentPage,
        progress: _progress,
        chapterTitle: _currentChapterTitle,
      );
    }
    return ReaderLocation(
      format: widget.book.format,
      pageIndex: _currentPage,
      chapterId: _currentChapterTitle.isEmpty ? null : _currentChapterTitle,
      progress: _progress,
    ).preservedAcrossTypographyChange();
  }

  void _jumpToBookmark(Bookmark bookmark) {
    final location = ReaderLocation.fromBookmark(
      bookmark,
      format: widget.book.format,
    );
    ref.read(pendingReaderJumpProvider.notifier).state = location;
    setState(() {
      _currentPage = location.pageIndex;
      _currentChapterTitle = location.chapterId ?? _currentChapterTitle;
      _progress = location.progress > 0
          ? location.progress
          : (_totalPages > 0 ? location.pageIndex / _totalPages : 0.0);
      _showControls = true;
    });
  }

  void _showAnnotations() {
    final resumeLabel = _currentLocation().displayLabel;
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
          autoResumeLabel: resumeLabel,
          onBookmarkJump: (bookmark) {
            Navigator.of(context).pop();
            _jumpToBookmark(bookmark);
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
            // Chapter navigation handled by child view
          },
        ),
      ),
    );
  }

  Future<void> _addBookmark() async {
    HapticFeedback.mediumImpact();
    final location = _currentLocation();
    final bookmark = Bookmark(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookId: widget.book.id,
      pageNumber: location.pageIndex,
      chapterId: location.chapterId,
      cfiLocation: location.toStableToken(),
      title: location.displayLabel,
      createdAt: DateTime.now(),
    );
    await ref.read(annotationDaoProvider).insertBookmark(bookmark);
    ref.invalidate(bookBookmarksProvider(widget.book.id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmark saved (separate from auto-resume)'),
        duration: Duration(seconds: 2),
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

  Widget _buildReaderContent() {
    if (widget.book.isPdf) {
      return PdfReaderView(book: widget.book, onPageChanged: _onPageChanged);
    }
    if (widget.book.isEpub) {
      return EpubReaderView(book: widget.book, onPageChanged: _onPageChanged);
    }
    // TXT / FB2 / DRM-free MOBI share the chapter text reader.
    return TextReaderView(book: widget.book, onPageChanged: _onPageChanged);
  }

  Future<void> _confirmClearInk(InkStrokesNotifier notifier) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear ink on this page?'),
        content: const Text(
          'This removes scribble strokes for the current page or chapter only.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await notifier.clearPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightnessHud = _brightnessHudValue;
    final inkTool = ref.watch(inkToolProvider);
    final location = _currentLocation();
    final inkArgs = InkLocationArgs(
      bookId: widget.book.id,
      locationKey: location.inkLocationKey,
    );
    final inkAsync = ref.watch(inkStrokesProvider(inkArgs));
    final inkNotifier = ref.read(inkStrokesProvider(inkArgs).notifier);
    final strokes = inkAsync.valueOrNull ?? const <InkStroke>[];
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        children: [
          // Reader content — tap toggles chrome (ignored while brightness-dragging
          // or when ink tools are capturing pointers).
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: (_brightnessGestureActive || inkTool != InkTool.off)
                ? null
                : _toggleControls,
            child: _buildReaderContent(),
          ),

          // Ink overlay — when tool is off, IgnorePointer lets scroll through.
          Positioned.fill(
            child: InkCanvas(
              bookId: widget.book.id,
              locationKey: location.inkLocationKey,
              tool: inkTool,
              strokes: strokes,
              penColor: theme.colorScheme.onSurface,
              onStrokeCommitted: inkNotifier.addStroke,
              onStrokesErased: inkNotifier.eraseStrokes,
            ),
          ),

          // Right-edge brightness gesture strip (does not block vertical scroll
          // elsewhere on the page). Hidden while ink tools are active.
          if (inkTool == InkTool.off)
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
                  await _session?.flushProgress();
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
                onBookmark: _addBookmark,
                onSettings: _showSettings,
              ),
            ),

          // Ink tool chrome — visible with controls so users can arm pen/eraser.
          if (_showControls)
            Positioned(
              top: topInset + 56,
              left: 0,
              right: 0,
              child: Center(
                child: InkToolbar(
                  tool: inkTool,
                  onToolChanged: (tool) {
                    ref.read(inkToolProvider.notifier).state = tool;
                  },
                  onClearPage: strokes.isEmpty
                      ? null
                      : () => _confirmClearInk(inkNotifier),
                ),
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
