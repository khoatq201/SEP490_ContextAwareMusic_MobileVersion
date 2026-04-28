import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/fuzzy_music_profile.dart';

abstract class FuzzyMusicProfileRemoteDataSource {
  Future<List<FuzzyMusicProfile>> getBrandProfiles();

  Future<FuzzyMusicProfile> getCurrentStoreProfile();

  Future<FuzzyMusicProfile> getStoreProfile(String storeId);

  Future<FuzzyMusicProfile> getSpaceProfile(String spaceId);

  Future<String> setBrandAutoVolume({
    required String profileId,
    required bool enabled,
  });

  Future<String> setCurrentStoreAutoVolume({required bool enabled});

  Future<String> setStoreAutoVolume({
    required String storeId,
    required bool enabled,
  });

  Future<String> setSpaceAutoVolume({
    required String spaceId,
    required bool enabled,
  });
}

class FuzzyMusicProfileRemoteDataSourceImpl
    implements FuzzyMusicProfileRemoteDataSource {
  final DioClient dioClient;

  FuzzyMusicProfileRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<List<FuzzyMusicProfile>> getBrandProfiles() async {
    try {
      final response =
          await dioClient.get(ApiConstants.fuzzyMusicProfilesForBrand);
      return _parseProfileList(_extractData(response.data));
    } on DioException catch (error) {
      throw ServerException(_extractDioMessage(
        error,
        fallback: 'Failed to load brand music profiles.',
      ));
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException('Failed to load brand music profiles: $error');
    }
  }

  @override
  Future<FuzzyMusicProfile> getCurrentStoreProfile() {
    return _getProfile(
      ApiConstants.fuzzyMusicProfileForCurrentStore,
      fallback: 'Failed to load store music profile.',
    );
  }

  @override
  Future<FuzzyMusicProfile> getStoreProfile(String storeId) {
    final id = _requireId(storeId, 'Store id is required.');
    return _getProfile(
      ApiConstants.fuzzyMusicProfileForStore(id),
      fallback: 'Failed to load store music profile.',
    );
  }

  @override
  Future<FuzzyMusicProfile> getSpaceProfile(String spaceId) {
    final id = _requireId(spaceId, 'Space id is required.');
    return _getProfile(
      ApiConstants.fuzzyMusicProfileForSpace(id),
      fallback: 'Failed to load space music profile.',
    );
  }

  @override
  Future<String> setBrandAutoVolume({
    required String profileId,
    required bool enabled,
  }) {
    final id = _requireId(profileId, 'Profile id is required.');
    return _patchAutoVolume(
      ApiConstants.fuzzyMusicProfileBrandAutoVolume(id),
      enabled: enabled,
    );
  }

  @override
  Future<String> setCurrentStoreAutoVolume({required bool enabled}) {
    return _patchAutoVolume(
      ApiConstants.fuzzyMusicProfileCurrentStoreAutoVolume,
      enabled: enabled,
    );
  }

  @override
  Future<String> setStoreAutoVolume({
    required String storeId,
    required bool enabled,
  }) {
    final id = _requireId(storeId, 'Store id is required.');
    return _patchAutoVolume(
      ApiConstants.fuzzyMusicProfileStoreAutoVolume(id),
      enabled: enabled,
    );
  }

  @override
  Future<String> setSpaceAutoVolume({
    required String spaceId,
    required bool enabled,
  }) {
    final id = _requireId(spaceId, 'Space id is required.');
    return _patchAutoVolume(
      ApiConstants.fuzzyMusicProfileSpaceAutoVolume(id),
      enabled: enabled,
    );
  }

  Future<FuzzyMusicProfile> _getProfile(
    String path, {
    required String fallback,
  }) async {
    try {
      final response = await dioClient.get(path);
      return _parseProfile(_extractData(response.data));
    } on DioException catch (error) {
      throw ServerException(_extractDioMessage(error, fallback: fallback));
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException('$fallback: $error');
    }
  }

  Future<String> _patchAutoVolume(
    String path, {
    required bool enabled,
  }) async {
    try {
      final response = await dioClient.patch(path, data: {'enabled': enabled});
      final body = _asMap(response.data);
      final message = body?['message']?.toString().trim();
      return message?.isNotEmpty == true ? message! : 'Auto volume updated.';
    } on DioException catch (error) {
      throw ServerException(_extractDioMessage(
        error,
        fallback: 'Failed to update auto volume.',
      ));
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException('Failed to update auto volume: $error');
    }
  }

  FuzzyMusicProfile _parseProfile(dynamic raw) {
    final map = _asMap(raw);
    if (map == null) {
      throw const ServerException('Invalid music profile response.');
    }
    return FuzzyMusicProfile(
      id: _readString(map, 'id') ?? '',
      brandId: _readString(map, 'brandId') ?? '',
      storeId: _readString(map, 'storeId'),
      name: _readString(map, 'name') ?? 'Music profile',
      templateKey: _readString(map, 'templateKey'),
      chillBpmMin: _readInt(map, 'chillBpmMin') ?? 0,
      chillBpmMax: _readInt(map, 'chillBpmMax') ?? 0,
      focusBpmMin: _readInt(map, 'focusBpmMin') ?? 0,
      focusBpmMax: _readInt(map, 'focusBpmMax') ?? 0,
      energeticBpmMin: _readInt(map, 'energeticBpmMin') ?? 0,
      energeticBpmMax: _readInt(map, 'energeticBpmMax') ?? 0,
      noiseQuietMaxDb: _readDouble(map, 'noiseQuietMaxDb') ?? 0,
      noiseLoudMinDb: _readDouble(map, 'noiseLoudMinDb') ?? 0,
      defaultDecibelWhenNull: _readDouble(map, 'defaultDecibelWhenNull') ?? 0,
      autoVolumeEnabled: _readBool(map, 'autoVolumeEnabled') ?? false,
      autoVolumeQuietPercent: _readInt(map, 'autoVolumeQuietPercent') ?? 0,
      autoVolumeModeratePercent:
          _readInt(map, 'autoVolumeModeratePercent') ?? 0,
      autoVolumeLoudPercent: _readInt(map, 'autoVolumeLoudPercent') ?? 0,
      autoVolumeMinPercent: _readInt(map, 'autoVolumeMinPercent') ?? 0,
      autoVolumeMaxPercent: _readInt(map, 'autoVolumeMaxPercent') ?? 100,
      autoVolumeDeadbandPercent:
          _readInt(map, 'autoVolumeDeadbandPercent') ?? 0,
    );
  }

  List<FuzzyMusicProfile> _parseProfileList(dynamic raw) {
    final list = raw is List
        ? raw
        : (_asMap(raw)?['items'] is List
            ? _asMap(raw)!['items'] as List
            : null);
    return (list ?? const [])
        .whereType<Map>()
        .map((item) => _parseProfile(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  dynamic _extractData(dynamic body) {
    final map = _asMap(body);
    if (map == null) return body;
    return map.containsKey('data') ? map['data'] : map;
  }

  Map<String, dynamic>? _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  String _extractDioMessage(
    DioException error, {
    required String fallback,
  }) {
    final body = _asMap(error.response?.data);
    final message = body?['message']?.toString().trim();
    if (message != null && message.isNotEmpty) return message;
    final errorCode = body?['errorCode']?.toString().trim();
    if (errorCode != null && errorCode.isNotEmpty) return errorCode;
    return fallback;
  }

  String _requireId(String value, String message) {
    final normalized = value.trim();
    if (normalized.isEmpty) throw ServerException(message);
    return normalized;
  }

  String? _readString(Map<String, dynamic> json, String key) {
    final value = json[key];
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  int? _readInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  double? _readDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  bool? _readBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
    return null;
  }
}
