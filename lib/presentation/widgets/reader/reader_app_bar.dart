import 'package:flutter/material.dart';

class ReaderAppBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final VoidCallback onBookmark;
  final VoidCallback onSettings;

  const ReaderAppBar({
    super.key,
    required this.title,
    required this.onBack,
    required this.onBookmark,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.of(context).padding;

    return Container(
      padding: EdgeInsets.only(top: padding.top),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.scaffoldBackgroundColor,
            theme.scaffoldBackgroundColor.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Semantics(
              button: true,
              label: 'Back to library',
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: onBack,
                tooltip: 'Back to library',
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Semantics(
              button: true,
              label: 'Add bookmark at current reading position',
              child: IconButton(
                icon: const Icon(Icons.bookmark_add_outlined),
                onPressed: onBookmark,
                tooltip: 'Add bookmark',
              ),
            ),
            Semantics(
              button: true,
              label: 'Open reader typography and layout settings',
              child: IconButton(
                icon: const Icon(Icons.text_fields_rounded),
                onPressed: onSettings,
                tooltip: 'Reader settings',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
