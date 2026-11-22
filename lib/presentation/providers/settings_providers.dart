import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/domain/entities/app_theme.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return SharedPreferences.getInstance();
});

final isFirstRunProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return prefs.getBool(AppConstants.prefKeyFirstRun) ?? true;
});

final currentThemeProvider = StateNotifierProvider<ThemeNotifier, AppTheme>((
  ref,
) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppTheme> {
  ThemeNotifier() : super(BuiltInThemes.porcelain);

  void setTheme(AppTheme theme) {
    state = theme;
    unawaited(_saveTheme(theme.id));
  }

  Future<void> _saveTheme(String themeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefKeyTheme, themeId);
  }

  Future<void> loadSavedTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeId = prefs.getString(AppConstants.prefKeyTheme) ?? 'porcelain';
    state = BuiltInThemes.findById(themeId);
  }
}

final reducedMotionProvider = StateNotifierProvider<BoolSettingNotifier, bool>((
  ref,
) {
  return BoolSettingNotifier(AppConstants.prefKeyReducedMotion);
});

final highContrastProvider = StateNotifierProvider<BoolSettingNotifier, bool>((
  ref,
) {
  return BoolSettingNotifier(AppConstants.prefKeyHighContrast);
});

final dyslexiaModeProvider = StateNotifierProvider<BoolSettingNotifier, bool>((
  ref,
) {
  return BoolSettingNotifier(AppConstants.prefKeyDyslexiaMode);
});

final lowStimulationProvider = StateNotifierProvider<BoolSettingNotifier, bool>(
  (ref) {
    return BoolSettingNotifier(AppConstants.prefKeyLowStimulation);
  },
);

class BoolSettingNotifier extends StateNotifier<bool> {
  final String _prefKey;

  BoolSettingNotifier(this._prefKey) : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_prefKey) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, state);
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
  }
}
