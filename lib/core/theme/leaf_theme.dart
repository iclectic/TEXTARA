import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:leaf_reader/domain/entities/app_theme.dart';

class LeafTheme {
  LeafTheme._();

  static ThemeData fromAppTheme(AppTheme appTheme, {bool reducedMotion = false}) {
    final isDark = appTheme.brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: appTheme.brightness,
      primary: appTheme.accentColor,
      onPrimary: isDark ? Colors.black : Colors.white,
      secondary: appTheme.accentColor.withValues(alpha: 0.8),
      onSecondary: isDark ? Colors.black : Colors.white,
      error: const Color(0xFFE53935),
      onError: Colors.white,
      surface: appTheme.surfaceColor,
      onSurface: appTheme.textColor,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: appTheme.backgroundColor,
      cardColor: appTheme.cardColor,
      dividerColor: appTheme.dividerColor,
      textTheme: _buildTextTheme(appTheme.textColor),
      appBarTheme: AppBarTheme(
        backgroundColor: appTheme.backgroundColor,
        foregroundColor: appTheme.textColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: appTheme.textColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: appTheme.cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: appTheme.dividerColor.withValues(alpha: 0.3)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: appTheme.surfaceColor,
        selectedItemColor: appTheme.accentColor,
        unselectedItemColor: appTheme.textColor.withValues(alpha: 0.5),
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: appTheme.accentColor,
        foregroundColor: isDark ? Colors.black : Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: appTheme.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: appTheme.accentColor, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: appTheme.surfaceColor,
        selectedColor: appTheme.accentColor.withValues(alpha: 0.15),
        side: BorderSide(color: appTheme.dividerColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: appTheme.textColor,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF333333) : const Color(0xFF1A1A2E),
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: appTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: appTheme.textColor,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: appTheme.surfaceColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: appTheme.accentColor,
        inactiveTrackColor: appTheme.dividerColor,
        thumbColor: appTheme.accentColor,
        overlayColor: appTheme.accentColor.withValues(alpha: 0.15),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return appTheme.accentColor;
          }
          return appTheme.dividerColor;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return appTheme.accentColor.withValues(alpha: 0.3);
          }
          return appTheme.dividerColor.withValues(alpha: 0.3);
        }),
      ),
      pageTransitionsTheme: reducedMotion
          ? const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
              },
            )
          : null,
    );
  }

  static TextTheme _buildTextTheme(Color textColor) {
    return GoogleFonts.interTextTheme().apply(
      bodyColor: textColor,
      displayColor: textColor,
    );
  }
}
