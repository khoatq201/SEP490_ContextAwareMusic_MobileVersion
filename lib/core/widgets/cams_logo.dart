import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// CAMS Logo Widget - Blue themed logo with concentric circles,
/// central music note, and orbiting sensor nodes.
/// Theme-aware: Blue for light mode, Cyan for dark mode
class CAMSLogo extends StatelessWidget {
  final double size;
  final bool animated;

  const CAMSLogo({
    super.key,
    this.size = 200,
    this.animated = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.primaryCyan : AppColors.primaryOrange;
    final primaryLight =
        isDark ? AppColors.primaryCyanBright : AppColors.primaryOrangeLight;
    final primaryPale =
        isDark ? AppColors.primaryCyanMuted : AppColors.primaryOrangePale;

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoConnectionsPainter(
          primaryPale: primaryPale,
          nodePositions: _getNodePositions(),
          size: size,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Concentric orbit circles (blue rings)
            ...List.generate(3, (index) {
              final circleSize = size * (0.88 - (index * 0.17));
              final opacity = 0.25 + (index * 0.12);
              return Container(
                width: circleSize,
                height: circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryLight.withOpacity(opacity),
                    width: 1.5 + (index * 0.3),
                  ),
                ),
              );
            }),

            // Central circle with gradient and music note
            Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: const Alignment(-0.2, -0.3),
                  colors: [
                    primaryLight,
                    primaryColor,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.35),
                    blurRadius: size * 0.06,
                    spreadRadius: size * 0.01,
                  ),
                ],
              ),
              child: Icon(
                Icons.music_note_rounded,
                color: Colors.white,
                size: size * 0.18,
              ),
            ),

            // Three sensor nodes orbiting around
            ..._buildSensorNodes(context),

            // Small decorative dots on orbits
            ..._buildDecorativeDots(primaryPale),
          ],
        ),
      ),
    );
  }

  /// Returns relative positions for the 3 sensor nodes
  List<Offset> _getNodePositions() {
    return const [
      Offset(0.8, -0.55), // top right
      Offset(-0.72, -0.35), // left
      Offset(-0.28, 0.88), // bottom left
    ];
  }

  List<Widget> _buildSensorNodes(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.primaryCyan : AppColors.primaryOrange;
    final primaryLight =
        isDark ? AppColors.primaryCyanBright : AppColors.primaryOrangeLight;
    final primaryPale =
        isDark ? AppColors.primaryCyanMuted : AppColors.primaryOrangePale;

    final nodeSizes = [size * 0.15, size * 0.12, size * 0.10];
    final radius = size * 0.45;
    final positions = _getNodePositions();

    return List.generate(3, (index) {
      final nodeSize = nodeSizes[index];
      final x = radius * positions[index].dx;
      final y = radius * positions[index].dy;

      return Positioned(
        left: (size / 2) + x - (nodeSize / 2),
        top: (size / 2) + y - (nodeSize / 2),
        child: Container(
          width: nodeSize,
          height: nodeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.2, -0.3),
              colors: [
                primaryLight,
                primaryColor,
              ],
            ),
            border: Border.all(
              color: primaryPale,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.25),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
          child: index < 3
              ? Icon(
                  _getSensorIcon(index),
                  color: Colors.white,
                  size: nodeSize * 0.5,
                )
              : null,
        ),
      );
    });
  }

  List<Widget> _buildDecorativeDots(Color color) {
    final dotData = [
      {'x': 0.92, 'y': 0.05, 'r': 3.0, 'o': 0.5},
      {'x': 0.08, 'y': 0.6, 'r': 2.5, 'o': 0.4},
      {'x': 0.72, 'y': 0.88, 'r': 2.0, 'o': 0.35},
    ];

    return dotData.map((dot) {
      return Positioned(
        left: size * (dot['x'] as double) - (dot['r'] as double),
        top: size * (dot['y'] as double) - (dot['r'] as double),
        child: Container(
          width: (dot['r'] as double) * 2,
          height: (dot['r'] as double) * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(dot['o'] as double),
          ),
        ),
      );
    }).toList();
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
}

/// Custom painter to draw connection lines from sensor nodes to center
class _LogoConnectionsPainter extends CustomPainter {
  final Color primaryPale;
  final List<Offset> nodePositions;
  final double size;

  _LogoConnectionsPainter({
    required this.primaryPale,
    required this.nodePositions,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(size / 2, size / 2);
    final radius = size * 0.45;

    final paint = Paint()
      ..color = primaryPale.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final pos in nodePositions) {
      final nodeCenter = Offset(
        center.dx + radius * pos.dx,
        center.dy + radius * pos.dy,
      );
      canvas.drawLine(center, nodeCenter, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
