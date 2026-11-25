import 'package:flutter/widgets.dart';
import 'package:textara/core/constants/app_constants.dart';

/// True when the window should use the two-pane library/reader and
/// threads list/detail layouts.
bool isTextaraTablet(Size size) =>
    size.shortestSide >= AppConstants.tabletShortestSide;
