import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/schedule_source.dart';
import '../../domain/entities/schedule_slot.dart';
import '../../domain/entities/space_schedule_bootstrap.dart';
import '../models/schedule_music_item_model.dart';
import '../models/schedule_source_model.dart';
import '../models/space_schedule_model.dart';

abstract class SpaceScheduleRemoteDataSource {
  Future<SpaceScheduleBootstrap> getBootstrap(String spaceId);

  Future<List<ScheduleSourceModel>> getBrandLibrary(String brandId);

  Future<List<ScheduleSourceModel>> getBrandTemplates(String brandId);

  Future<String> upsertSlot({
    required String spaceId,
    required ScheduleSlot slot,
  });

  Future<String> deleteSlot({
    required String spaceId,
    required String slotId,
  });

  Future<String> applySource({
    required String spaceId,
    required String sourceId,
  });

  Future<String> saveToLibrary({
    required String spaceId,
    required String title,
    String? subtitle,
  });

  Future<String> toggle({
    required String spaceId,
    required bool enabled,
  });

  Future<String> createBrandSource({
    required String title,
    String? subtitle,
    String? description,
    bool isTemplate = false,
  });

  Future<String> updateBrandSource({
    required String sourceId,
    required String title,
    String? subtitle,
    String? description,
  });

  Future<String> deleteBrandSource({
    required String sourceId,
  });

  Future<String> upsertBrandSlot({
    required String sourceId,
    required ScheduleSlot slot,
  });

  Future<String> deleteBrandSlot({
    required String sourceId,
    required String slotId,
  });
}

