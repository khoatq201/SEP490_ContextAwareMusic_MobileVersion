import '../../domain/entities/api_playlist.dart';
import '../../domain/entities/playlist_track_item.dart';
import '../../../../core/enums/entity_status_enum.dart';

class PlaylistTrackItemModel extends PlaylistTrackItem {
  const PlaylistTrackItemModel({
    required super.trackId,
    super.title,
    super.artist,
    super.durationSec,
    super.orderIndex,
    super.coverImageUrl,
    super.actualDurationSec,
    super.seekOffsetSeconds,
  });

  factory PlaylistTrackItemModel.fromJson(Map<String, dynamic> json) {
    return PlaylistTrackItemModel(
      trackId: json['trackId'] as String,
      title: json['title'] as String?,
      artist: json['artist'] as String?,
      durationSec: json['durationSec'] as int?,
      orderIndex: json['orderIndex'] as int?,
      coverImageUrl: json['coverImageUrl'] as String?,
      actualDurationSec: json['actualDurationSec'] as int?,
      seekOffsetSeconds: json['seekOffsetSeconds'] as int? ?? 0,
    );
  }
}

class ApiPlaylistModel extends ApiPlaylist {
  const ApiPlaylistModel({
    required super.id,
    super.brandId,
    super.storeId,
    super.storeName,
    super.moodId,
    super.moodName,
    required super.name,
    super.description,
    super.isDynamic,
    super.isDefault,
    super.hlsUrl,
    super.totalDurationSeconds,
    super.trackCount,
    super.status,
    required super.createdAt,
    super.updatedAt,
    super.tracks,
  });

  /// Parse a PlaylistListItem (from paginated list).
  factory ApiPlaylistModel.fromJson(Map<String, dynamic> json) {
    return ApiPlaylistModel(
      id: json['id'] as String,
      brandId: json['brandId'] as String?,
      storeId: json['storeId'] as String?,
      storeName: json['storeName'] as String?,
      moodId: json['moodId'] as String?,
      moodName: json['moodName'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      isDynamic: json['isDynamic'] as bool?,
      isDefault: json['isDefault'] as bool?,
      hlsUrl: json['hlsUrl'] as String?,
      totalDurationSeconds: json['totalDurationSeconds'] as int?,
      trackCount: json['trackCount'] as int? ?? 0,
      status: EntityStatusEnum.fromJson(json['status'] ?? 1),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Parse a PlaylistDetailResponse (from GET /api/playlists/{id}).
  /// Includes tracks with seekOffsetSeconds.
  factory ApiPlaylistModel.fromDetailJson(Map<String, dynamic> json) {
    final tracksJson = json['tracks'] as List<dynamic>?;
    return ApiPlaylistModel(
      id: json['id'] as String,
      brandId: json['brandId'] as String?,
      storeId: json['storeId'] as String?,
      storeName: json['storeName'] as String?,
      moodId: json['moodId'] as String?,
      moodName: json['moodName'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      isDynamic: json['isDynamic'] as bool?,
      isDefault: json['isDefault'] as bool?,
      hlsUrl: json['hlsUrl'] as String?,
      totalDurationSeconds: json['totalDurationSeconds'] as int?,
      trackCount: json['trackCount'] as int? ?? 0,
      status: EntityStatusEnum.fromJson(json['status'] ?? 1),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      tracks: tracksJson
          ?.map((e) =>
              PlaylistTrackItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Parse paginated API response:
  /// { "currentPage": 1, ..., "items": [...], "isSuccess": true }
  static List<ApiPlaylistModel> fromPaginatedResponse(
      Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => ApiPlaylistModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Parse detail API response:
  /// { "isSuccess": true, "data": { ... } }
  static ApiPlaylistModel? fromDetailResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) return null;
    return ApiPlaylistModel.fromDetailJson(data);
  }
}
