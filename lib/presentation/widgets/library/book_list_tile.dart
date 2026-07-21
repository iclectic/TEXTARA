import 'dart:io';
import 'package:flutter/material.dart';
import 'package:textara/domain/entities/book.dart';
import 'package:textara/core/constants/enums.dart';

class BookListTile extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback onFavourite;

  const BookListTile({
    super.key,
    required this.book,
    required this.onTap,
    required this.onFavourite,
  });

  String _statusLabel(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.notStarted:
        return 'Not started';
      case ReadingStatus.reading:
        return 'Reading';
      case ReadingStatus.finished:
        return 'Finished';
    }
  }

  Color _statusColour(ReadingStatus status, ThemeData theme) {
    switch (status) {
      case ReadingStatus.notStarted:
        return theme.colorScheme.onSurface.withValues(alpha: 0.4);
      case ReadingStatus.reading:
        return theme.colorScheme.primary;
      case ReadingStatus.finished:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label:
          '${book.title} by ${book.author}. ${_statusLabel(book.readingStatus)}. ${book.formattedProgress} read.',
      button: true,
      child: Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 68,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: _buildCover(theme),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        book.author,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColour(
                                book.readingStatus,
                                theme,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _statusLabel(book.readingStatus),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _statusColour(book.readingStatus, theme),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (book.readingProgress > 0)
                            Text(
                              book.formattedProgress,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                                fontSize: 11,
                              ),
                            ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.05,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              book.format.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    book.isFavourite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 20,
                    color: book.isFavourite
                        ? Colors.redAccent
                        : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  onPressed: onFavourite,
                  tooltip: book.isFavourite
                      ? 'Remove from favourites'
                      : 'Add to favourites',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCover(ThemeData theme) {
    if (book.coverPath != null && book.coverPath!.isNotEmpty) {
      final file = File(book.coverPath!);
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(theme),
      );
    }
    return _buildPlaceholder(theme);
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primary.withValues(alpha: 0.15),
      child: Icon(
        book.isEpub ? Icons.menu_book_rounded : Icons.picture_as_pdf_rounded,
        size: 20,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
