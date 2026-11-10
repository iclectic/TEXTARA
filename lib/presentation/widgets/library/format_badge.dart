import 'package:flutter/material.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/book.dart';

class FormatBadge extends StatelessWidget {
  final BookFormat format;
  final bool compact;

  const FormatBadge({super.key, required this.format, this.compact = false});

  factory FormatBadge.forBook(Book book, {bool compact = false}) {
    return FormatBadge(format: book.format, compact: compact);
  }

  Color _colour(ThemeData theme) {
    switch (format) {
      case BookFormat.epub:
        return const Color(0xFF2F6FED);
      case BookFormat.pdf:
        return const Color(0xFFC62828);
      case BookFormat.txt:
        return const Color(0xFF455A64);
      case BookFormat.fb2:
        return const Color(0xFF00695C);
      case BookFormat.mobi:
        return const Color(0xFF6A1B9A);
    }
  }

  String get _label {
    switch (format) {
      case BookFormat.epub:
        return 'EPUB';
      case BookFormat.pdf:
        return 'PDF';
      case BookFormat.txt:
        return 'TXT';
      case BookFormat.fb2:
        return 'FB2';
      case BookFormat.mobi:
        return 'MOBI';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colour = _colour(theme);
    return Semantics(
      label: 'Format $_label',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 5 : 6,
          vertical: compact ? 1 : 2,
        ),
        decoration: BoxDecoration(
          color: colour.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: colour.withValues(alpha: 0.35)),
        ),
        child: Text(
          _label,
          style: TextStyle(
            fontSize: compact ? 8 : 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: colour,
          ),
        ),
      ),
    );
  }
}

IconData formatIconFor(BookFormat format) {
  switch (format) {
    case BookFormat.epub:
      return Icons.menu_book_rounded;
    case BookFormat.pdf:
      return Icons.picture_as_pdf_rounded;
    case BookFormat.txt:
      return Icons.article_outlined;
    case BookFormat.fb2:
      return Icons.auto_stories_outlined;
    case BookFormat.mobi:
      return Icons.tablet_mac_outlined;
  }
}
