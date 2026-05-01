import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../moods/data/datasources/mood_remote_datasource.dart';
import '../../../moods/data/models/mood_model.dart';
import '../../../playlists/data/datasources/playlist_remote_datasource.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/playlist_entity.dart';
import '../../domain/entities/sensor_entity.dart';

/// Datasource that fetches real data from Moods + Playlists APIs
/// and maps them into Home domain entities.
abstract class HomeRemoteDataSource {
  Future<List<SensorEntity>> getSensorData({
    String? storeId,
    String? spaceId,
  });
  Future<List<CategoryEntity>> getCategories();
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  final MoodRemoteDataSource moodDataSource;
  final PlaylistRemoteDataSource playlistDataSource;
  final DioClient dioClient;

  HomeRemoteDataSourceImpl({
    required this.moodDataSource,
    required this.playlistDataSource,
    required this.dioClient,
  });

  @override
  Future<List<SensorEntity>> getSensorData({
    String? storeId,
    String? spaceId,
  }) async {
    if (storeId == null || storeId.trim().isEmpty) {
      return const [];
    }

    try {
      final response = await dioClient.get(
        ApiConstants.storeContextLogs(storeId),
        queryParameters: {
          'page': 1,
          'pageSize': 20,
          if (spaceId != null && spaceId.trim().isNotEmpty) 'spaceId': spaceId,
        },
      );
      final latest = _latestContextLog(response.data);
      if (latest == null) return const [];

      final sensors = <SensorEntity>[];
      if (latest.crowdDensity != null) {
        sensors.add(
          SensorEntity(
            id: 'sensor-crowd',
            name: 'Crowd',
            value: latest.crowdDensity!.toString(),
            icon: Icons.people_outline,
            accentColor: const Color(0xFFA78BFA),
            badge: 'Live',
          ),
        );
      }
      if (latest.avgNoise != null) {
        sensors.add(
          SensorEntity(
            id: 'sensor-noise',
            name: 'Noise',
            value: '${latest.avgNoise!.toStringAsFixed(1)} dB',
            icon: Icons.volume_up_outlined,
            accentColor: const Color(0xFF34D399),
            badge: 'Live',
          ),
        );
      }
      return sensors;
    } catch (_) {
      return const [];
    }
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

      // 4. Add a complete catalog section before mood-specific sections.
      if (allPlaylists.isNotEmpty) {
        categories.insert(
          0,
          CategoryEntity(
            id: 'cat-all',
            title: 'All Playlists',
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
          ),
        );
      }

      return categories;
    } catch (e) {
      throw ServerException('Failed to fetch home categories: $e');
    }
  }
}

_HomeContextLog? _latestContextLog(dynamic responseData) {
  final page = responseData is Map<String, dynamic> &&
          responseData['data'] is Map<String, dynamic>
      ? responseData['data'] as Map<String, dynamic>
      : responseData;
  final rawItems = <dynamic>[
    if (page is Map<String, dynamic>)
      ...(page['items'] as List<dynamic>? ?? [])
    else if (page is List)
      ...page,
  ];

  _HomeContextLog? latest;
  for (final raw in rawItems) {
    if (raw is! Map) continue;
    final log = _HomeContextLog.fromJson(Map<String, dynamic>.from(raw));
    if (!log.hasDisplayData) continue;
    if (latest == null || log.isNewerThan(latest)) {
      latest = log;
    }
  }
  return latest;
}

class _HomeContextLog {
  const _HomeContextLog({
    this.measuredAtUtc,
    this.avgNoise,
    this.crowdDensity,
  });

  final DateTime? measuredAtUtc;
  final double? avgNoise;
  final int? crowdDensity;

  bool get hasDisplayData => avgNoise != null || crowdDensity != null;

  bool isNewerThan(_HomeContextLog other) {
    final current = measuredAtUtc;
    final previous = other.measuredAtUtc;
    if (current == null) return previous == null;
    if (previous == null) return true;
    return current.isAfter(previous);
  }

  factory _HomeContextLog.fromJson(Map<String, dynamic> json) {
    return _HomeContextLog(
      measuredAtUtc: _readDateTime(json, 'measuredAtUtc'),
      avgNoise: _readNum(json, 'avgNoise')?.toDouble(),
      crowdDensity: _readNum(json, 'crowdDensity')?.round(),
    );
  }
}

dynamic _readValue(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) return json[key];
  if (key.isEmpty) return null;
  final pascalCaseKey = '${key[0].toUpperCase()}${key.substring(1)}';
  return json[pascalCaseKey];
}

num? _readNum(Map<String, dynamic> json, String key) {
  final value = _readValue(json, key);
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

DateTime? _readDateTime(Map<String, dynamic> json, String key) {
  final value = _readValue(json, key);
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
