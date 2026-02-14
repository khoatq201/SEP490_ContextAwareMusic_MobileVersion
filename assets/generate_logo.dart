import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

// Script to generate placeholder logo PNG
// Run: dart run assets/generate_logo.dart

void main() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // Background
  final paint = Paint()..color = const Color(0xFF1976D2);
  canvas.drawCircle(const Offset(256, 256), 230, paint);

  // White circle border
  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8;
  canvas.drawCircle(const Offset(256, 256), 200, borderPaint);

  // Text CAMS
  final textPainter = TextPainter(
    text: const TextSpan(
      text: 'CAMS',
      style: TextStyle(
        color: Colors.white,
        fontSize: 80,
        fontWeight: FontWeight.bold,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  textPainter.layout();
  textPainter.paint(canvas, const Offset(145, 210));

  // Subtitle
  final subtitlePainter = TextPainter(
    text: const TextSpan(
      text: 'Store Manager',
      style: TextStyle(
        color: Color(0xFFBBDEFB),
        fontSize: 24,
      ),
    ),
    textDirection: TextDirection.ltr,
  );
  subtitlePainter.layout();
  subtitlePainter.paint(canvas, const Offset(160, 300));

  final picture = recorder.endRecording();
  final img = await picture.toImage(512, 512);
  final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

  print('Logo generated! Save this as splash_logo.png');
}
