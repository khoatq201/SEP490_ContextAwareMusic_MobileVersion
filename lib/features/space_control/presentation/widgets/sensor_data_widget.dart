import 'package:flutter/material.dart';
import '../../../../core/theme/cams_theme_tokens.dart';
import '../../domain/entities/sensor_data.dart';

class SensorDataWidget extends StatelessWidget {
  final SensorData? sensorData;
  final bool isOffline;

  const SensorDataWidget({
    super.key,
    this.sensorData,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    if (sensorData == null) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Text(
              'No sensor data available',
              style: TextStyle(color: tokens.textSecondary),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sensor Data',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SensorCard(
                icon: Icons.thermostat,
                label: 'Temperature',
                value: '${sensorData!.temperature.toStringAsFixed(1)}°C',
                color: tokens.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SensorCard(
                icon: Icons.volume_up,
                label: 'Noise Level',
                value: '${sensorData!.noiseLevel.toStringAsFixed(0)} dB',
                color: tokens.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SensorCard(
                icon: Icons.water_drop,
                label: 'Humidity',
                value: '${sensorData!.humidity.toStringAsFixed(0)}%',
                color: tokens.techAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SensorCard(
                icon: Icons.light_mode,
                label: 'Light Level',
                value: sensorData!.lightLevel != null
                    ? '${sensorData!.lightLevel!.toStringAsFixed(0)} lux'
                    : 'N/A',
                color: tokens.moodEnergetic,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SensorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SensorCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.camsTokens.textSecondary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
