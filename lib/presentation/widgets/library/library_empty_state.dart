import 'package:flutter/material.dart';
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/core/theme/leaf_tokens.dart';

class LibraryEmptyState extends StatelessWidget {
  final VoidCallback onImport;

  const LibraryEmptyState({super.key, required this.onImport});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: LeafTokens.spaceXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppConstants.appName,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LeafTokens.spaceSm),
            Text(
              AppConstants.appTagline,
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LeafTokens.spaceLg),
            Text(
              'Your library is empty',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LeafTokens.spaceSm),
            Text(
              'Import DRM-free EPUB and PDF files to start reading privately on this device.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: LeafTokens.spaceXl),
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
