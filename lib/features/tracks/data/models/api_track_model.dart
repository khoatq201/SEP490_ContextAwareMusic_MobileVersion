import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/enums/music_provider_enum.dart';
import '../../domain/entities/api_track.dart';
import '../../domain/entities/track_metadata_status.dart';

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
    super.bpm,
    super.energyLevel,
    super.valence,
    super.hlsUrl,
    super.sourceAudioUrl,
    super.transcodeStatus,
    super.coverImageUrl,
    super.playCount,
    super.isAiGenerated,
    super.sunoClipId,
    super.generationPrompt,
    super.generatedAt,
    super.lyricsUrl,
    super.lastPlayedAt,
    super.metadataStatusOverride,
    super.status,
    required super.createdAt,
    super.updatedAt,
  });

  factory ApiTrackModel.fromJson(Map<String, dynamic> json) {
    final hlsUrl = json['hlsUrl'] as String? ?? json['audioUrl'] as String?;
    final sourceAudioUrl =
        json['sourceAudioUrl'] as String? ?? json['audioUrl'] as String?;
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
      bpm: (json['bpm'] as num?)?.toInt(),
      energyLevel: (json['energyLevel'] as num?)?.toDouble(),
      valence: (json['valence'] as num?)?.toDouble(),
      hlsUrl: hlsUrl,
      sourceAudioUrl: sourceAudioUrl,
      transcodeStatus: json['transcodeStatus']?.toString(),
      coverImageUrl: json['coverImageUrl'] as String?,
      playCount: (json['playCount'] as num?)?.toInt() ?? 0,
      isAiGenerated: json['isAiGenerated'] as bool?,
      sunoClipId: json['sunoClipId'] as String?,
      generationPrompt: json['generationPrompt'] as String?,
      generatedAt: _parseDateTime(json['generatedAt']),
      lyricsUrl: json['lyricsUrl'] as String?,
      lastPlayedAt: _parseDateTime(json['lastPlayedAt']),
      metadataStatusOverride: _readMetadataStatus(json['metadataStatus']),
      status: EntityStatusEnum.fromJson(json['status'] ?? 1),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now().toUtc(),
      updatedAt: _parseDateTime(json['updatedAt']),
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
      'bpm': bpm,
      'energyLevel': energyLevel,
      'valence': valence,
      'hlsUrl': hlsUrl,
      'sourceAudioUrl': sourceAudioUrl,
      'audioUrl': sourceAudioUrl,
      'transcodeStatus': transcodeStatus,
      'coverImageUrl': coverImageUrl,
      'playCount': playCount,
      'isAiGenerated': isAiGenerated,
      'sunoClipId': sunoClipId,
      'generationPrompt': generationPrompt,
      'generatedAt': generatedAt?.toIso8601String(),
      'lyricsUrl': lyricsUrl,
      'lastPlayedAt': lastPlayedAt?.toIso8601String(),
      'metadataStatus': metadataStatus.name,
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

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString())?.toUtc();
  }

  static TrackMetadataStatus? _readMetadataStatus(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      return TrackMetadataStatus.values.firstWhere(
        (value) => value.name.toLowerCase() == raw.toLowerCase(),
        orElse: () => TrackMetadataStatus.metadataUnknown,
      );
    }
    return null;
  }
}
