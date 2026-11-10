import 'package:flutter/material.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/domain/entities/reader_location.dart';

class ContinueReadingCard extends StatelessWidget {
  final Book book;
  final VoidCallback onContinue;

  const ContinueReadingCard({
    super.key,
    required this.book,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = ReaderLocation.fromBook(book);
    final percent = (book.readingProgress * 100).clamp(0, 100).round();

    return Semantics(
      button: true,
      label:
          'Continue reading ${book.title} by ${book.author}, $percent percent complete',
      child: Material(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onContinue,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Continue reading',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$percent%',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${book.author} · ${location.displayLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: book.readingProgress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor:
                        theme.colorScheme.primary.withValues(alpha: 0.12),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Automatic resume — separate from manual bookmarks',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
