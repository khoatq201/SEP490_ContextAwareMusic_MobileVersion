import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../../music_policy/data/models/fuzzy_override_profile_request.dart';
import '../models/space_summary_model.dart';
import '../models/store_model.dart';

abstract class StoreRemoteDataSource {
  Future<StoreModel> getStoreDetails(String storeId);
  Future<List<SpaceSummaryModel>> getSpaceSummaries(String storeId);
  Future<StoreMutationResult> createStore(StoreMutationRequest request);
  Future<StoreMutationResult> updateStore(
    String storeId,
    StoreMutationRequest request,
  );
  Future<StoreMutationResult> deleteStore(String storeId);
  Future<StoreMutationResult> toggleStoreStatus(String storeId);
  Future<StoreMutationResult> createFuzzyOverrideProfile(
    String storeId,
    FuzzyOverrideProfileRequest request,
  );
}

class StoreMutationRequest {
  final String? name;
  final String? contactNumber;
  final String? address;
  final String? city;
  final String? district;
  final double? latitude;
  final double? longitude;
  final String? mapUrl;
  final String? timeZone;
  final double? areaSquareMeters;
  final int? maxCapacity;
  final String? firestoreCollectionPath;

  const StoreMutationRequest({
    this.name,
    this.contactNumber,
    this.address,
    this.city,
    this.district,
    this.latitude,
    this.longitude,
    this.mapUrl,
    this.timeZone,
    this.areaSquareMeters,
    this.maxCapacity,
    this.firestoreCollectionPath,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
      if (contactNumber != null && contactNumber!.trim().isNotEmpty)
        'contactNumber': contactNumber!.trim(),
      if (address != null && address!.trim().isNotEmpty)
        'address': address!.trim(),
      if (city != null && city!.trim().isNotEmpty) 'city': city!.trim(),
      if (district != null && district!.trim().isNotEmpty)
        'district': district!.trim(),
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (mapUrl != null && mapUrl!.trim().isNotEmpty) 'mapUrl': mapUrl!.trim(),
      if (timeZone != null && timeZone!.trim().isNotEmpty)
        'timeZone': timeZone!.trim(),
      if (areaSquareMeters != null) 'areaSquareMeters': areaSquareMeters,
      if (maxCapacity != null) 'maxCapacity': maxCapacity,
      if (firestoreCollectionPath != null &&
          firestoreCollectionPath!.trim().isNotEmpty)
        'firestoreCollectionPath': firestoreCollectionPath!.trim(),
    };
  }
}

class StoreMutationResult {
  final bool isSuccess;
  final String? message;
  final String? errorCode;

  const StoreMutationResult({
    required this.isSuccess,
    this.message,
    this.errorCode,
  });

  factory StoreMutationResult.fromJson(Map<String, dynamic> json) {
    return StoreMutationResult(
      isSuccess: json['isSuccess'] as bool? ?? false,
      message: json['message']?.toString(),
      errorCode: json['errorCode']?.toString(),
    );
  }
}

/// Real API implementation of [StoreRemoteDataSource].
class StoreRemoteDataSourceImpl implements StoreRemoteDataSource {
  final DioClient dioClient;

  StoreRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<StoreModel> getStoreDetails(String storeId) async {
    try {
      final response =
          await dioClient.get(ApiConstants.getStoreDetail(storeId));
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        return StoreModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      return StoreModel.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      throw ServerException('Failed to get store details: $e');
    }
  }

