import 'package:flutter/material.dart';

class MoodDisplayWidget extends StatelessWidget {
  final String? mood;
  final bool isOffline;

  const MoodDisplayWidget({
    Key? key,
    this.mood,
    required this.isOffline,
  }) : super(key: key);

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

  Color _getMoodColor(String? mood) {
    switch (mood?.toLowerCase()) {
      case 'happy':
        return Colors.yellow.shade700;
      case 'chill':
        return Colors.blue.shade400;
      case 'energetic':
        return Colors.orange.shade700;
      case 'romantic':
        return Colors.pink.shade400;
      case 'focus':
        return Colors.purple.shade400;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark
              ? _getMoodColor(mood).withOpacity(0.1)
              : _getMoodColor(mood).withOpacity(0.05),
        ),
        child: Column(
          children: [
            Icon(
              _getMoodIcon(mood),
              size: 80,
              color: _getMoodColor(mood),
            ),
            const SizedBox(height: 16),
            Text(
              mood ?? 'No Mood',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getMoodColor(mood),
                  ),
            ),
            const SizedBox(height: 8),
            if (isOffline)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.offline_bolt,
                      size: 16,
                      color: Colors.orange.shade900,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Playing from Local Cache',
                      style: TextStyle(
                        color: Colors.orange.shade900,
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
