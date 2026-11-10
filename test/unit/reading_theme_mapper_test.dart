import 'package:flutter_test/flutter_test.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/core/theme/reading_theme_mapper.dart';
import 'package:textara/domain/entities/app_theme.dart';

void main() {
  group('ReadingThemeMapper', () {
    test('primaryModes are light, dark, and blue', () {
      expect(ReadingThemeMapper.primaryModes, [
        ReaderThemeMode.light,
        ReaderThemeMode.dark,
        ReaderThemeMode.blue,
      ]);
    });

    test('maps reading triad onto porcelain, dusk, and azure', () {
      expect(
        ReadingThemeMapper.appThemeFor(ReaderThemeMode.light).id,
        'porcelain',
      );
      expect(ReadingThemeMapper.appThemeFor(ReaderThemeMode.dark).id, 'dusk');
      expect(ReadingThemeMapper.appThemeFor(ReaderThemeMode.blue).id, 'azure');
    });

    test('maps legacy modes', () {
      expect(
        ReadingThemeMapper.appThemeFor(ReaderThemeMode.trueBlack).id,
        'midnight',
      );
      expect(
        ReadingThemeMapper.appThemeFor(ReaderThemeMode.sepia).id,
        'parchment',
      );
    });

    test('reverse maps known themes', () {
      expect(
        ReadingThemeMapper.modeForAppTheme(BuiltInThemes.porcelain),
        ReaderThemeMode.light,
      );
      expect(
        ReadingThemeMapper.modeForAppTheme(BuiltInThemes.dusk),
        ReaderThemeMode.dark,
      );
      expect(
        ReadingThemeMapper.modeForAppTheme(BuiltInThemes.azure),
        ReaderThemeMode.blue,
      );
      expect(ReadingThemeMapper.modeForAppTheme(BuiltInThemes.sage), isNull);
    });

    test('labels are human readable', () {
      expect(ReadingThemeMapper.labelFor(ReaderThemeMode.light), 'Light');
      expect(ReadingThemeMapper.labelFor(ReaderThemeMode.dark), 'Dark');
      expect(ReadingThemeMapper.labelFor(ReaderThemeMode.blue), 'Blue');
    });
  });
}
