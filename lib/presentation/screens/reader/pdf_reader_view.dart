import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/reader_location.dart';
import 'package:textara/presentation/providers/app_providers.dart';

class PdfReaderView extends ConsumerStatefulWidget {
  final Book book;
  final void Function(int page, int total, String chapterTitle) onPageChanged;

  const PdfReaderView({
    super.key,
    required this.book,
    required this.onPageChanged,
  });

  @override
  ConsumerState<PdfReaderView> createState() => _PdfReaderViewState();
}

class _PdfReaderViewState extends ConsumerState<PdfReaderView> {
  PdfViewerController? _controller;
  bool _isLoading = true;
  String? _error;
  int _totalPages = 0;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
    _validateFile();
  }

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  Future<void> _validateFile() async {
    final file = File(widget.book.filePath);
    if (!await file.exists()) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'PDF file not found. It may have been moved or deleted.';
      });
      return;
    }
    setState(() => _isLoading = false);
  }

  void _handlePendingJump(ReaderLocation? location) {
    final controller = _controller;
    if (location == null || controller == null || _totalPages <= 0) return;
    if (location.format != BookFormat.pdf) return;
    final target = location.pageIndex.clamp(1, _totalPages);
    controller.goToPage(pageNumber: target);
    widget.onPageChanged(target, _totalPages, 'Page $target');
    ref.read(pendingReaderJumpProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                'Unable to open PDF',
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

    return PdfViewer.file(
      widget.book.filePath,
      controller: _controller,
      params: PdfViewerParams(
        enableTextSelection: true,
        pageDropShadow: null,
        backgroundColor: theme.scaffoldBackgroundColor,
        onPageChanged: (pageNumber) {
          if (pageNumber != null) {
            widget.onPageChanged(
              pageNumber,
              _totalPages,
              'Page $pageNumber',
            );
          }
        },
        onViewerReady: (document, controller) {
          _totalPages = document.pages.length;
          final resume = ReaderLocation.fromBook(widget.book)
              .preservedAcrossTypographyChange();
          final page = resume.pageIndex > 0 && resume.pageIndex <= _totalPages
              ? resume.pageIndex
              : 1;
          if (page > 1) {
            controller.goToPage(pageNumber: page);
          }
          widget.onPageChanged(page, _totalPages, 'Page $page');
        },
      ),
    );
  }
}
