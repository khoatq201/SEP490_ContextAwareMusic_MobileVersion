import 'package:flutter/material.dart';

class MoodColorHelper {
  const MoodColorHelper._();

  static LinearGradient gradientFor(String? mood) {
    final key = mood?.trim().toLowerCase() ?? '';
    switch (key) {
      case 'energetic':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD54F), Color(0xFF00E676)],
        );
      case 'chill':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF22D3EE)],
        );
      case 'focus':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF14B8A6), Color(0xFF10B981)],
        );
      case 'happy':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF472B6), Color(0xFFF59E0B)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4B5563), Color(0xFF6B7280)],
        );
    }
  }

  static Color shadowColorFor(String? mood) {
    final gradient = gradientFor(mood);
    return gradient.colors.first.withOpacity(0.35);
  }
}
