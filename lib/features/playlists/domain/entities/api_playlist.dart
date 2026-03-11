import 'package:equatable/equatable.dart';
import '../../../core/enums/entity_status_enum.dart';
import 'playlist_track_item.dart';

/// Playlist entity matching backend PlaylistListItem DTO.
/// For list views — tracks are only available in detail.
class ApiPlaylist extends Equatable {
  final String id;
  final String? brandId;
  final String? storeId;
  final String? storeName;
  final String? moodId;
  final String? moodName;
  final String name;
  final String? description;
  final bool? isDynamic;
  final bool? isDefault;
  final String? hlsUrl;
  final int? totalDurationSeconds;
  final int trackCount;
  final EntityStatusEnum status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// Only populated in detail response (GET /api/playlists/{id}).
  final List<PlaylistTrackItem>? tracks;

  const ApiPlaylist({
    required this.id,
    this.brandId,
    this.storeId,
    this.storeName,
    this.moodId,
    this.moodName,
    required this.name,
    this.description,
    this.isDynamic,
    this.isDefault,
    this.hlsUrl,
    this.totalDurationSeconds,
    this.trackCount = 0,
    this.status = EntityStatusEnum.active,
    required this.createdAt,
    this.updatedAt,
    this.tracks,
  });

  /// Whether this playlist has a ready HLS stream
  bool get isStreamReady => hlsUrl != null && hlsUrl!.isNotEmpty;

  /// Formatted total duration
  String get formattedDuration {
    if (totalDurationSeconds == null) return '--:--';
    final hours = totalDurationSeconds! ~/ 3600;
    final minutes = (totalDurationSeconds! % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}h';
    }
    return '${minutes}min';
  }

  @override
  List<Object?> get props => [
        id,
        brandId,
        storeId,
        storeName,
        moodId,
        moodName,
        name,
        description,
        isDynamic,
        isDefault,
        hlsUrl,
        totalDurationSeconds,
        trackCount,
        status,
        createdAt,
        updatedAt,
        tracks,
      ];
}
