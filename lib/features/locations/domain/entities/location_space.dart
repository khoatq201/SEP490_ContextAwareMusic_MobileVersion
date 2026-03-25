import 'package:equatable/equatable.dart';

import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/enums/space_type_enum.dart';
import '../../../cams/domain/entities/pair_code_snapshot.dart';
import '../../../cams/domain/entities/pair_device_info.dart';

/// Represents a space (and its summary info) displayed in the Location Tab.
class LocationSpace extends Equatable {
  final String id;
  final String name;
  final String storeId;

  // Real API fields
  final SpaceTypeEnum type;
  final String? description;
  final EntityStatusEnum status;
  final String? currentPlaylistId;

  // Legacy / UI Mock fields
  final String? storeName;
  final bool isOnline; // Kept for UI backwards compatibility
  final String? currentPlaylistName;
  final String? currentMoodName;
  final String? currentTrackName;
  final String? currentTrackArtist;
  final bool hasActivePlayback;
  final double volume;
  final PairDeviceInfo? pairDeviceInfo;
  final PairCodeSnapshot? activePairCode;

  const LocationSpace({
    required this.id,
    required this.name,
    required this.storeId,
    required this.type,
    this.description,
    required this.status,
    this.currentPlaylistId,
    this.storeName,
    this.isOnline = false,
    this.currentPlaylistName,
    this.currentMoodName,
    this.currentTrackName,
    this.currentTrackArtist,
    this.hasActivePlayback = false,
    this.volume = 50.0,
    this.pairDeviceInfo,
    this.activePairCode,
  });

  String? get currentPlaybackName {
    if (currentTrackName != null && currentTrackName!.isNotEmpty) {
      return currentTrackName;
    }
    if (currentPlaylistName != null && currentPlaylistName!.isNotEmpty) {
      return currentPlaylistName;
    }
    return null;
  }

  bool get hasLivePlayback =>
      hasActivePlayback ||
      (currentPlaybackName != null && currentPlaybackName!.isNotEmpty);

  bool get hasPairedPlaybackDevice => pairDeviceInfo?.isPaired ?? false;

  bool get hasActivePairCode =>
      !hasPairedPlaybackDevice &&
      activePairCode != null &&
      !activePairCode!.isExpired;

  String get pairingStatusLabel {
    if (hasPairedPlaybackDevice) {
      return pairDeviceInfo?.managerStatusLabel ?? 'Da paired';
    }
    if (hasActivePairCode) {
      return activePairCode!.displayCode;
    }
    return 'No playback device';
  }

  LocationSpace copyWith({
    String? id,
    String? name,
    String? storeId,
    SpaceTypeEnum? type,
    String? description,
    EntityStatusEnum? status,
    String? currentPlaylistId,
    String? storeName,
    bool? isOnline,
    String? currentPlaylistName,
    String? currentMoodName,
    String? currentTrackName,
    String? currentTrackArtist,
    bool? hasActivePlayback,
    double? volume,
    PairDeviceInfo? pairDeviceInfo,
    PairCodeSnapshot? activePairCode,
    bool clearCurrentPlaylistId = false,
    bool clearCurrentPlaylistName = false,
    bool clearCurrentMoodName = false,
    bool clearCurrentTrackName = false,
    bool clearCurrentTrackArtist = false,
    bool clearPairDeviceInfo = false,
    bool clearActivePairCode = false,
  }) {
    return LocationSpace(
      id: id ?? this.id,
      name: name ?? this.name,
      storeId: storeId ?? this.storeId,
      type: type ?? this.type,
      description: description ?? this.description,
      status: status ?? this.status,
      currentPlaylistId: clearCurrentPlaylistId
          ? null
          : (currentPlaylistId ?? this.currentPlaylistId),
      storeName: storeName ?? this.storeName,
      isOnline: isOnline ?? this.isOnline,
      currentPlaylistName: clearCurrentPlaylistName
          ? null
          : (currentPlaylistName ?? this.currentPlaylistName),
      currentMoodName: clearCurrentMoodName
          ? null
          : (currentMoodName ?? this.currentMoodName),
      currentTrackName: clearCurrentTrackName
          ? null
          : (currentTrackName ?? this.currentTrackName),
      currentTrackArtist: clearCurrentTrackArtist
          ? null
          : (currentTrackArtist ?? this.currentTrackArtist),
      hasActivePlayback: hasActivePlayback ?? this.hasActivePlayback,
      volume: volume ?? this.volume,
      pairDeviceInfo:
          clearPairDeviceInfo ? null : (pairDeviceInfo ?? this.pairDeviceInfo),
      activePairCode:
          clearActivePairCode ? null : (activePairCode ?? this.activePairCode),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        storeId,
        type,
        description,
        status,
        currentPlaylistId,
        storeName,
        isOnline,
        currentPlaylistName,
        currentMoodName,
        currentTrackName,
        currentTrackArtist,
        hasActivePlayback,
        volume,
        pairDeviceInfo,
        activePairCode,
      ];
}
