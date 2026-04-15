import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// CAMS logo lockup inspired by the provided login mockup.
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
    final accent = isDark ? AppColors.primaryCyan : AppColors.primaryOrange;
    final accentDark =
        isDark ? AppColors.primaryCyanBright : AppColors.secondaryTealDark;
    final accentLight =
        isDark ? AppColors.primaryCyanMuted : AppColors.primaryOrangeLight;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _CAMSLogoPainter(
              accent: accent,
              accentDark: accentDark,
              accentLight: accentLight,
            ),
          ),
          Transform.translate(
            offset: Offset(size * 0.015, size * 0.02),
            child: Icon(
              Icons.music_note_rounded,
              color: accentDark,
              size: size * 0.34,
            ),
          ),
        ],
      ),
    );
  }
}

class _CAMSLogoPainter extends CustomPainter {
  final Color accent;
  final Color accentDark;
  final Color accentLight;

  _CAMSLogoPainter({
    required this.accent,
    required this.accentDark,
    required this.accentLight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final arcRadius = size.width * 0.29;

    final darkArcPaint = Paint()
      ..color = accentDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.082
      ..strokeCap = StrokeCap.round;

    final accentPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.048
      ..strokeCap = StrokeCap.round;

    final lightPaint = Paint()
      ..color = accentLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.036
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcRadius),
      0.72,
      4.92,
      false,
      darkArcPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.37),
      -1.16,
      1.36,
      false,
      accentPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.31),
      0.84,
      1.46,
      false,
      accentPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.19),
      -1.18,
      1.02,
      false,
      lightPaint,
    );

    _drawWaveBars(
      canvas: canvas,
      center: center,
      size: size,
      isLeft: true,
    );
    _drawWaveBars(
      canvas: canvas,
      center: center,
      size: size,
      isLeft: false,
    );
  }

  void _drawWaveBars({
    required Canvas canvas,
    required Offset center,
    required Size size,
    required bool isLeft,
  }) {
    final direction = isLeft ? -1.0 : 1.0;
    final xBase = center.dx + direction * size.width * 0.39;

    final barSpecs = [
      (height: size.width * 0.13, offset: 0.0, width: size.width * 0.03),
      (
        height: size.width * 0.22,
        offset: size.width * 0.085,
        width: size.width * 0.042
      ),
      (
        height: size.width * 0.13,
        offset: size.width * 0.17,
        width: size.width * 0.03
      ),
    ];

    final colors = [accent, accentDark, accentLight];

    for (var index = 0; index < barSpecs.length; index++) {
      final spec = barSpecs[index];
      final paint = Paint()
        ..color = colors[index]
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = spec.width;

      final x = xBase + (spec.offset * direction);
      final top = center.dy - (spec.height / 2);
      final bottom = center.dy + (spec.height / 2);
      canvas.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        paint,
      );
    }

    final dotPaint = Paint()
      ..color = accentLight
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(
        center.dx + direction * size.width * 0.64,
        center.dy,
      ),
      size.width * 0.018,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
