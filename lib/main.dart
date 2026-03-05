import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:leaf_reader/core/constants/app_constants.dart';
import 'package:leaf_reader/core/theme/leaf_theme.dart';
import 'package:leaf_reader/domain/entities/app_theme.dart';
import 'package:leaf_reader/presentation/providers/app_providers.dart';
import 'package:leaf_reader/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:leaf_reader/presentation/screens/library/library_screen.dart';

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

  runApp(const ProviderScope(child: LeafReaderApp()));
}

class LeafReaderApp extends ConsumerStatefulWidget {
  const LeafReaderApp({super.key});

  @override
  ConsumerState<LeafReaderApp> createState() => _LeafReaderAppState();
}

class _LeafReaderAppState extends ConsumerState<LeafReaderApp> {
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

    await ref.read(currentThemeProvider.notifier).loadSavedTheme();

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
