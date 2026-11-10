import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/app_theme.dart';

/// Maps the quick Light / Dark / Blue reading triad (plus legacy modes)
/// onto concrete [AppTheme] values.
class ReadingThemeMapper {
  ReadingThemeMapper._();

  static const primaryModes = <ReaderThemeMode>[
    ReaderThemeMode.light,
    ReaderThemeMode.dark,
    ReaderThemeMode.blue,
  ];

  static AppTheme appThemeFor(ReaderThemeMode mode) {
    switch (mode) {
      case ReaderThemeMode.light:
        return BuiltInThemes.porcelain;
      case ReaderThemeMode.dark:
        return BuiltInThemes.dusk;
      case ReaderThemeMode.blue:
        return BuiltInThemes.azure;
      case ReaderThemeMode.trueBlack:
        return BuiltInThemes.midnight;
      case ReaderThemeMode.sepia:
        return BuiltInThemes.parchment;
      case ReaderThemeMode.highContrast:
        return BuiltInThemes.porcelain;
    }
  }

  static String labelFor(ReaderThemeMode mode) {
    switch (mode) {
      case ReaderThemeMode.light:
        return 'Light';
      case ReaderThemeMode.dark:
        return 'Dark';
      case ReaderThemeMode.blue:
        return 'Blue';
      case ReaderThemeMode.trueBlack:
        return 'True black';
      case ReaderThemeMode.sepia:
        return 'Sepia';
      case ReaderThemeMode.highContrast:
        return 'High contrast';
    }
  }

  /// Best-effort reverse map when the user picks a theme from Settings.
  static ReaderThemeMode? modeForAppTheme(AppTheme theme) {
    switch (theme.id) {
      case 'porcelain':
        return ReaderThemeMode.light;
      case 'dusk':
        return ReaderThemeMode.dark;
      case 'azure':
        return ReaderThemeMode.blue;
      case 'midnight':
        return ReaderThemeMode.trueBlack;
      case 'parchment':
        return ReaderThemeMode.sepia;
      default:
        return null;
    }
  }
}