  @override
  Future<List<SpaceSummaryModel>> getSpaceSummaries(String storeId) async {
    try {
      final response = await dioClient.get(
        ApiConstants.getSpacesEndpoint,
        queryParameters: {'storeId': storeId},
      );
      final data = response.data;
      final rawItems = <dynamic>[
        if (data is Map<String, dynamic>)
          ...(data['items'] as List<dynamic>? ?? [])
        else if (data is List)
          ...data,
      ];

      final summaries = rawItems
          .map((e) => SpaceSummaryModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final latestTelemetryBySpace = await _getLatestTelemetryBySpace(storeId);

      return Future.wait(
        summaries.map((summary) async {
          final runtimeState = await _getRuntimeFromSpaceState(
            spaceId: summary.id,
            fallbackMood: summary.currentMood,
          );
          final telemetry = _findTelemetryForSpace(
            latestTelemetryBySpace,
            summary,
          );
          return summary.copyWith(
            currentMood: runtimeState.moodName,
            isOnline: runtimeState.isIotDeviceOffline == null
                ? summary.isOnline
                : summary.isOnline && !runtimeState.isIotDeviceOffline!,
            customerCount: telemetry?.crowdDensity,
            noiseLevel: telemetry?.avgNoise,
            isMusicPlaying:
                runtimeState.isMusicPlaying ?? summary.isMusicPlaying,
            currentTrack: runtimeState.currentTrack,
            clearCurrentTrack: runtimeState.hasPlaybackState &&
                (runtimeState.currentTrack?.trim().isEmpty ?? true),
            isManualOverride: runtimeState.isManualOverride,
            isScheduling: runtimeState.isScheduling,
            manualOverrideRemainingSeconds:
                runtimeState.manualOverrideRemainingSeconds,
            schedulingRemainingSeconds: runtimeState.schedulingRemainingSeconds,
          );
        }),
      );
    } catch (e) {
      throw ServerException('Failed to get space summaries: $e');
    }
  }

  @override
  Future<StoreMutationResult> createStore(StoreMutationRequest request) async {
    try {
      final response = await dioClient.post(
        ApiConstants.getStoresEndpoint,
        data: request.toJson(),
      );
      return _parseMutationResult(response.data);
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMessage(e, fallback: 'Failed to create store.'),
      );
    } catch (e) {
      throw ServerException('Failed to create store: $e');
    }
  }

