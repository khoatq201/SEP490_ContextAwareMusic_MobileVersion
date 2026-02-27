import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_constants.dart';
import '../bloc/music_control_bloc.dart';
import '../bloc/music_control_event.dart';

class ManualOverrideWidget extends StatelessWidget {
  final String spaceId;
  final String? currentMood;

  const ManualOverrideWidget({
    super.key,
    required this.spaceId,
    this.currentMood,
  });

  void _showOverrideDialog(BuildContext context) {
    String selectedMood = currentMood ?? AppConstants.availableMoods.first;
    int duration = AppConstants.defaultOverrideDuration;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Manual Override'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select a mood to override the current automatic selection:',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedMood,
                decoration: const InputDecoration(
                  labelText: 'Mood',
                  border: OutlineInputBorder(),
                ),
                items: AppConstants.availableMoods.map((mood) {
                  return DropdownMenuItem(
                    value: mood,
                    child: Row(
                      children: [
                        _getMoodIcon(mood),
                        const SizedBox(width: 8),
                        Text(mood),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedMood = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: duration.toString(),
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                  border: OutlineInputBorder(),
                  suffixText: 'min',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  duration = int.tryParse(value) ??
                      AppConstants.defaultOverrideDuration;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                context.read<MusicControlBloc>().add(
                      OverrideMoodRequested(
                        spaceId: spaceId,
                        moodId: selectedMood.toLowerCase(),
                        duration: duration,
                      ),
                    );
                Navigator.of(dialogContext).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Mood overridden to $selectedMood for $duration minutes'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Icon _getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return const Icon(Icons.sentiment_very_satisfied, color: Colors.amber);
      case 'chill':
        return const Icon(Icons.spa, color: Colors.blue);
      case 'energetic':
        return const Icon(Icons.bolt, color: Colors.orange);
      case 'romantic':
        return const Icon(Icons.favorite, color: Colors.pink);
      case 'focus':
        return const Icon(Icons.psychology, color: Colors.purple);
      default:
        return const Icon(Icons.mood, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manual Override',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Override the automatic mood selection and choose your preferred atmosphere.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showOverrideDialog(context),
                icon: const Icon(Icons.tune),
                label: const Text('Override Mood'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