class SpaceScheduleRemoteDataSourceImpl
    implements SpaceScheduleRemoteDataSource {
  final DioClient dioClient;

  SpaceScheduleRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<SpaceScheduleBootstrap> getBootstrap(String spaceId) async {
    final normalizedSpaceId = _requireId(spaceId, 'Space id is required.');
    try {
      final response = await dioClient.get(
        ApiConstants.cmsScheduleSpaceBootstrap(normalizedSpaceId),
      );
      final payload = _requireResultMap(response.data);
      final result = ApiResult<SpaceScheduleBootstrap>.fromJson(
        payload,
        fromData: (data) => _parseBootstrap(
          Map<String, dynamic>.from(data as Map),
        ),
      );
      if (!result.isSuccess || result.data == null) {
        throw ServerException(result.userFriendlyError);
      }
      return result.data!;
    } on DioException catch (error) {
      throw ServerException(
        _extractDioErrorMessage(
          error,
          fallback: 'Failed to load schedule data.',
        ),
      );
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException('Failed to load schedule data: $error');
    }
  }

  @override
  Future<List<ScheduleSourceModel>> getBrandLibrary(String brandId) async {
    final normalizedBrandId = _requireId(brandId, 'Brand id is required.');
    try {
      final response = await dioClient.get(
        ApiConstants.cmsScheduleBrandLibrary(normalizedBrandId),
      );
      final payload = _requireResultMap(response.data);
      final result = ApiResult<List<ScheduleSourceModel>>.fromJson(
        payload,
        fromData: (data) => _parseSourceList(data),
      );
      if (!result.isSuccess || result.data == null) {
        throw ServerException(result.userFriendlyError);
      }
      return result.data!;
    } on DioException catch (error) {
      throw ServerException(
        _extractDioErrorMessage(
          error,
          fallback: 'Failed to load brand schedule library.',
        ),
      );
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException('Failed to load brand schedule library: $error');
    }
  }

  @override
  Future<List<ScheduleSourceModel>> getBrandTemplates(String brandId) async {
    final normalizedBrandId = _requireId(brandId, 'Brand id is required.');
    try {
      final response = await dioClient.get(
        ApiConstants.cmsScheduleBrandTemplates(normalizedBrandId),
      );
      final payload = _requireResultMap(response.data);
      final result = ApiResult<List<ScheduleSourceModel>>.fromJson(
        payload,
        fromData: (data) => _parseSourceList(data)
            .where((source) => source.type == ScheduleSourceType.template)
            .toList(growable: false),
      );
      if (!result.isSuccess || result.data == null) {
        throw ServerException(result.userFriendlyError);
      }
      return result.data!;
    } on DioException catch (error) {
      throw ServerException(
        _extractDioErrorMessage(
          error,
          fallback: 'Failed to load brand schedule templates.',
        ),
      );
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException('Failed to load brand schedule templates: $error');
    }
  }

  @override
  Future<String> upsertSlot({
    required String spaceId,
    required ScheduleSlot slot,
  }) async {
    final normalizedSpaceId = _requireId(spaceId, 'Space id is required.');
    final normalizedSlotId = _requireId(slot.id, 'Slot id is required.');
    return _sendResult(
      () => dioClient.put(
        ApiConstants.cmsScheduleSpaceSlot(
          normalizedSpaceId,
          normalizedSlotId,
        ),
        data: {
          'daysOfWeek': slot.daysOfWeek,
          'startTime': slot.startTime,
          'endTime': slot.endTime,
          'playlistId': slot.musicId,
        },
      ),
      fallback: 'Schedule slot saved.',
    );
  }

  @override
  Future<String> deleteSlot({
    required String spaceId,
    required String slotId,
  }) async {
    final normalizedSpaceId = _requireId(spaceId, 'Space id is required.');
    final normalizedSlotId = _requireId(slotId, 'Slot id is required.');
    return _sendResult(
      () => dioClient.delete(
        ApiConstants.cmsScheduleSpaceSlot(
          normalizedSpaceId,
          normalizedSlotId,
        ),
      ),
      fallback: 'Schedule slot removed.',
    );
  }

  @override
  Future<String> applySource({
    required String spaceId,
    required String sourceId,
  }) async {
    final normalizedSpaceId = _requireId(spaceId, 'Space id is required.');
    final normalizedSourceId = _requireId(sourceId, 'Source id is required.');
    return _sendResult(
      () => dioClient.post(
        ApiConstants.cmsScheduleSpaceApplySource(normalizedSpaceId),
        data: {'sourceId': normalizedSourceId},
      ),
      fallback: 'Schedule source applied.',
    );
  }

  @override
  Future<String> saveToLibrary({
    required String spaceId,
    required String title,
    String? subtitle,
  }) async {
    final normalizedSpaceId = _requireId(spaceId, 'Space id is required.');
    final normalizedTitle = _requireId(title, 'Schedule title is required.');
    return _sendResult(
      () => dioClient.post(
        ApiConstants.cmsScheduleSpaceSaveToLibrary(normalizedSpaceId),
        data: {
          'title': normalizedTitle,
          if (subtitle != null && subtitle.trim().isNotEmpty)
            'subtitle': subtitle.trim(),
        },
      ),
      fallback: 'Schedule saved to library.',
    );
  }

  @override
  Future<String> toggle({
    required String spaceId,
    required bool enabled,
  }) async {
    final normalizedSpaceId = _requireId(spaceId, 'Space id is required.');
    return _sendResult(
      () => dioClient.patch(
        ApiConstants.cmsScheduleSpaceToggle(normalizedSpaceId),
        data: {'enabled': enabled},
      ),
      fallback: enabled ? 'Schedule enabled.' : 'Schedule disabled.',
    );
  }

  @override
  Future<String> createBrandSource({
    required String title,
    String? subtitle,
    String? description,
    bool isTemplate = false,
  }) async {
    final normalizedTitle = _requireId(title, 'Schedule title is required.');
    return _sendResult(
      () => dioClient.post(
        ApiConstants.cmsScheduleBrandSources,
        data: {
          'title': normalizedTitle,
          'subtitle': subtitle?.trim() ?? '',
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
          'isTemplate': isTemplate,
        },
      ),
      fallback: 'Brand schedule source created.',
    );
  }

  @override
  Future<String> updateBrandSource({
    required String sourceId,
    required String title,
    String? subtitle,
    String? description,
  }) async {
    final normalizedSourceId =
        _requireId(sourceId, 'Schedule source id is required.');
    final normalizedTitle = _requireId(title, 'Schedule title is required.');
    return _sendResult(
      () => dioClient.patch(
        ApiConstants.cmsScheduleBrandSource(normalizedSourceId),
        data: {
          'title': normalizedTitle,
          'subtitle': subtitle?.trim() ?? '',
          if (description != null && description.trim().isNotEmpty)
            'description': description.trim(),
        },
      ),
      fallback: 'Brand schedule source updated.',
    );
  }

  @override
  Future<String> deleteBrandSource({
    required String sourceId,
  }) async {
    final normalizedSourceId =
        _requireId(sourceId, 'Schedule source id is required.');
    return _sendResult(
      () => dioClient.delete(
        ApiConstants.cmsScheduleBrandSource(normalizedSourceId),
      ),
      fallback: 'Brand schedule source deleted.',
    );
  }

  @override
  Future<String> upsertBrandSlot({
    required String sourceId,
    required ScheduleSlot slot,
  }) async {
    final normalizedSourceId =
        _requireId(sourceId, 'Schedule source id is required.');
    final normalizedSlotId = _requireId(slot.id, 'Slot id is required.');
    return _sendResult(
      () => dioClient.put(
        ApiConstants.cmsScheduleBrandSourceSlot(
          normalizedSourceId,
          normalizedSlotId,
        ),
        data: {
          'daysOfWeek': slot.daysOfWeek,
          'startTime': slot.startTime,
          'endTime': slot.endTime,
          'playlistId': slot.musicId,
        },
      ),
      fallback: 'Brand schedule slot saved.',
    );
  }

  @override
  Future<String> deleteBrandSlot({
    required String sourceId,
    required String slotId,
  }) async {
    final normalizedSourceId =
        _requireId(sourceId, 'Schedule source id is required.');
    final normalizedSlotId = _requireId(slotId, 'Slot id is required.');
    return _sendResult(
      () => dioClient.delete(
        ApiConstants.cmsScheduleBrandSourceSlot(
          normalizedSourceId,
          normalizedSlotId,
        ),
      ),
      fallback: 'Brand schedule slot removed.',
    );
  }

  SpaceScheduleBootstrap _parseBootstrap(Map<String, dynamic> json) {
    final draftJson = json['draftSchedule'];
    final rawLibrarySources = _parseSourceList(json['librarySources']);
    final rawTemplateSources = _parseSourceList(json['templateSources']);
    final librarySources = rawLibrarySources
        .where((source) => source.type != ScheduleSourceType.template)
        .toList(growable: false);
    final templateSources = _uniqueSources([
      ...rawTemplateSources,
      ...rawLibrarySources,
    ].where((source) => source.type == ScheduleSourceType.template));
    final musicCatalog = (json['musicCatalog'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) =>
              ScheduleMusicItemModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);

    return SpaceScheduleBootstrap(
      draftSchedule: draftJson is Map
          ? SpaceScheduleModel.fromJson(Map<String, dynamic>.from(draftJson))
          : null,
      librarySources: librarySources,
      templateSources: templateSources,
      musicCatalog: musicCatalog,
    );
  }

  List<ScheduleSourceModel> _parseSourceList(dynamic raw) {
    return (raw as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) => ScheduleSourceModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList(growable: false);
  }

  List<ScheduleSourceModel> _uniqueSources(
    Iterable<ScheduleSourceModel> sources,
  ) {
    final seen = <String>{};
    final unique = <ScheduleSourceModel>[];
    for (final source in sources) {
      if (seen.add(source.id)) unique.add(source);
    }
    return List<ScheduleSourceModel>.unmodifiable(unique);
  }

  Future<String> _sendResult(
    Future<Response<dynamic>> Function() send, {
    required String fallback,
  }) async {
    try {
      final response = await send();
      final payload = _requireResultMap(response.data);
      final result = ApiResult<String>.fromJson(
        payload,
        fromData: _parseStringData,
      );
      if (!result.isSuccess) {
        throw ServerException(result.userFriendlyError);
      }
      final data = result.data?.trim();
      if (data != null && data.isNotEmpty) return data;
      final message = result.message?.trim();
      if (message != null && message.isNotEmpty) return message;
      return fallback;
    } on DioException catch (error) {
      throw ServerException(
        _extractDioErrorMessage(error, fallback: fallback),
      );
    } catch (error) {
      if (error is ServerException) rethrow;
      throw ServerException('$fallback: $error');
    }
  }

  Map<String, dynamic> _requireResultMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ServerException('Invalid schedule API response.');
  }

  String _parseStringData(dynamic data) {
    if (data is Map) {
      final id = data['id']?.toString().trim();
      if (id != null && id.isNotEmpty) return id;
      final message = data['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
    }
    return data.toString();
  }

  String _requireId(String value, String message) {
    final normalized = value.trim();
    if (normalized.isEmpty) throw ServerException(message);
    return normalized;
  }

  String _extractDioErrorMessage(
    DioException error, {
    required String fallback,
  }) {
    final payload = error.response?.data;
    if (payload is Map<String, dynamic>) {
      return _extractErrorMessage(payload);
    }
    if (payload is Map) {
      return _extractErrorMessage(Map<String, dynamic>.from(payload));
    }
    final message = error.message;
    if (message != null && message.trim().isNotEmpty) {
      return message;
    }
    return fallback;
  }

  String _extractErrorMessage(Map<String, dynamic> payload) {
    final errorCode = payload['errorCode']?.toString();
    if (errorCode == 'Cams_Error_TemplateSourceNotApplicable') {
      return 'Template sources cannot be applied directly. Use Strict Sync governance to link a template.';
    }
    final errors = payload['errors'];
    if (errors is List && errors.isNotEmpty) {
      final detail = errors.first.toString();
      if (detail.trim().isNotEmpty) return detail;
    }
    if (errors is Map<String, dynamic> && errors.isNotEmpty) {
      final firstValue = errors.values.first;
      if (firstValue is List && firstValue.isNotEmpty) {
        final detail = firstValue.first.toString();
        if (detail.trim().isNotEmpty) return detail;
      }
    }
    final message = payload['message']?.toString();
    if (message != null && message.trim().isNotEmpty) return message;
    return 'Schedule request failed.';
  }
}
