import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textara/core/constants/app_constants.dart';
import 'package:textara/core/constants/enums.dart';
import 'package:textara/domain/entities/reader_settings.dart';
import 'package:textara/presentation/providers/reader_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReaderSettingsNotifier persistence', () {
    test('loads saved settings from SharedPreferences', () async {
      const saved = ReaderSettings(
        fontFamily: 'Merriweather',
        fontSize: 22,
        lineHeight: 1.9,
        textAlignment: TextAlignment.justify,
      );
      SharedPreferences.setMockInitialValues({
        AppConstants.prefKeyReaderDefaults: jsonEncode(saved.toJson()),
      });

      final notifier = ReaderSettingsNotifier();
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.fontFamily, 'Merriweather');
      expect(notifier.state.fontSize, 22);
      expect(notifier.state.lineHeight, 1.9);
      expect(notifier.state.textAlignment, TextAlignment.justify);
    });

    test('persists updates to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = ReaderSettingsNotifier();
      await Future<void>.delayed(Duration.zero);

      notifier.setFontSize(18);
      await Future<void>.delayed(Duration.zero);

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.prefKeyReaderDefaults);
      expect(raw, isNotNull);
      final restored = ReaderSettings.fromJson(
        jsonDecode(raw!) as Map<String, dynamic>,
      );
      expect(restored.fontSize, 18);
    });
  });
}
