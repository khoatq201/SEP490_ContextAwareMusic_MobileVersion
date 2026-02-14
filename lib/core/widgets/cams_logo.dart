import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// CAMS Logo Widget - Recreates the logo design using Flutter widgets
/// Theme-aware: Orange+Teal for light mode, Cyan+Lime for dark mode
class CAMSLogo extends StatelessWidget {
  final double size;
  final bool animated;

  const CAMSLogo({
    Key? key,
    this.size = 200,
    this.animated = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.primaryCyan : AppColors.primaryOrange;
    final secondaryColor =
        isDark ? AppColors.secondaryLime : AppColors.secondaryTeal;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric circles (Orange for light, Cyan for dark)
          ...List.generate(3, (index) {
            final circleSize = size * (0.9 - (index * 0.15));
            return Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withOpacity(0.6 - (index * 0.1)),
                  width: 2,
                ),
              ),
            );
          }),

          // Central circle with music note (Teal for light, Lime for dark)
          Container(
            width: size * 0.35,
            height: size * 0.35,
            decoration: BoxDecoration(
              color: secondaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.music_note,
              color: isDark ? AppColors.backgroundDarkPrimary : Colors.white,
              size: size * 0.2,
            ),
          ),

          // Three sensor nodes (positioned around the circles)
          ..._buildSensorNodes(context),

          // Connecting lines (optional)
          if (animated) ..._buildConnectingLines(),
        ],
      ),
    );
  }

  List<Widget> _buildSensorNodes(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor =
        isDark ? AppColors.secondaryLime : AppColors.secondaryTeal;
    final secondaryLight =
        isDark ? AppColors.secondaryLimeBright : AppColors.secondaryTealLight;

    final nodeSize = size * 0.15;
    final radius = size * 0.45;

    return List.generate(3, (index) {
      final x = radius *
          (index == 0
              ? 0.8
              : index == 1
                  ? -0.8
                  : -0.3);
      final y = radius *
          (index == 0
              ? -0.6
              : index == 1
                  ? -0.3
                  : 0.9);

      return Positioned(
        left: (size / 2) + x - (nodeSize / 2),
        top: (size / 2) + y - (nodeSize / 2),
        child: Container(
          width: nodeSize,
          height: nodeSize,
          decoration: BoxDecoration(
            color:
                index == 0 ? secondaryLight : secondaryColor.withOpacity(0.8),
            shape: BoxShape.circle,
            border: Border.all(
              color: secondaryColor,
              width: 2,
            ),
          ),
          child: Icon(
            _getSensorIcon(index),
            color: isDark ? AppColors.backgroundDarkPrimary : Colors.white,
            size: nodeSize * 0.5,
          ),
        ),
      );
    });
  }

  IconData _getSensorIcon(int index) {
    switch (index) {
      case 0:
        return Icons.thermostat_outlined;
      case 1:
        return Icons.people_outline;
      case 2:
        return Icons.graphic_eq;
      default:
        return Icons.sensors;
    }
  }

  List<Widget> _buildConnectingLines() {
    // This would require CustomPaint for precise lines
    // Simplified version - could be enhanced with CustomPainter
    return [];
  }
}
