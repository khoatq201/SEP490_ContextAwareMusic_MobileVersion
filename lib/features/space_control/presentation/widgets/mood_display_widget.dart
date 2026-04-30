import 'package:flutter/material.dart';

import '../../../../core/theme/cams_theme_tokens.dart';

class MoodDisplayWidget extends StatelessWidget {
  final String? mood;
  final bool isOffline;

  const MoodDisplayWidget({
    super.key,
    this.mood,
    required this.isOffline,
  });

  IconData _getMoodIcon(String? mood) {
    switch (mood?.toLowerCase()) {
      case 'happy':
        return Icons.sentiment_very_satisfied;
      case 'chill':
        return Icons.spa;
      case 'energetic':
        return Icons.bolt;
      case 'romantic':
        return Icons.favorite;
      case 'focus':
        return Icons.psychology;
      default:
        return Icons.mood;
    }
  }

  Color _getMoodColor(String? mood, CamsThemeTokens tokens) {
    switch (mood?.toLowerCase()) {
      case 'happy':
        return tokens.warning;
      case 'chill':
        return tokens.moodChill;
      case 'energetic':
        return tokens.moodEnergetic;
      case 'romantic':
        return tokens.brandPrimaryHover;
      case 'focus':
        return tokens.moodFocus;
      default:
        return tokens.moodDefault;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = context.camsTokens;
    final moodColor = _getMoodColor(mood, tokens);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: moodColor.withValues(alpha: isDark ? 0.1 : 0.05),
        ),
        child: Column(
          children: [
            Icon(
              _getMoodIcon(mood),
              size: 80,
              color: moodColor,
            ),
            const SizedBox(height: 16),
            Text(
              mood ?? 'No Mood',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: moodColor,
                  ),
            ),
            const SizedBox(height: 8),
            if (isOffline)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tokens.alertWarningBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.offline_bolt,
                      size: 16,
                      color: tokens.warning,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Playing from Local Cache',
                      style: TextStyle(
                        color: tokens.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
