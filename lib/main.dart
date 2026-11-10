import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/core/theme/leaf_theme.dart';
import 'package:textara/core/theme/reading_theme_mapper.dart';
import 'package:textara/domain/entities/app_theme.dart';
import 'package:textara/presentation/providers/app_providers.dart';
import 'package:textara/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:textara/presentation/screens/library/library_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const ProviderScope(child: TextaraApp()));
}

class TextaraApp extends ConsumerStatefulWidget {
  const TextaraApp({super.key});

  @override
  ConsumerState<TextaraApp> createState() => _TextaraAppState();
}

class _TextaraAppState extends ConsumerState<TextaraApp> {
  bool _isFirstRun = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialise();
  }

  Future<void> _initialise() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool(AppConstants.prefKeyFirstRun) ?? true;

    await ref.read(readerSettingsProvider.notifier).loadSavedSettings();
    await ref.read(currentThemeProvider.notifier).loadSavedTheme();

    // Prefer the persisted reading-mode triad when present so Light/Dark/Blue
    // survive relaunch even if an older theme id was stored separately.
    final readingMode = ref.read(readerSettingsProvider).themeMode;
    if (readingMode != ReaderThemeMode.highContrast) {
      ref
          .read(currentThemeProvider.notifier)
          .setTheme(ReadingThemeMapper.appThemeFor(readingMode));
    }

    if (!mounted) return;
    setState(() {
      _isFirstRun = isFirst;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = ref.watch(currentThemeProvider);
    final reducedMotion = ref.watch(reducedMotionProvider);

    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: LeafTheme.fromAppTheme(BuiltInThemes.porcelain),
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: LeafTheme.fromAppTheme(appTheme, reducedMotion: reducedMotion),
      home: _isFirstRun ? const OnboardingScreen() : const LibraryScreen(),
    );
  }
}
