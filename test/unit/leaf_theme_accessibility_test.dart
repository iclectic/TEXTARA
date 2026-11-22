import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textara/core/theme/leaf_theme.dart';
import 'package:textara/domain/entities/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LeafTheme accessibility overlays', () {
    test('high contrast forces black/white surfaces for light themes', () {
      final theme = LeafTheme.fromAppTheme(
        BuiltInThemes.porcelain,
        highContrast: true,
      );
      expect(theme.scaffoldBackgroundColor, Colors.white);
      expect(theme.colorScheme.onSurface, Colors.black);
      expect(theme.dividerColor, Colors.black);
    });

    test('high contrast forces black surfaces for dark themes', () {
      final theme = LeafTheme.fromAppTheme(
        BuiltInThemes.dusk,
        highContrast: true,
      );
      expect(theme.scaffoldBackgroundColor, Colors.black);
      expect(theme.colorScheme.onSurface, Colors.white);
    });

    test('low stimulation reduces FAB elevation', () {
      final normal = LeafTheme.fromAppTheme(BuiltInThemes.porcelain);
      final calm = LeafTheme.fromAppTheme(
        BuiltInThemes.porcelain,
        lowStimulation: true,
      );
      expect(normal.floatingActionButtonTheme.elevation, 2);
      expect(calm.floatingActionButtonTheme.elevation, 0);
    });

    test('reduced motion installs fade page transitions', () {
      final theme = LeafTheme.fromAppTheme(
        BuiltInThemes.porcelain,
        reducedMotion: true,
      );
      expect(theme.pageTransitionsTheme, isNotNull);
      expect(
        theme.pageTransitionsTheme.builders[TargetPlatform.android],
        isA<FadeUpwardsPageTransitionsBuilder>(),
      );
    });

    test('low stimulation also uses calm page transitions', () {
      final theme = LeafTheme.fromAppTheme(
        BuiltInThemes.porcelain,
        lowStimulation: true,
      );
      expect(
        theme.pageTransitionsTheme.builders[TargetPlatform.iOS],
        isA<FadeUpwardsPageTransitionsBuilder>(),
      );
    });

    test('applyAccessibility mutes accent under low stimulation', () {
      final resolved = LeafTheme.applyAccessibility(
        BuiltInThemes.porcelain,
        highContrast: false,
        lowStimulation: true,
      );
      expect(resolved.accentColor, isNot(BuiltInThemes.porcelain.accentColor));
      expect(resolved.backgroundTextureStrength, 0);
    });
  });
}
