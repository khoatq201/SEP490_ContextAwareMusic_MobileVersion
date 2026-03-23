import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/enums/music_provider_enum.dart';
import '../../domain/entities/api_track.dart';

class ApiTrackModel extends ApiTrack {
  const ApiTrackModel({
    required super.id,
    super.brandId,
    required super.title,
    super.artist,
    super.moodId,
    super.moodName,
    super.genre,
    super.provider,
    super.durationSec,
    super.hlsUrl,
    super.coverImageUrl,
    super.playCount,
    super.isAiGenerated,
    super.status,
    required super.createdAt,
    super.updatedAt,
  });

  factory ApiTrackModel.fromJson(Map<String, dynamic> json) {
    final hlsUrl = json['hlsUrl'] as String? ?? json['audioUrl'] as String?;
    return ApiTrackModel(
      id: json['id'] as String,
      brandId: json['brandId'] as String?,
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String?,
      moodId: json['moodId'] as String?,
      moodName: json['moodName'] as String?,
      genre: json['genre'] as String?,
      provider: MusicProviderEnum.fromJson(json['provider']),
      durationSec: (json['durationSec'] as num?)?.toInt(),
      hlsUrl: hlsUrl,
      coverImageUrl: json['coverImageUrl'] as String?,
      playCount: (json['playCount'] as num?)?.toInt() ?? 0,
      isAiGenerated: json['isAiGenerated'] as bool?,
      status: EntityStatusEnum.fromJson(json['status'] ?? 1),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brandId': brandId,
      'title': title,
      'artist': artist,
      'moodId': moodId,
      'moodName': moodName,
      'genre': genre,
      'provider': provider?.value,
      'durationSec': durationSec,
      'hlsUrl': hlsUrl,
      'coverImageUrl': coverImageUrl,
      'playCount': playCount,
      'isAiGenerated': isAiGenerated,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Parse paginated API response:
  /// { "currentPage": 1, ..., "items": [...], "isSuccess": true }
  static List<ApiTrackModel> fromPaginatedResponse(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => ApiTrackModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
