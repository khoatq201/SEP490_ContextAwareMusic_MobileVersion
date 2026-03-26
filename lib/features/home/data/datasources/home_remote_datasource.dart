import 'package:flutter/material.dart';
import '../../../../core/error/exceptions.dart';
import '../../../moods/data/datasources/mood_remote_datasource.dart';
import '../../../moods/data/models/mood_model.dart';
import '../../../playlists/data/datasources/playlist_remote_datasource.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/entities/sensor_entity.dart';

/// Datasource that fetches real data from Moods + Playlists APIs
/// and maps them into Home domain entities.
abstract class HomeRemoteDataSource {
  Future<List<SensorEntity>> getSensorData();
  Future<List<CategoryEntity>> getCategories();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final MoodRemoteDataSource moodDataSource;
  final PlaylistRemoteDataSource playlistDataSource;

  HomeRemoteDataSourceImpl({
    required this.moodDataSource,
    required this.playlistDataSource,
  });

  @override
  Future<List<SensorEntity>> getSensorData() async {
    // Sensor data comes from IoT / MQTT — no REST endpoint yet.
    // Return placeholder sensors until backend provides this.
    return const [
      SensorEntity(
        id: 'sensor-temp',
        name: 'Temperature',
        value: '--',
        icon: Icons.thermostat_outlined,
        accentColor: Color(0xFFF97316),
        badge: 'N/A',
      ),
      SensorEntity(
        id: 'sensor-humidity',
        name: 'Humidity',
        value: '--',
        icon: Icons.water_drop_outlined,
        accentColor: Color(0xFF38BDF8),
        badge: 'N/A',
      ),
      SensorEntity(
        id: 'sensor-crowd',
        name: 'Crowd Level',
        value: '--',
        icon: Icons.people_outline,
        accentColor: Color(0xFFA78BFA),
        badge: 'N/A',
      ),
      SensorEntity(
        id: 'sensor-noise',
        name: 'Noise Level',
        value: '--',
        icon: Icons.volume_up_outlined,
        accentColor: Color(0xFF34D399),
        badge: 'N/A',
      ),
    ];
  }

  @override
  Future<List<CategoryEntity>> getCategories() async {
    try {
      // 1. Fetch first page of playlists (enough for the home dashboard)
      final playlistResponse = await playlistDataSource.getPlaylists(
        page: 1,
        pageSize: 50,
      );

      final allPlaylists = playlistResponse.items;
      final categories = <CategoryEntity>[];
      List<MoodModel> moods = const [];

      // 2. Moods are optional for Home. Playback-device sessions may not be
      // authorized to read /api/moods, so we gracefully fall back to generic
      // playlist buckets instead of hiding the entire catalog.
      try {
        moods = await moodDataSource.getMoods();
      } catch (_) {
        moods = const [];
      }

      // 3. Group playlists by mood when reference data is available
      for (final mood in moods) {
        final moodPlaylists =
            allPlaylists.where((p) => p.moodId == mood.id).toList();

        if (moodPlaylists.isEmpty) continue;

        categories.add(CategoryEntity(
          id: mood.id,
          title: mood.name,
          playlists: moodPlaylists
              .map((p) => PlaylistEntity(
                    id: p.id,
                    title: p.name,
                    description: p.description,
                    coverUrl: null, // API playlists don't have cover images
                    songs: const [], // Tracks loaded on demand in detail page
                    overrideTrackCount: p.trackCount,
                  ))
              .toList(),
        ));
      }

      // 4. Add "All Playlists" category for playlists without mood
      final unmoodedPlaylists = allPlaylists
          .where((p) => p.moodId == null || p.moodId!.isEmpty)
          .toList();

      if (unmoodedPlaylists.isNotEmpty) {
        categories.insert(
          0,
          CategoryEntity(
            id: 'cat-all',
            title: 'All Playlists',
            playlists: unmoodedPlaylists
                .map((p) => PlaylistEntity(
                      id: p.id,
                      title: p.name,
                      description: p.description,
                      coverUrl: null,
                      songs: const [],
                      overrideTrackCount: p.trackCount,
                    ))
                .toList(),
          ),
        );
      }

      // 5. If no categories at all, add a single "Browse" category
      if (categories.isEmpty && allPlaylists.isNotEmpty) {
        categories.add(CategoryEntity(
          id: 'cat-browse',
          title: 'Browse Playlists',
          playlists: allPlaylists
              .map((p) => PlaylistEntity(
                    id: p.id,
                    title: p.name,
                    description: p.description,
                    coverUrl: null,
                    songs: const [],
                    overrideTrackCount: p.trackCount,
                  ))
              .toList(),
        ));
      }

      return categories;
    } catch (e) {
      throw ServerException('Failed to fetch home categories: $e');
    }
  }
}
