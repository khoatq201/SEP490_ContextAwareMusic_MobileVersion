import '../../../../core/models/pagination_result.dart';
import '../models/location_space_model.dart';

abstract class LocationRemoteDataSource {
  Future<LocationSpaceModel> getSpace(String spaceId, String storeId);
  Future<PaginationResult<LocationSpaceModel>> getSpacesForStore(String storeId,
      {int page = 1, int pageSize = 10});
  Future<Map<String, PaginationResult<LocationSpaceModel>>> getSpacesForBrand(
      List<String> storeIds,
      {int page = 1,
      int pageSize = 10});

  Future<SpaceMutationResult> createSpace(SpaceMutationRequest request);
  Future<SpaceMutationResult> updateSpace(
    String spaceId,
    SpaceMutationRequest request,
  );
  Future<SpaceMutationResult> deleteSpace(String spaceId);
  Future<SpaceMutationResult> toggleSpaceStatus(String spaceId);
}

class SpaceMutationRequest {
  final String? storeId;
  final String? name;
  final int? type;
  final String? description;
  final String? cameraId;
  final String? roiCoordinates;
  final int? maxOccupancy;
  final int? criticalQueueThreshold;
  final String? wiFiSensorId;

  const SpaceMutationRequest({
    this.storeId,
    this.name,
    this.type,
    this.description,
    this.cameraId,
    this.roiCoordinates,
    this.maxOccupancy,
    this.criticalQueueThreshold,
    this.wiFiSensorId,
  });

  Map<String, dynamic> toJson() {
    return {
      if (storeId != null && storeId!.trim().isNotEmpty) 'storeId': storeId,
      if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
      if (type != null) 'type': type,
      if (description != null) 'description': description,
      if (cameraId != null && cameraId!.trim().isNotEmpty)
        'cameraId': cameraId!.trim(),
      if (roiCoordinates != null && roiCoordinates!.trim().isNotEmpty)
        'roiCoordinates': roiCoordinates!.trim(),
      if (maxOccupancy != null) 'maxOccupancy': maxOccupancy,
      if (criticalQueueThreshold != null)
        'criticalQueueThreshold': criticalQueueThreshold,
      if (wiFiSensorId != null && wiFiSensorId!.trim().isNotEmpty)
        'wiFiSensorId': wiFiSensorId!.trim(),
    };
  }
}

class SpaceMutationResult {
  final bool isSuccess;
  final String? message;
  final String? errorCode;

  const SpaceMutationResult({
    required this.isSuccess,
    this.message,
    this.errorCode,
  });

  factory SpaceMutationResult.fromJson(Map<String, dynamic> json) {
    return SpaceMutationResult(
      isSuccess: json['isSuccess'] as bool? ?? false,
      message: json['message']?.toString(),
      errorCode: json['errorCode']?.toString(),
    );
  }
}
