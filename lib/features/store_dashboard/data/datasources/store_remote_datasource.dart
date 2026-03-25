import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
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

      return Future.wait(
        summaries.map((summary) async {
          final moodName = await _getMoodFromSpaceState(
            spaceId: summary.id,
            fallbackMood: summary.currentMood,
          );
          return summary.copyWith(currentMood: moodName);
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

  Future<String> _getMoodFromSpaceState({
    required String spaceId,
    required String fallbackMood,
  }) async {
    try {
      final response = await dioClient.get(ApiConstants.camsState(spaceId));
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final payload = data['data'];
        if (payload is Map<String, dynamic>) {
          final moodName = payload['moodName']?.toString();
          if (moodName != null && moodName.trim().isNotEmpty) {
            return moodName;
          }
        }
      }
    } catch (_) {
      // Keep per-space fallback without failing the full list.
    }
    return fallbackMood;
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
