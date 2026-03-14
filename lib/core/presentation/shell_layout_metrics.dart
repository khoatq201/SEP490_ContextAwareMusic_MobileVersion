import 'package:flutter/material.dart';

import '../constants/app_dimensions.dart';

class ShellLayoutMetrics {
  const ShellLayoutMetrics._();

  static const double miniPlayerHeight = 72.0;
  static const double safeBottomFallback = 32.0;

  static double safeBottom(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;
    return bottom > 0 ? bottom : safeBottomFallback;
  }

  static double reservedBottom(
    BuildContext context, {
    required bool hasMiniPlayer,
    double extra = 0,
  }) {
    final miniPlayerOffset = hasMiniPlayer ? miniPlayerHeight : 0.0;
    return AppDimensions.bottomNavHeight +
        safeBottom(context) +
        miniPlayerOffset +
        extra;
  }
}
