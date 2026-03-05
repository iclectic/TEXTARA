import 'package:flutter_test/flutter_test.dart';
import 'package:leaf_reader/core/constants/enums.dart';
import 'package:leaf_reader/domain/entities/reader_settings.dart';

void main() {
  group('ReaderSettings', () {
    test('default values are sensible', () {
      const settings = ReaderSettings();
      expect(settings.fontFamily, 'Literata');
      expect(settings.fontSize, 16.0);
      expect(settings.lineHeight, 1.6);
      expect(settings.paragraphSpacing, 12.0);
      expect(settings.horizontalMargin, 24.0);
      expect(settings.textAlignment, TextAlignment.left);
      expect(settings.hyphenationEnabled, false);
      expect(settings.themeMode, ReaderThemeMode.light);
    });

    test('copyWith updates specified fields only', () {
      const settings = ReaderSettings();
      final updated = settings.copyWith(
        fontSize: 20.0,
        lineHeight: 2.0,
      );
      expect(updated.fontSize, 20.0);
      expect(updated.lineHeight, 2.0);
      expect(updated.fontFamily, 'Literata');
      expect(updated.horizontalMargin, 24.0);
    });

    test('toJson produces valid JSON map', () {
      const settings = ReaderSettings();
      final json = settings.toJson();
      expect(json['fontFamily'], 'Literata');
      expect(json['fontSize'], 16.0);
      expect(json['lineHeight'], 1.6);
      expect(json['textAlignment'], 'left');
      expect(json['hyphenationEnabled'], false);
      expect(json['themeMode'], 'light');
    });

    test('fromJson round-trips correctly', () {
      const original = ReaderSettings(
        fontFamily: 'Merriweather',
        fontSize: 22.0,
        lineHeight: 1.8,
        paragraphSpacing: 16.0,
        horizontalMargin: 32.0,
        textAlignment: TextAlignment.justify,
        hyphenationEnabled: true,
        themeMode: ReaderThemeMode.sepia,
      );
      final json = original.toJson();
      final restored = ReaderSettings.fromJson(json);
      expect(restored.fontFamily, 'Merriweather');
      expect(restored.fontSize, 22.0);
      expect(restored.lineHeight, 1.8);
      expect(restored.paragraphSpacing, 16.0);
      expect(restored.horizontalMargin, 32.0);
      expect(restored.textAlignment, TextAlignment.justify);
      expect(restored.hyphenationEnabled, true);
      expect(restored.themeMode, ReaderThemeMode.sepia);
    });

    test('fromJson handles missing fields gracefully', () {
      final restored = ReaderSettings.fromJson(<String, dynamic>{});
      expect(restored.fontFamily, 'Literata');
      expect(restored.fontSize, 16.0);
      expect(restored.lineHeight, 1.6);
      expect(restored.textAlignment, TextAlignment.left);
    });

    test('fromJson handles invalid enum values gracefully', () {
      final json = <String, dynamic>{
        'textAlignment': 'invalid_value',
        'themeMode': 'nonexistent',
      };
      final restored = ReaderSettings.fromJson(json);
      expect(restored.textAlignment, TextAlignment.left);
      expect(restored.themeMode, ReaderThemeMode.light);
    });

    test('equatable compares all fields', () {
      const a = ReaderSettings();
      const b = ReaderSettings();
      expect(a, equals(b));

      final c = a.copyWith(fontSize: 20.0);
      expect(a, isNot(equals(c)));
    });
  });
}
