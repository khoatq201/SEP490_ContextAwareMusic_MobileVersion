import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/enums/space_type_enum.dart';
import '../../../cams/data/models/pair_code_snapshot_model.dart';
import '../../../cams/data/models/pair_device_info_model.dart';
import '../../domain/entities/location_space.dart';

class LocationSpaceModel extends LocationSpace {
  const LocationSpaceModel({
    required super.id,
    required super.name,
    required super.storeId,
    required super.type,
    super.description,
    required super.status,
    super.currentPlaylistId,
    super.storeName,
    required super.isOnline,
    super.currentPlaylistName,
    super.currentMoodName,
    super.currentTrackName,
    super.currentTrackArtist,
    required super.volume,
    super.pairDeviceInfo,
    super.activePairCode,
  });

  factory LocationSpaceModel.fromJson(Map<String, dynamic> json) {
    // Parse the Enums
    final typeEnum = SpaceTypeEnum.fromValue(json['type'] as int?);
    final statusEnum =
        EntityStatusEnum.fromJson(json['status'] ?? json['statusStr']);

    return LocationSpaceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      storeId: json['storeId'] as String,
      type: typeEnum,
      description: json['description'] as String?,
      status: statusEnum,
      currentPlaylistId: json['currentPlaylistId'] as String?,
      currentPlaylistName: json['currentPlaylistName'] as String?,
      currentMoodName: json['currentMoodName'] as String?,

      // Keep support for UI mocks if they are passed through
      storeName: json['storeName'] as String?,
      isOnline: json['isOnline'] as bool? ?? statusEnum.isActive,
      currentTrackName: json['currentTrackName'] as String?,
      currentTrackArtist: json['currentTrackArtist'] as String?,
      volume: (json['volume'] as num?)?.toDouble() ?? 50.0,
      pairDeviceInfo: json['pairDeviceInfo'] is Map
          ? PairDeviceInfoModel.fromJson(
              Map<String, dynamic>.from(json['pairDeviceInfo'] as Map),
            )
          : null,
      activePairCode: json['activePairCode'] is Map
          ? PairCodeSnapshotModel.fromJson(
              Map<String, dynamic>.from(json['activePairCode'] as Map),
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'storeId': storeId,
      'type': type.value,
      'description': description,
      'status': status.value,
      'currentPlaylistId': currentPlaylistId,
      'currentPlaylistName': currentPlaylistName,
      'currentMoodName': currentMoodName,
      'storeName': storeName,
      'isOnline': isOnline,
      'currentTrackName': currentTrackName,
      'currentTrackArtist': currentTrackArtist,
      'volume': volume,
      'pairDeviceInfo': pairDeviceInfo == null
          ? null
          : {
              'spaceId': pairDeviceInfo!.spaceId,
              'storeId': pairDeviceInfo!.storeId,
              'brandId': pairDeviceInfo!.brandId,
              'deviceSessionId': pairDeviceInfo!.deviceSessionId,
              'isPlaybackDeviceCaller': pairDeviceInfo!.isPlaybackDeviceCaller,
              'manufacturer': pairDeviceInfo!.manufacturer,
              'model': pairDeviceInfo!.model,
              'osVersion': pairDeviceInfo!.osVersion,
              'appVersion': pairDeviceInfo!.appVersion,
              'deviceId': pairDeviceInfo!.deviceId,
              'pairedAtUtc': pairDeviceInfo!.pairedAtUtc?.toIso8601String(),
              'lastActiveAtUtc':
                  pairDeviceInfo!.lastActiveAtUtc?.toIso8601String(),
            },
      'activePairCode': activePairCode == null
          ? null
          : {
              'code': activePairCode!.code,
              'displayCode': activePairCode!.displayCode,
              'spaceId': activePairCode!.spaceId,
              'spaceName': activePairCode!.spaceName,
              'expiresAt': activePairCode!.expiresAt.toIso8601String(),
              'expiresInSeconds': activePairCode!.expiresInSeconds,
            },
    };
  }
}
