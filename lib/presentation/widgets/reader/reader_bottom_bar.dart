import 'package:flutter/material.dart';

class ReaderBottomBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final String chapterTitle;
  final double progress;
  final int minutesLeft;
  final VoidCallback onToc;
  final VoidCallback onAnnotations;

  const ReaderBottomBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.chapterTitle,
    required this.progress,
    required this.minutesLeft,
    required this.onToc,
    required this.onAnnotations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.of(context).padding;

    return Container(
      padding: EdgeInsets.only(bottom: padding.bottom),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            theme.scaffoldBackgroundColor,
            theme.scaffoldBackgroundColor.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor:
                    theme.colorScheme.onSurface.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 8),
            // Info row
            Row(
              children: [
                Expanded(
                  child: Text(
                    chapterTitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '$currentPage / $totalPages',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
                if (minutesLeft > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${minutesLeft}min left',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BottomAction(
                  icon: Icons.toc_rounded,
                  label: 'Contents',
                  onTap: onToc,
                ),
                _BottomAction(
                  icon: Icons.format_quote_rounded,
                  label: 'Notes',
                  onTap: onAnnotations,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
