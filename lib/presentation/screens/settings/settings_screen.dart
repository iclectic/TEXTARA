import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/core/errors/local_error_log.dart';
import 'package:textara/data/services/encrypted_backup.dart';
import 'package:textara/domain/entities/app_theme.dart';
import 'package:textara/presentation/providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  final bool embeddedInShell;

  const SettingsScreen({super.key, this.embeddedInShell = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(currentThemeProvider);
    final reducedMotion = ref.watch(reducedMotionProvider);
    final highContrast = ref.watch(highContrastProvider);
    final dyslexiaMode = ref.watch(dyslexiaModeProvider);
    final lowStimulation = ref.watch(lowStimulationProvider);
    final threadInsights = ref.watch(threadInsightsEnabledProvider);
    final readingReminder = ref.watch(readingReminderEnabledProvider);
    final statsAsync = ref.watch(readingStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: !embeddedInShell,
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
            subtitle: const Text('Disable animations and transitions'),
            value: reducedMotion,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              ref.read(reducedMotionProvider.notifier).toggle();
            },
          ),
          SwitchListTile(
            title: const Text('High contrast'),
            subtitle: const Text('Increase contrast for better readability'),
            value: highContrast,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              ref.read(highContrastProvider.notifier).toggle();
            },
          ),
          SwitchListTile(
            title: const Text('Dyslexia-friendly mode'),
            subtitle: const Text(
              'Use a dyslexia-friendly font with extra spacing',
            ),
            value: dyslexiaMode,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              ref.read(dyslexiaModeProvider.notifier).toggle();
            },
          ),
          SwitchListTile(
            title: const Text('Low stimulation mode'),
            subtitle: const Text('Muted colours and simplified interface'),
            value: lowStimulation,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              ref.read(lowStimulationProvider.notifier).toggle();
            },
          ),
          const Divider(height: 32),

          _SectionHeader(title: 'Idea Threads'),
          SwitchListTile(
            title: const Text('Local suggestions'),
            subtitle: const Text(
              'Show offline tips like recurring terms or threads that need evidence',
            ),
            value: threadInsights,
            onChanged: (_) {
              HapticFeedback.selectionClick();
              ref.read(threadInsightsEnabledProvider.notifier).toggle();
            },
          ),
          const Divider(height: 32),

          _SectionHeader(title: 'Reading insights'),
          statsAsync.when(
            data: (stats) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '${stats.totalMinutesRead} min read · '
                '${stats.booksFinished} finished · '
                '${stats.highlightCount} highlights · '
                '${stats.booksInLibrary} in library',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => ListTile(title: Text('Stats unavailable: $e')),
          ),
          SwitchListTile(
            title: const Text('Daily reading reminder'),
            subtitle: const Text(
              'Off by default. Local notification only — never marketing.',
            ),
            value: readingReminder,
            onChanged: (_) async {
              HapticFeedback.selectionClick();
              final next = !readingReminder;
              await ref.read(readingReminderEnabledProvider.notifier).set(next);
              final reminders = ref.read(readingReminderServiceProvider);
              if (next) {
                await reminders.scheduleDaily(hour: 20, minute: 0);
              } else {
                await reminders.cancel();
              }
            },
          ),
          const Divider(height: 32),

          _SectionHeader(title: 'Data'),
          ListTile(
            leading: const Icon(Icons.upload_rounded),
            title: const Text('Export backup'),
            subtitle: const Text('Save library data, highlights, and notes'),
            onTap: () => _exportBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.download_rounded),
            title: const Text('Import backup'),
            subtitle: const Text('Restore from a Textara backup file'),
            onTap: () => _importBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline_rounded),
            title: const Text('Export encrypted backup'),
            subtitle: const Text(
              'Passphrase-protected copy — stays on this device unless you share it',
            ),
            onTap: () => _exportEncryptedBackup(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Export diagnostics'),
            subtitle: const Text(
              'Local error log only — no book titles or contents',
            ),
            onTap: () => _exportDiagnostics(context),
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
              'Textara supports DRM-free EPUB and PDF files. It does not bypass or remove DRM.',
            ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Backup saved to: $path')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup failed. Please try again.')),
      );
    }
  }

  Future<void> _exportEncryptedBackup(
    BuildContext context,
    WidgetRef ref,
  ) async {
    HapticFeedback.mediumImpact();
    final controller = TextEditingController();
    final passphrase = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Encrypted backup'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Passphrase (min 8 characters)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Encrypt'),
          ),
        ],
      ),
    );
    if (passphrase == null || passphrase.trim().length < 8) {
      if (!context.mounted) return;
      if (passphrase != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passphrase must be at least 8 characters.'),
          ),
        );
      }
      return;
    }
    try {
      final plainPath = await ref.read(exportServiceProvider).exportBackup();
      final plain = await File(plainPath).readAsString();
      final sealed = EncryptedBackup.seal(plain, passphrase);
      final encPath = plainPath.replaceFirst('.json', '.textara.json');
      await File(encPath).writeAsString(sealed);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Encrypted backup saved to: $encPath')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Encrypted backup failed. Please try again.'),
        ),
      );
    }
  }

  Future<void> _exportDiagnostics(BuildContext context) async {
    HapticFeedback.mediumImpact();
    try {
      final path = await LocalErrorLog.exportDiagnostics();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Diagnostics saved to: $path')));
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not export diagnostics.')),
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
              'Restored ${backup.books.length} books, ${backup.highlights.length} highlights.',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not read this backup file. It may be corrupted or from a different app.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import failed. Please try again.')),
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

  const _ThemeSelector({required this.currentTheme, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 88,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: BuiltInThemes.all.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
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
