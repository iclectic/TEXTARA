import 'dart:math' as math;

import 'package:flutter/material.dart';

/// WCAG-style relative luminance / contrast helpers for theme gates.
class ColorContrast {
  ColorContrast._();

  /// Relative luminance per WCAG 2.x (sRGB).
  static double relativeLuminance(Color color) {
    double channel(double c) {
      final v = c;
      return v <= 0.04045
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = channel(color.r);
    final g = channel(color.g);
    final b = channel(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Contrast ratio of [foreground] on [background] (1.0–21.0).
  static double ratio(Color foreground, Color background) {
    final l1 = relativeLuminance(foreground);
    final l2 = relativeLuminance(background);
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// WCAG AA for normal text is 4.5:1; large text is 3:1.
  static bool meetsAa(
    Color foreground,
    Color background, {
    double minimum = 4.5,
  }) {
    return ratio(foreground, background) >= minimum;
  }
}
