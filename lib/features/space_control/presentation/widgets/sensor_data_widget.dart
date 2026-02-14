import 'package:flutter/material.dart';
import '../../domain/entities/sensor_data.dart';

class SensorDataWidget extends StatelessWidget {
  final SensorData? sensorData;
  final bool isOffline;

  const SensorDataWidget({
    Key? key,
    this.sensorData,
    required this.isOffline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (sensorData == null) {
      return const Card(
        elevation: 2,
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: Text('No sensor data available'),
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
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SensorCard(
                icon: Icons.volume_up,
                label: 'Noise Level',
                value: '${sensorData!.noiseLevel.toStringAsFixed(0)} dB',
                color: Colors.orange,
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
                color: Colors.blue,
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
                color: Colors.amber,
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
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

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
                    color: Colors.grey.shade600,
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
