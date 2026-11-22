import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/presentation/providers/app_providers.dart';
import 'package:textara/presentation/screens/shell/app_shell.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _importing = false;

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefKeyFirstRun, false);
    if (!mounted) return;
    await Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AppShell()));
  }

  Future<void> _importSample() async {
    if (!ref.read(lowStimulationProvider)) {
      unawaited(HapticFeedback.lightImpact());
    }
    setState(() => _importing = true);

    try {
      final bytes = await rootBundle.load(AppConstants.sampleBookAsset);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/welcome_to_textara.epub');
      await tempFile.writeAsBytes(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        flush: true,
      );

      final result = await ref
          .read(importServiceProvider)
          .importFile(tempFile.path);
      await ref.read(booksProvider.notifier).loadBooks();

      if (!mounted) return;

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sample book imported. You can also import your own EPUB and PDF files.',
            ),
          ),
        );
        await _completeOnboarding();
      } else {
        setState(() => _importing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.errorMessage ??
                  'Could not import the sample book. You can skip and import your own.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not import the sample book. You can skip and import your own.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isTablet = size.shortestSide >= 600;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isTablet ? 520 : 400),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      size: 44,
                      color: theme.colorScheme.primary,
                      semanticLabel: 'Textara logo',
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Welcome to Textara',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                    semanticsLabel: 'Welcome to Textara',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppConstants.appTagline,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  const _FeatureRow(
                    icon: Icons.menu_book_rounded,
                    title: 'DRM-free reading',
                    subtitle:
                        'Import your own EPUB and PDF files. No restrictions, no accounts required.',
                  ),
                  const SizedBox(height: 20),
                  const _FeatureRow(
                    icon: Icons.palette_outlined,
                    title: 'Beautiful and customisable',
                    subtitle:
                        'Choose from 8 themes, adjust typography, and tailor the reading experience to your needs.',
                  ),
                  const SizedBox(height: 20),
                  const _FeatureRow(
                    icon: Icons.offline_bolt_outlined,
                    title: 'Fully offline',
                    subtitle:
                        'Your library stays on your device. No internet needed, ever.',
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _importing ? null : _importSample,
                      child: _importing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Get started with a sample book'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _importing ? null : _completeOnboarding,
                      child: const Text('Skip and import my own books'),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
