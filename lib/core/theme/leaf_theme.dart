import 'package:flutter/material.dart';
import 'package:textara/domain/entities/app_theme.dart';

class LeafTheme {
  LeafTheme._();

  static ThemeData fromAppTheme(
    AppTheme appTheme, {
    bool reducedMotion = false,
    bool highContrast = false,
    bool lowStimulation = false,
  }) {
    final resolved = applyAccessibility(
      appTheme,
      highContrast: highContrast,
      lowStimulation: lowStimulation,
    );
    final isDark = resolved.brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: resolved.brightness,
      primary: resolved.accentColor,
      onPrimary: isDark ? Colors.black : Colors.white,
      secondary: resolved.accentColor.withValues(alpha: 0.8),
      onSecondary: isDark ? Colors.black : Colors.white,
      error: const Color(0xFFE53935),
      onError: Colors.white,
      surface: resolved.surfaceColor,
      onSurface: resolved.textColor,
    );

    final fabElevation = lowStimulation ? 0.0 : 2.0;
    final textTheme = _buildTextTheme(resolved.textColor, isDark: isDark);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: resolved.backgroundColor,
      cardColor: resolved.cardColor,
      dividerColor: resolved.dividerColor,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: resolved.backgroundColor,
        foregroundColor: resolved.textColor,
        elevation: 0,
        scrolledUnderElevation: lowStimulation ? 0 : 0.5,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: resolved.textColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: resolved.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(lowStimulation ? 8 : 12),
          side: BorderSide(
            color: resolved.dividerColor.withValues(
              alpha: highContrast ? 0.8 : 0.3,
            ),
            width: highContrast ? 1.5 : 1,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: resolved.surfaceColor,
        selectedItemColor: resolved.accentColor,
        unselectedItemColor: resolved.textColor.withValues(alpha: 0.5),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: resolved.accentColor,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: fabElevation,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: resolved.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: resolved.dividerColor,
            width: highContrast ? 1.5 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: resolved.dividerColor,
            width: highContrast ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: resolved.accentColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: resolved.surfaceColor,
        selectedColor: resolved.accentColor.withValues(alpha: 0.15),
        side: BorderSide(
          color: resolved.dividerColor,
          width: highContrast ? 1.5 : 1,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: textTheme.bodySmall?.copyWith(color: resolved.textColor),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF333333)
            : const Color(0xFF1A1A2E),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: resolved.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: resolved.textColor,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: resolved.surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: resolved.accentColor,
        inactiveTrackColor: resolved.dividerColor,
        thumbColor: resolved.accentColor,
        overlayColor: resolved.accentColor.withValues(alpha: 0.15),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return resolved.accentColor;
          }
          return resolved.dividerColor;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return resolved.accentColor.withValues(alpha: 0.3);
          }
          return resolved.dividerColor.withValues(alpha: 0.3);
        }),
      ),
      pageTransitionsTheme: (reducedMotion || lowStimulation)
          ? const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
              },
            )
          : null,
    );
  }

  /// Applies accessibility overlays without mutating the stored theme identity.
  static AppTheme applyAccessibility(
    AppTheme theme, {
    required bool highContrast,
    required bool lowStimulation,
  }) {
    var resolved = theme;

    if (lowStimulation) {
      resolved = resolved.copyWith(
        accentColor: Color.lerp(theme.accentColor, theme.textColor, 0.35)!,
        highlightPalettePrimary: Color.lerp(
          theme.highlightPalettePrimary,
          theme.surfaceColor,
          0.4,
        )!,
        backgroundTextureStrength: 0,
      );
    }

    if (highContrast) {
      final isDark = resolved.brightness == Brightness.dark;
      resolved = resolved.copyWith(
        backgroundColor: isDark ? Colors.black : Colors.white,
        surfaceColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        cardColor: isDark ? const Color(0xFF111111) : Colors.white,
        textColor: isDark ? Colors.white : Colors.black,
        dividerColor: isDark ? Colors.white : Colors.black,
        accentColor: isDark ? const Color(0xFFFFFF00) : const Color(0xFF0000EE),
      );
    }

    return resolved;
  }

  static TextTheme _buildTextTheme(Color textColor, {required bool isDark}) {
    // Local Material typography — no runtime network font fetch.
    final base = isDark
        ? Typography.material2021().white
        : Typography.material2021().black;
    return base.apply(bodyColor: textColor, displayColor: textColor);
  }
}
