import 'package:flutter/foundation.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:textara/core/constants/app_constants.dart';

/// Controls application-scoped screen brightness for the reader.
///
/// Uses [screen_brightness] so Android does not need `WRITE_SETTINGS`.
/// All platform failures are swallowed so unit tests and unsupported
/// desktops keep working.
abstract class BrightnessService {
  Future<void> apply(double brightness);
  Future<void> reset();
}

class ScreenBrightnessService implements BrightnessService {
  ScreenBrightnessService({ScreenBrightness? plugin})
      : _plugin = plugin ?? ScreenBrightness.instance;

  final ScreenBrightness _plugin;

  @override
  Future<void> apply(double brightness) async {
    final clamped = brightness.clamp(
      AppConstants.minReaderBrightness,
      AppConstants.maxReaderBrightness,
    );
    try {
      await _plugin.setApplicationScreenBrightness(clamped);
    } catch (error, stackTrace) {
      debugPrint('BrightnessService.apply failed: $error\n$stackTrace');
    }
  }

  @override
  Future<void> reset() async {
    try {
      await _plugin.resetApplicationScreenBrightness();
    } catch (error, stackTrace) {
      debugPrint('BrightnessService.reset failed: $error\n$stackTrace');
    }
  }
}

/// Used in tests and as a safe fallback when the plugin is unavailable.
class NoOpBrightnessService implements BrightnessService {
  double? lastApplied;

  @override
  Future<void> apply(double brightness) async {
    lastApplied = brightness;
  }

  @override
  Future<void> reset() async {
    lastApplied = null;
  }
}
