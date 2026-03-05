import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';

class AppTheme extends Equatable {
  final String id;
  final String name;
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final Color surfaceColor;
  final Color cardColor;
  final Color dividerColor;
  final Color highlightPalettePrimary;
  final double backgroundTextureStrength;
  final Brightness brightness;

  const AppTheme({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.dividerColor,
    this.highlightPalettePrimary = const Color(0xFFFFF176),
    this.backgroundTextureStrength = 0.0,
    this.brightness = Brightness.light,
  });

  AppTheme copyWith({
    String? id,
    String? name,
    Color? backgroundColor,
    Color? textColor,
    Color? accentColor,
    Color? surfaceColor,
    Color? cardColor,
    Color? dividerColor,
    Color? highlightPalettePrimary,
    double? backgroundTextureStrength,
    Brightness? brightness,
  }) {
    return AppTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      accentColor: accentColor ?? this.accentColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      cardColor: cardColor ?? this.cardColor,
      dividerColor: dividerColor ?? this.dividerColor,
      highlightPalettePrimary:
          highlightPalettePrimary ?? this.highlightPalettePrimary,
      backgroundTextureStrength:
          backgroundTextureStrength ?? this.backgroundTextureStrength,
      brightness: brightness ?? this.brightness,
    );
  }

  @override
  List<Object?> get props => [id];
}

class BuiltInThemes {
  BuiltInThemes._();

  static const AppTheme porcelain = AppTheme(
    id: 'porcelain',
    name: 'Porcelain',
    backgroundColor: Color(0xFFFAFAFA),
    textColor: Color(0xFF1A1A2E),
    accentColor: Color(0xFF6366F1),
    surfaceColor: Color(0xFFFFFFFF),
    cardColor: Color(0xFFFFFFFF),
    dividerColor: Color(0xFFE5E7EB),
    brightness: Brightness.light,
  );

  static const AppTheme parchment = AppTheme(
    id: 'parchment',
    name: 'Parchment',
    backgroundColor: Color(0xFFF5F0E8),
    textColor: Color(0xFF3D3229),
    accentColor: Color(0xFFC07A3E),
    surfaceColor: Color(0xFFF9F5EF),
    cardColor: Color(0xFFF9F5EF),
    dividerColor: Color(0xFFDDD5C8),
    brightness: Brightness.light,
  );

  static const AppTheme dusk = AppTheme(
    id: 'dusk',
    name: 'Dusk',
    backgroundColor: Color(0xFF1E1E2E),
    textColor: Color(0xFFCDD6F4),
    accentColor: Color(0xFF89B4FA),
    surfaceColor: Color(0xFF313244),
    cardColor: Color(0xFF313244),
    dividerColor: Color(0xFF45475A),
    brightness: Brightness.dark,
  );

  static const AppTheme midnight = AppTheme(
    id: 'midnight',
    name: 'Midnight',
    backgroundColor: Color(0xFF000000),
    textColor: Color(0xFFE0E0E0),
    accentColor: Color(0xFF818CF8),
    surfaceColor: Color(0xFF0A0A0A),
    cardColor: Color(0xFF111111),
    dividerColor: Color(0xFF1F1F1F),
    brightness: Brightness.dark,
  );

  static const AppTheme sage = AppTheme(
    id: 'sage',
    name: 'Sage',
    backgroundColor: Color(0xFFF0F4F0),
    textColor: Color(0xFF1A2E1A),
    accentColor: Color(0xFF4A7C59),
    surfaceColor: Color(0xFFF5F8F5),
    cardColor: Color(0xFFF5F8F5),
    dividerColor: Color(0xFFD0DCD0),
    brightness: Brightness.light,
  );

  static const AppTheme rosewood = AppTheme(
    id: 'rosewood',
    name: 'Rosewood',
    backgroundColor: Color(0xFF2B1520),
    textColor: Color(0xFFE8D0D8),
    accentColor: Color(0xFFE8789A),
    surfaceColor: Color(0xFF3A1F2D),
    cardColor: Color(0xFF3A1F2D),
    dividerColor: Color(0xFF4D2A3B),
    brightness: Brightness.dark,
  );

  static const AppTheme ocean = AppTheme(
    id: 'ocean',
    name: 'Ocean',
    backgroundColor: Color(0xFFF0F5FA),
    textColor: Color(0xFF1A2744),
    accentColor: Color(0xFF2563EB),
    surfaceColor: Color(0xFFF5F8FC),
    cardColor: Color(0xFFFFFFFF),
    dividerColor: Color(0xFFD0DCE8),
    brightness: Brightness.light,
  );

  static const AppTheme ember = AppTheme(
    id: 'ember',
    name: 'Ember',
    backgroundColor: Color(0xFF1A1210),
    textColor: Color(0xFFE8D8D0),
    accentColor: Color(0xFFE8783C),
    surfaceColor: Color(0xFF261A15),
    cardColor: Color(0xFF261A15),
    dividerColor: Color(0xFF3D2A20),
    brightness: Brightness.dark,
  );

  static List<AppTheme> get all => [
        porcelain,
        parchment,
        dusk,
        midnight,
        sage,
        rosewood,
        ocean,
        ember,
      ];

  static AppTheme findById(String id) {
    return all.firstWhere(
      (t) => t.id == id,
      orElse: () => porcelain,
    );
  }
}
