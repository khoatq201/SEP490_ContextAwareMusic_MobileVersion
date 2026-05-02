import 'package:flutter/material.dart';

import '../../../../core/theme/cams_theme_tokens.dart';

class MoodColorHelper {
  const MoodColorHelper._();

  static LinearGradient gradientFor(String? mood, CamsThemeTokens tokens) {
    final key = mood?.trim().toLowerCase() ?? '';
    final colors = switch (key) {
      'calm' || 'chill' || 'relax' || 'relaxed' => [
          tokens.moodCalm,
          tokens.moodSocial,
        ],
      'energetic' || 'energy' => [tokens.moodEnergetic, tokens.warning],
      'focus' || 'focused' => [tokens.moodFocus, tokens.techAccent],
      'social' => [tokens.moodSocial, tokens.moodCalm],
      'romantic' => [tokens.moodRomantic, tokens.moodUplifting],
      'uplifting' || 'happy' => [
          tokens.moodUplifting,
          tokens.moodEnergetic,
        ],
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
