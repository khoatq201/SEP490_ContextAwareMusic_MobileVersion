import 'package:flutter/material.dart';

import '../../../../core/theme/cams_theme_tokens.dart';

class MoodColorHelper {
  const MoodColorHelper._();

  static LinearGradient gradientFor(String? mood, CamsThemeTokens tokens) {
    final key = mood?.trim().toLowerCase() ?? '';
    final colors = switch (key) {
      'energetic' => [tokens.moodEnergetic, tokens.success],
      'chill' => [tokens.moodChill, tokens.techAccent],
      'focus' => [tokens.moodFocus, tokens.techAccent],
      'happy' => [tokens.moodDefault, tokens.moodEnergetic],
      _ => [tokens.textTertiary, tokens.borderSecondary],
    };
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }

  static Color shadowColorFor(String? mood, CamsThemeTokens tokens) {
    final gradient = gradientFor(mood, tokens);
    return gradient.colors.first.withValues(alpha: 0.35);
  }
}
