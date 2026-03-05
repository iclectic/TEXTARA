import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/epub_content.dart';
import 'package:textara/presentation/providers/app_providers.dart';

class TocSheet extends ConsumerStatefulWidget {
  final Book book;
  final ScrollController scrollController;
  final void Function(String chapterId) onChapterSelected;

  const TocSheet({
    super.key,
    required this.book,
    required this.scrollController,
    required this.onChapterSelected,
  });

  @override
  ConsumerState<TocSheet> createState() => _TocSheetState();
}

class _TocSheetState extends ConsumerState<TocSheet> {
  EpubTableOfContents? _toc;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadToc();
  }

  Future<void> _loadToc() async {
    if (!widget.book.isEpub) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final parser = ref.read(epubParserProvider);
      final epubBook = await parser.parseEpub(widget.book.filePath);
      final toc = parser.extractTableOfContents(epubBook);
      if (!mounted) return;
      setState(() {
        _toc = toc;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Table of Contents',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (!widget.book.isEpub) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.picture_as_pdf_rounded,
                size: 40,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 12),
              Text(
                'PDF navigation',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Use the page slider to navigate through this PDF.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_toc == null || _toc!.chapters.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No table of contents available for this book.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _toc!.chapters.length,
      itemBuilder: (context, index) {
        final chapter = _toc!.chapters[index];
        return _buildChapterTile(chapter, theme, 0);
      },
    );
  }

  Widget _buildChapterTile(TocChapter chapter, ThemeData theme, int depth) {
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.only(left: 24.0 + (depth * 20.0), right: 24),
          title: Text(
            chapter.title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: depth == 0 ? FontWeight.w500 : FontWeight.w400,
              color: depth == 0
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onChapterSelected(chapter.id);
          },
        ),
        ...chapter.subChapters
            .map((sub) => _buildChapterTile(sub, theme, depth + 1)),
      ],
    );
  }
}