  @override
  Future<StoreMutationResult> updateStore(
    String storeId,
    StoreMutationRequest request,
  ) async {
    try {
      final response = await dioClient.put(
        ApiConstants.updateStore(storeId),
        data: request.toJson(),
      );
      return _parseMutationResult(response.data);
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMessage(e, fallback: 'Failed to update store.'),
      );
    } catch (e) {
      throw ServerException('Failed to update store: $e');
    }
  }

  @override
  Future<StoreMutationResult> deleteStore(String storeId) async {
    try {
      final response =
          await dioClient.delete(ApiConstants.deleteStore(storeId));
      return _parseMutationResult(response.data);
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMessage(e, fallback: 'Failed to delete store.'),
      );
    } catch (e) {
      throw ServerException('Failed to delete store: $e');
    }
  }

  @override
  Future<StoreMutationResult> toggleStoreStatus(String storeId) async {
    try {
      final response =
          await dioClient.put(ApiConstants.toggleStoreStatus(storeId));
      return _parseMutationResult(response.data);
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMessage(
          e,
          fallback: 'Failed to toggle store status.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to toggle store status: $e');
    }
  }

  @override
  Future<StoreMutationResult> createFuzzyOverrideProfile(
    String storeId,
    FuzzyOverrideProfileRequest request,
  ) async {
    try {
      final response = await dioClient.post(
        ApiConstants.storeFuzzyProfiles(storeId),
        data: request.toJson(),
      );
      return _parseMutationResult(response.data);
    } on DioException catch (e) {
      throw ServerException(
        _extractDioErrorMessage(
          e,
          fallback: 'Failed to save store fuzzy override.',
        ),
      );
    } catch (e) {
      throw ServerException('Failed to save store fuzzy override: $e');
    }
  }

  Future<Map<String, _SpaceIotTelemetry>> _getLatestTelemetryBySpace(
    String storeId,
  ) async {
    try {
      final response = await dioClient.get(
        ApiConstants.storeContextLogs(storeId),
        queryParameters: const {
          'page': 1,
          'pageSize': 200,
        },
      );
      final data = response.data;
      final page =
          data is Map<String, dynamic> && data['data'] is Map<String, dynamic>
              ? data['data'] as Map<String, dynamic>
              : data;
      final rawItems = <dynamic>[
        if (page is Map<String, dynamic>)
          ...(page['items'] as List<dynamic>? ?? [])
        else if (page is List)
          ...page,
      ];

      final latestByKey = <String, _SpaceIotTelemetry>{};
      for (final raw in rawItems) {
        if (raw is! Map) continue;
        final telemetry = _SpaceIotTelemetry.fromJson(
          Map<String, dynamic>.from(raw),
        );
        if (!telemetry.hasDisplayData) continue;
        _putLatestTelemetry(latestByKey, telemetry.spaceId, telemetry);
        _putLatestTelemetry(latestByKey, telemetry.spaceName, telemetry);
      }
      return latestByKey;
    } catch (_) {
      // IoT telemetry is helpful but should not block the store dashboard.
      return const {};
    }
  }

  _SpaceIotTelemetry? _findTelemetryForSpace(
    Map<String, _SpaceIotTelemetry> latestByKey,
    SpaceSummaryModel summary,
  ) {
    return latestByKey[_telemetryKey(summary.id)] ??
        latestByKey[_telemetryKey(summary.name)];
  }

  void _putLatestTelemetry(
    Map<String, _SpaceIotTelemetry> latestByKey,
    String? rawKey,
    _SpaceIotTelemetry telemetry,
  ) {
    final key = _telemetryKey(rawKey);
    if (key == null) return;
    final previous = latestByKey[key];
    if (previous == null || telemetry.isNewerThan(previous)) {
      latestByKey[key] = telemetry;
    }
  }

  Future<_SpaceRuntimeSummary> _getRuntimeFromSpaceState({
    required String spaceId,
    required String fallbackMood,
  }) async {
    try {
      final response = await dioClient.get(ApiConstants.camsState(spaceId));
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final payload = data['data'];
        if (payload is Map<String, dynamic>) {
          final normalized = Map<String, dynamic>.from(payload);
          final liveMoodName = await _getLiveSpaceMoodName(spaceId);
          final moodName = liveMoodName ?? _readString(normalized, 'moodName');
          final currentTrack = _readString(normalized, 'currentTrackName') ??
              _readString(normalized, 'currentPlaylistName');
          final hlsUrl = _readString(normalized, 'hlsUrl');
          final currentQueueItemId =
              _readString(normalized, 'currentQueueItemId') ??
                  _readString(normalized, 'currentPlaylistId');
          final hasPlayback = _hasText(currentTrack) ||
              _hasText(hlsUrl) ||
              _hasText(currentQueueItemId);
          final isPaused = _readBool(normalized, 'isPaused') ?? false;
          return _SpaceRuntimeSummary(
            moodName: moodName != null && moodName.trim().isNotEmpty
                ? moodName
                : fallbackMood,
            hasPlaybackState: true,
            currentTrack: _hasText(currentTrack) ? currentTrack!.trim() : null,
            isMusicPlaying: hasPlayback && !isPaused,
            isIotDeviceOffline: _readBool(normalized, 'isIotDeviceOffline'),
            isManualOverride:
                _readBool(normalized, 'isManualOverride') ?? false,
            isScheduling: _readBool(normalized, 'isScheduling') ?? false,
            manualOverrideRemainingSeconds:
                _readNum(normalized, 'manualOverrideRemainingSeconds')?.toInt(),
            schedulingRemainingSeconds:
                _readNum(normalized, 'schedulingRemainingSeconds')?.toInt(),
          );
        }
      }
    } catch (_) {
      // Keep per-space fallback without failing the full list.
    }
    return _SpaceRuntimeSummary(moodName: fallbackMood);
  }

  Future<String?> _getLiveSpaceMoodName(String spaceId) async {
    final trimmedSpaceId = spaceId.trim();
    if (trimmedSpaceId.isEmpty) return null;

    for (final path in [
      ApiConstants.camsSpaceMood(trimmedSpaceId),
      ApiConstants.camsSpaceMoodPlural(trimmedSpaceId),
    ]) {
      try {
        final response = await dioClient.get(path);
        final moodName = _extractMoodName(response.data);
        if (moodName != null && moodName.trim().isNotEmpty) {
          return moodName.trim();
        }
      } on DioException catch (error) {
        final statusCode = error.response?.statusCode;
        if (statusCode == 401 || statusCode == 403 || statusCode == 404) {
          continue;
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  String? _extractMoodName(dynamic body) {
    final payload = _extractMoodPayload(body);
    if (payload == null) return null;

    final direct = _readFirstString(payload, const [
      'moodName',
      'currentMood',
      'spaceMood',
      'name',
      'selectedMoodName',
      'newMood',
      'targetMood',
    ]);
    if (direct != null) return direct;

    final mood = _readValue(payload, 'mood');
    if (mood is Map) {
      return _readFirstString(Map<String, dynamic>.from(mood), const [
        'moodName',
        'name',
        'currentMood',
      ]);
    }
    if (mood is String && mood.trim().isNotEmpty) {
      return mood.trim();
    }
    return null;
  }

  Map<String, dynamic>? _extractMoodPayload(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return body;
    }
    if (body is Map) {
      final normalized = Map<String, dynamic>.from(body);
      final data = normalized['data'];
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return normalized;
    }
    return null;
  }

  String? _readFirstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = _readValue(json, key);
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  StoreMutationResult _parseMutationResult(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['isSuccess'] == false) {
        throw ServerException(_extractErrorMessage(data));
      }
      return StoreMutationResult.fromJson(data);
    }
    return const StoreMutationResult(isSuccess: true);
  }

  String _extractDioErrorMessage(
    DioException error, {
    required String fallback,
  }) {
    final payload = error.response?.data;
    if (payload is Map<String, dynamic>) {
      return _extractErrorMessage(payload);
    }
    final message = error.message;
    if (message != null && message.trim().isNotEmpty) {
      return message;
    }
    return fallback;
  }

  String _extractErrorMessage(Map<String, dynamic> payload) {
    final errors = payload['errors'];
    if (errors is List && errors.isNotEmpty) {
      final first = errors.first;
      if (first is Map<String, dynamic>) {
        final detail = first['message']?.toString();
        if (detail != null && detail.trim().isNotEmpty) {
          return detail;
        }
      }
      final detail = first.toString();
      if (detail.trim().isNotEmpty) {
        return detail;
      }
    }
    final message = payload['message']?.toString();
    if (message != null && message.trim().isNotEmpty) {
      return message;
    }
    return 'Request failed.';
  }
}

