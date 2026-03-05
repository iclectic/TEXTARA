import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/domain/entities/app_theme.dart';
import 'package:textara/presentation/providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(currentThemeProvider);
    final reducedMotion = ref.watch(reducedMotionProvider);
    final highContrast = ref.watch(highContrastProvider);
    final dyslexiaMode = ref.watch(dyslexiaModeProvider);
    final lowStimulation = ref.watch(lowStimulationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(title: 'Appearance'),
          _ThemeSelector(
            currentTheme: currentTheme,
            onChanged: (t) {
              HapticFeedback.selectionClick();
              ref.read(currentThemeProvider.notifier).setTheme(t);
            },
          ),
          const Divider(height: 32),

          _SectionHeader(title: 'Accessibility'),
          SwitchListTile(
            title: const Text('Reduced motion'),
            subtitle: const Text(
                'Disable animations and transitions'),
            value: reducedMotion,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              ref.read(reducedMotionProvider.notifier).toggle();
            },
          ),
          SwitchListTile(
            title: const Text('High contrast'),
            subtitle:
                const Text('Increase contrast for better readability'),
            value: highContrast,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              ref.read(highContrastProvider.notifier).toggle();
            },
          ),
          SwitchListTile(
            title: const Text('Dyslexia-friendly mode'),
            subtitle: const Text(
                'Use a dyslexia-friendly font with extra spacing'),
            value: dyslexiaMode,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              ref.read(dyslexiaModeProvider.notifier).toggle();
            },
          ),
          SwitchListTile(
            title: const Text('Low stimulation mode'),
            subtitle: const Text(
                'Muted colours and simplified interface'),
            value: lowStimulation,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              ref.read(lowStimulationProvider.notifier).toggle();
            },
          ),
          const Divider(height: 32),

          _SectionHeader(title: 'Data'),
          ListTile(
            leading: const Icon(Icons.upload_rounded),
            title: const Text('Export backup'),
            subtitle: const Text(
                'Save library data, highlights, and notes'),
            onTap: () => _exportBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download_rounded),
            title: const Text('Import backup'),
            subtitle: const Text(
                'Restore from a Textara backup file'),
            onTap: () => _importBackup(context, ref),
          ),
          const Divider(height: 32),

          _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('Textara'),
            subtitle: Text('Version ${AppConstants.appVersion}'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('DRM-free only'),
            subtitle: const Text(
                'Textara supports DRM-free EPUB and PDF files. It does not bypass or remove DRM.'),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    try {
      final exportService = ref.read(exportServiceProvider);
      final path = await exportService.exportBackup();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup saved to: $path')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Backup failed. Please try again.')),
      );
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact();
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.first.path;
      if (filePath == null) return;

      final exportService = ref.read(exportServiceProvider);
      final backup = await exportService.importBackup(filePath);

      if (!context.mounted) return;

      if (backup != null) {
        ref.read(booksProvider.notifier).loadBooks();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Restored ${backup.books.length} books, ${backup.highlights.length} highlights.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Could not read this backup file. It may be corrupted or from a different app.'),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Import failed. Please try again.')),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  final AppTheme currentTheme;
  final ValueChanged<AppTheme> onChanged;

  const _ThemeSelector({
    required this.currentTheme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 88,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: BuiltInThemes.all.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final appTheme = BuiltInThemes.all[index];
          final isSelected = appTheme.id == currentTheme.id;

          return Semantics(
            label: '${appTheme.name} theme${isSelected ? ', selected' : ''}',
            button: true,
            child: GestureDetector(
              onTap: () => onChanged(appTheme),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: appTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: appTheme.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 3,
                          decoration: BoxDecoration(
                            color: appTheme.textColor,
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      appTheme.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
