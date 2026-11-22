import 'package:flutter/material.dart';
import 'package:textara/core/constants/app_constants.dart';

/// Design tokens for spacing, radius, elevation, and motion.
class LeafTokens {
  LeafTokens._();

  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  static const double elevationNone = 0;
  static const double elevationLow = 2;

  static const Duration motionFast = AppConstants.animationFast;
  static const Duration motionNormal = AppConstants.animationNormal;
  static const Duration motionSlow = AppConstants.animationSlow;

  static Duration motion(
    BuildContext context, {
    Duration preferred = motionNormal,
    bool forceReduce = false,
  }) {
    final media = MediaQuery.maybeOf(context);
    final systemReduce = media?.disableAnimations ?? false;
    if (forceReduce || systemReduce) {
      return Duration.zero;
    }
    return preferred;
  }

  static Curve curve(bool reduced) =>
      reduced ? Curves.linear : Curves.easeOutCubic;
}
