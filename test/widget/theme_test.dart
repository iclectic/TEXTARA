import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textara/domain/entities/app_theme.dart';

void main() {
  group('BuiltInThemes', () {
    test('contains exactly 8 themes', () {
      expect(BuiltInThemes.all.length, 8);
    });

    test('all themes have unique ids', () {
      final ids = BuiltInThemes.all.map((t) => t.id).toSet();
      expect(ids.length, 8);
    });

    test('all themes have non-empty names', () {
      for (final theme in BuiltInThemes.all) {
        expect(theme.name.isNotEmpty, true);
      }
    });

    test('findById returns correct theme', () {
      expect(BuiltInThemes.findById('dusk').name, 'Dusk');
      expect(BuiltInThemes.findById('sage').name, 'Sage');
      expect(BuiltInThemes.findById('midnight').name, 'Midnight');
    });

    test('findById returns porcelain for unknown id', () {
      expect(BuiltInThemes.findById('nonexistent').id, 'porcelain');
    });

    test('theme names are: Porcelain, Parchment, Dusk, Midnight, Sage, Rosewood, Ocean, Ember',
        () {
      final names = BuiltInThemes.all.map((t) => t.name).toList();
      expect(names, [
        'Porcelain',
        'Parchment',
        'Dusk',
        'Midnight',
        'Sage',
        'Rosewood',
        'Ocean',
        'Ember',
      ]);
    });

    test('porcelain is a light theme', () {
      expect(BuiltInThemes.porcelain.brightness, Brightness.light);
    });

    test('dusk is a dark theme', () {
      expect(BuiltInThemes.dusk.brightness, Brightness.dark);
    });

    test('midnight has true black background', () {
      expect(BuiltInThemes.midnight.backgroundColor, const Color(0xFF000000));
    });

    test('parchment is a light sepia theme', () {
      expect(BuiltInThemes.parchment.brightness, Brightness.light);
    });

    test('all themes have valid colours', () {
      for (final theme in BuiltInThemes.all) {
        expect(theme.backgroundColor, isNotNull);
        expect(theme.textColor, isNotNull);
        expect(theme.accentColor, isNotNull);
        expect(theme.surfaceColor, isNotNull);
        expect(theme.cardColor, isNotNull);
        expect(theme.dividerColor, isNotNull);
      }
    });

    test('all themes have correct brightness for their background', () {
      for (final theme in BuiltInThemes.all) {
        final luminance = theme.backgroundColor.computeLuminance();
        if (theme.brightness == Brightness.dark) {
          expect(luminance, lessThan(0.5),
              reason: '${theme.name} should have dark background');
        } else {
          expect(luminance, greaterThanOrEqualTo(0.3),
              reason: '${theme.name} should have light background');
        }
      }
    });
  });

  group('Theme switching in widget tree', () {
    testWidgets('switching AppTheme updates scaffold background',
        (WidgetTester tester) async {
      AppTheme currentTheme = BuiltInThemes.porcelain;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              theme: ThemeData(
                scaffoldBackgroundColor: currentTheme.backgroundColor,
                colorScheme: ColorScheme(
                  brightness: currentTheme.brightness,
                  primary: currentTheme.accentColor,
                  onPrimary: Colors.white,
                  secondary: currentTheme.accentColor,
                  onSecondary: Colors.white,
                  error: Colors.red,
                  onError: Colors.white,
                  surface: currentTheme.surfaceColor,
                  onSurface: currentTheme.textColor,
                ),
              ),
              home: Scaffold(
                body: Column(
                  children: [
                    Text('Theme: ${currentTheme.name}'),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentTheme = BuiltInThemes.dusk;
                        });
                      },
                      child: const Text('Switch to Dusk'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Theme: Porcelain'), findsOneWidget);

      await tester.tap(find.text('Switch to Dusk'));
      await tester.pumpAndSettle();

      expect(find.text('Theme: Dusk'), findsOneWidget);

      final scaffoldContext = tester.element(find.byType(Scaffold));
      final resolvedTheme = Theme.of(scaffoldContext);
      expect(resolvedTheme.scaffoldBackgroundColor,
          BuiltInThemes.dusk.backgroundColor);
    });
  });
}
