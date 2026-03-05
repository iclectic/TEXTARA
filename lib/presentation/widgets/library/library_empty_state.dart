import 'package:flutter/material.dart';

class LibraryEmptyState extends StatelessWidget {
  final VoidCallback onImport;

  const LibraryEmptyState({super.key, required this.onImport});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.library_books_outlined,
                size: 36,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Your library is empty',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Import your DRM-free EPUB and PDF files to start reading. You can also use the share menu or Files app to send books here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Import books'),
            ),
          ],
        ),
      ),
    );
  }
}
