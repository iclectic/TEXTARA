import 'dart:io';
import 'package:flutter/material.dart';
import 'package:leaf_reader/domain/entities/book.dart';

class BookGridTile extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;

  const BookGridTile({
    super.key,
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '${book.title} by ${book.author}. ${book.formattedProgress} read.',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildCover(theme),
                      if (book.readingProgress > 0)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: _buildProgressBar(theme),
                        ),
                      if (book.isFavourite)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              book.author,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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
        errorBuilder: (_, __, ___) => _buildPlaceholderCover(theme),
      );
    }
    return _buildPlaceholderCover(theme);
  }

  Widget _buildPlaceholderCover(ThemeData theme) {
    final colours = [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF14B8A6),
      const Color(0xFFF59E0B),
      const Color(0xFF3B82F6),
    ];
    final colourIndex = book.title.hashCode.abs() % colours.length;

    return Container(
      color: colours[colourIndex],
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            book.isEpub ? Icons.menu_book_rounded : Icons.picture_as_pdf_rounded,
            color: Colors.white.withValues(alpha: 0.8),
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            book.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            book.author,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    return Container(
      height: 3,
      color: Colors.black.withValues(alpha: 0.2),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: book.readingProgress.clamp(0.0, 1.0),
        child: Container(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
