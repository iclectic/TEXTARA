import 'package:flutter/material.dart';
import 'package:textara/core/theme/design_tokens.dart';
import 'package:textara/domain/entities/app_theme.dart';

class LeafTheme {
  LeafTheme._();

  static ThemeData fromAppTheme(
    AppTheme appTheme, {
    bool reducedMotion = false,
    bool highContrast = false,
    bool lowStimulation = false,
  }) {
    final effectiveTheme = _applyAccessibilityModes(
      appTheme,
      highContrast: highContrast,
      lowStimulation: lowStimulation,
    );
    final isDark = effectiveTheme.brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: effectiveTheme.brightness,
      primary: effectiveTheme.accentColor,
      onPrimary: isDark ? Colors.black : Colors.white,
      secondary: effectiveTheme.accentColor.withValues(alpha: 0.8),
      onSecondary: isDark ? Colors.black : Colors.white,
      error: const Color(0xFFE53935),
      onError: Colors.white,
      surface: effectiveTheme.surfaceColor,
      onSurface: effectiveTheme.textColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: effectiveTheme.backgroundColor,
      cardColor: effectiveTheme.cardColor,
      dividerColor: effectiveTheme.dividerColor,
      textTheme: _buildTextTheme(effectiveTheme.textColor),
      appBarTheme: AppBarTheme(
        backgroundColor: effectiveTheme.backgroundColor,
        foregroundColor: effectiveTheme.textColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: effectiveTheme.textColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: effectiveTheme.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TextaraRadius.lg),
          side: BorderSide(
            color: effectiveTheme.dividerColor.withValues(
              alpha: highContrast ? 0.9 : 0.3,
            ),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: effectiveTheme.surfaceColor,
        selectedItemColor: effectiveTheme.accentColor,
        unselectedItemColor: effectiveTheme.textColor.withValues(alpha: 0.6),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: effectiveTheme.accentColor,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: lowStimulation ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TextaraRadius.lg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: effectiveTheme.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TextaraRadius.md),
          borderSide: BorderSide(color: effectiveTheme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TextaraRadius.md),
          borderSide: BorderSide(color: effectiveTheme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TextaraRadius.md),
          borderSide: BorderSide(color: effectiveTheme.accentColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TextaraSpacing.lg,
          vertical: TextaraSpacing.md,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: effectiveTheme.surfaceColor,
        selectedColor: effectiveTheme.accentColor.withValues(alpha: 0.15),
        side: BorderSide(color: effectiveTheme.dividerColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TextaraRadius.xl),
        ),
        labelStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          color: effectiveTheme.textColor,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF333333)
            : const Color(0xFF1A1A2E),
        contentTextStyle: const TextStyle(
          fontFamily: 'Inter',
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TextaraRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: effectiveTheme.surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TextaraRadius.xl),
        ),
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: effectiveTheme.textColor,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: effectiveTheme.surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(TextaraRadius.xl),
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: effectiveTheme.accentColor,
        inactiveTrackColor: effectiveTheme.dividerColor,
        thumbColor: effectiveTheme.accentColor,
        overlayColor: effectiveTheme.accentColor.withValues(alpha: 0.15),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return effectiveTheme.accentColor;
          }
          return effectiveTheme.dividerColor;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return effectiveTheme.accentColor.withValues(alpha: 0.3);
          }
          return effectiveTheme.dividerColor.withValues(alpha: 0.3);
        }),
      ),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: reducedMotion
          ? const PageTransitionsTheme(
              builders: {
                TargetPlatform.android:
                    TextaraNoAnimationPageTransitionsBuilder(),
                TargetPlatform.iOS: TextaraNoAnimationPageTransitionsBuilder(),
              },
            )
          : null,
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    return Typography.material2021().black.apply(
      fontFamily: 'Inter',
      bodyColor: textColor,
      displayColor: textColor,
    );
  }

  static AppTheme _applyAccessibilityModes(
    AppTheme theme, {
    required bool highContrast,
    required bool lowStimulation,
  }) {
    var effective = theme;

    if (lowStimulation) {
      final isDark = theme.brightness == Brightness.dark;
      effective = effective.copyWith(
        backgroundColor: isDark
            ? const Color(0xFF111111)
            : const Color(0xFFF7F7F2),
        surfaceColor: isDark
            ? const Color(0xFF181818)
            : const Color(0xFFFCFCF8),
        cardColor: isDark ? const Color(0xFF181818) : const Color(0xFFFFFFFF),
        accentColor: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF5F6F65),
        dividerColor: isDark
            ? const Color(0xFF333333)
            : const Color(0xFFD8D8D0),
      );
    }

    if (highContrast) {
      final isDark = effective.brightness == Brightness.dark;
      effective = effective.copyWith(
        backgroundColor: isDark ? Colors.black : Colors.white,
        surfaceColor: isDark ? const Color(0xFF050505) : Colors.white,
        cardColor: isDark ? const Color(0xFF0D0D0D) : Colors.white,
        textColor: isDark ? Colors.white : Colors.black,
        accentColor: isDark ? const Color(0xFFFFD54F) : const Color(0xFF003EA8),
        dividerColor: isDark
            ? const Color(0xFFE0E0E0)
            : const Color(0xFF222222),
      );
    }

    return effective;
  }
}

class TextaraNoAnimationPageTransitionsBuilder extends PageTransitionsBuilder {
  const TextaraNoAnimationPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
