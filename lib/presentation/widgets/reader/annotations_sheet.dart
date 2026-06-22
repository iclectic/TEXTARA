import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/annotation.dart';
import 'package:textara/presentation/providers/app_providers.dart';

class AnnotationsSheet extends ConsumerStatefulWidget {
  final String bookId;
  final String bookTitle;
  final ScrollController scrollController;

  const AnnotationsSheet({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.scrollController,
  });

  @override
  ConsumerState<AnnotationsSheet> createState() => _AnnotationsSheetState();
}

class _AnnotationsSheetState extends ConsumerState<AnnotationsSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _highlightColourValue(HighlightColour colour) {
    switch (colour) {
      case HighlightColour.yellow:
        return const Color(0xFFFFF176);
      case HighlightColour.green:
        return const Color(0xFFA5D6A7);
      case HighlightColour.blue:
        return const Color(0xFF90CAF9);
      case HighlightColour.pink:
        return const Color(0xFFF48FB1);
      case HighlightColour.orange:
        return const Color(0xFFFFCC80);
      case HighlightColour.purple:
        return const Color(0xFFCE93D8);
      case HighlightColour.red:
        return const Color(0xFFEF9A9A);
      case HighlightColour.teal:
        return const Color(0xFF80CBC4);
    }
  }

  Future<void> _exportToMarkdown() async {
    HapticFeedback.mediumImpact();
    final exportService = ref.read(exportServiceProvider);
    try {
      final path = await exportService.exportHighlightsToMarkdown(
        widget.bookId,
        widget.bookTitle,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exported to: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export failed. Please try again.')),
      );
    }
  }

  Future<void> _exportToPdf() async {
    HapticFeedback.mediumImpact();
    final exportService = ref.read(exportServiceProvider);
    try {
      final path = await exportService.exportHighlightsToPdf(
        widget.bookId,
        widget.bookTitle,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Exported to: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightsAsync = ref.watch(bookHighlightsProvider(widget.bookId));
    final bookmarksAsync = ref.watch(bookBookmarksProvider(widget.bookId));

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
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
                Row(
                  children: [
                    Text(
                      'Highlights and Notes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.ios_share_rounded,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      tooltip: 'Export',
                      onSelected: (value) {
                        if (value == 'markdown') _exportToMarkdown();
                        if (value == 'pdf') _exportToPdf();
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'markdown',
                          child: Text('Export to Markdown'),
                        ),
                        const PopupMenuItem(
                          value: 'pdf',
                          child: Text('Export to PDF'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Highlights'),
              Tab(text: 'Bookmarks'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Highlights tab
                highlightsAsync.when(
                  data: (highlights) => highlights.isEmpty
                      ? _buildEmptyState(
                          theme,
                          'No highlights yet',
                          'Select text whilst reading to add highlights.',
                        )
                      : ListView.separated(
                          controller: widget.scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: highlights.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, index) =>
                              _buildHighlightTile(highlights[index], theme),
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => _buildEmptyState(
                    theme,
                    'Error',
                    'Could not load highlights.',
                  ),
                ),
                // Bookmarks tab
                bookmarksAsync.when(
                  data: (bookmarks) => bookmarks.isEmpty
                      ? _buildEmptyState(
                          theme,
                          'No bookmarks yet',
                          'Tap the bookmark icon to save your place.',
                        )
                      : ListView.separated(
                          controller: widget.scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: bookmarks.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, index) =>
                              _buildBookmarkTile(bookmarks[index], theme),
                        ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stackTrace) => _buildEmptyState(
                    theme,
                    'Error',
                    'Could not load bookmarks.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notes_rounded,
              size: 40,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              subtitle,
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

  Widget _buildHighlightTile(Highlight highlight, ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _highlightColourValue(highlight.colour),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    highlight.createdAt.toLocal().toString().split('.').first,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await ref
                        .read(annotationDaoProvider)
                        .deleteHighlight(highlight.id);
                    ref.invalidate(bookHighlightsProvider(widget.bookId));
                  },
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _highlightColourValue(
                  highlight.colour,
                ).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                highlight.selectedText,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),
            if (highlight.hasNote) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.sticky_note_2_outlined,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      highlight.note!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookmarkTile(Bookmark bookmark, ThemeData theme) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        dense: true,
        leading: Icon(
          Icons.bookmark_rounded,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        title: Text(
          bookmark.title ?? 'Page ${bookmark.pageNumber}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          bookmark.createdAt.toLocal().toString().split('.').first,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            fontSize: 11,
          ),
        ),
        trailing: InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            await ref.read(annotationDaoProvider).deleteBookmark(bookmark.id);
            ref.invalidate(bookBookmarksProvider(widget.bookId));
          },
          child: Icon(
            Icons.close_rounded,
            size: 18,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}
