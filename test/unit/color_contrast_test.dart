import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/core/theme/reading_theme_mapper.dart';
import 'package:textara/core/utils/color_contrast.dart';

void main() {
  group('ColorContrast', () {
    test('black on white is 21:1', () {
      expect(
        ColorContrast.ratio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21.0, 0.05),
      );
    });

    test('Light / Dark / Blue reading themes meet AA for body text', () {
      for (final mode in ReadingThemeMapper.primaryModes) {
        final theme = ReadingThemeMapper.appThemeFor(mode);
        final ratio = ColorContrast.ratio(
          theme.textColor,
          theme.backgroundColor,
        );
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              '${mode.name} (${theme.id}) text/background contrast was $ratio',
        );
        expect(
          ColorContrast.meetsAa(theme.textColor, theme.backgroundColor),
          isTrue,
        );
      }
    });

    test('primary triad maps to Porcelain / Dusk / Azure', () {
      expect(
        ReadingThemeMapper.appThemeFor(ReaderThemeMode.light).id,
        'porcelain',
      );
      expect(ReadingThemeMapper.appThemeFor(ReaderThemeMode.dark).id, 'dusk');
      expect(ReadingThemeMapper.appThemeFor(ReaderThemeMode.blue).id, 'azure');
    });
  });
}