class _SpaceRuntimeSummary {
  const _SpaceRuntimeSummary({
    required this.moodName,
    this.hasPlaybackState = false,
    this.currentTrack,
    this.isMusicPlaying,
    this.isIotDeviceOffline,
    this.isManualOverride = false,
    this.isScheduling = false,
    this.manualOverrideRemainingSeconds,
    this.schedulingRemainingSeconds,
  });

  final String moodName;
  final bool hasPlaybackState;
  final String? currentTrack;
  final bool? isMusicPlaying;
  final bool? isIotDeviceOffline;
  final bool isManualOverride;
  final bool isScheduling;
  final int? manualOverrideRemainingSeconds;
  final int? schedulingRemainingSeconds;
}

class _SpaceIotTelemetry {
  const _SpaceIotTelemetry({
    this.spaceId,
    this.spaceName,
    this.measuredAtUtc,
    this.avgNoise,
    this.crowdDensity,
  });

  final String? spaceId;
  final String? spaceName;
  final DateTime? measuredAtUtc;
  final double? avgNoise;
  final int? crowdDensity;

  bool get hasDisplayData => avgNoise != null || crowdDensity != null;

  bool isNewerThan(_SpaceIotTelemetry other) {
    final current = measuredAtUtc;
    final previous = other.measuredAtUtc;
    if (current == null) return previous == null;
    if (previous == null) return true;
    return current.isAfter(previous);
  }

  factory _SpaceIotTelemetry.fromJson(Map<String, dynamic> json) {
    return _SpaceIotTelemetry(
      spaceId: _readString(json, 'spaceId'),
      spaceName: _readString(json, 'spaceName'),
      measuredAtUtc: _readDateTime(json, 'measuredAtUtc'),
      avgNoise: _readNum(json, 'avgNoise')?.toDouble(),
      crowdDensity: _readNum(json, 'crowdDensity')?.round(),
    );
  }
}

String? _telemetryKey(String? value) {
  final trimmed = value?.trim().toLowerCase();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

dynamic _readValue(Map<String, dynamic> json, String key) {
  if (json.containsKey(key)) return json[key];
  if (key.isEmpty) return null;
  final pascalCaseKey = '${key[0].toUpperCase()}${key.substring(1)}';
  return json[pascalCaseKey];
}

String? _readString(Map<String, dynamic> json, String key) {
  final value = _readValue(json, key);
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

num? _readNum(Map<String, dynamic> json, String key) {
  final value = _readValue(json, key);
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

bool? _readBool(Map<String, dynamic> json, String key) {
  final value = _readValue(json, key);
  if (value is bool) return value;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return null;
}

DateTime? _readDateTime(Map<String, dynamic> json, String key) {
  final value = _readValue(json, key);
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
