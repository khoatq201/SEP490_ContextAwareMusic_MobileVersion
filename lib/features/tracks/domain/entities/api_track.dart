import 'package:equatable/equatable.dart';

import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/enums/music_provider_enum.dart';
import 'track_metadata_status.dart';

/// Track entity matching backend TrackListItem DTO.
class ApiTrack extends Equatable {
  final String id;
  final String? brandId;
  final String title;
  final String? artist;
  final String? moodId;
  final String? moodName;
  final String? genre;
  final MusicProviderEnum? provider;
  final int? durationSec;
  final int? bpm;
  final double? energyLevel;
  final double? valence;
  final String? hlsUrl;
  final String? sourceAudioUrl;
  final String? transcodeStatus;
  final String? coverImageUrl;
  final int playCount;
  final bool? isAiGenerated;
  final String? sunoClipId;
  final String? generationPrompt;
  final DateTime? generatedAt;
  final String? lyricsUrl;
  final DateTime? lastPlayedAt;
  final TrackMetadataStatus? metadataStatusOverride;
  final EntityStatusEnum status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ApiTrack({
    required this.id,
    this.brandId,
    required this.title,
    this.artist,
    this.moodId,
    this.moodName,
    this.genre,
    this.provider,
    this.durationSec,
    this.bpm,
    this.energyLevel,
    this.valence,
    this.hlsUrl,
    this.sourceAudioUrl,
    this.transcodeStatus,
    this.coverImageUrl,
    this.playCount = 0,
    this.isAiGenerated,
    this.sunoClipId,
    this.generationPrompt,
    this.generatedAt,
    this.lyricsUrl,
    this.lastPlayedAt,
    this.metadataStatusOverride,
    this.status = EntityStatusEnum.active,
    required this.createdAt,
    this.updatedAt,
  });

  /// Legacy alias during migration from `audioUrl` to `hlsUrl`.
  @Deprecated('Use hlsUrl instead')
  String? get audioUrl => hlsUrl ?? sourceAudioUrl;

  bool get hasMeaningfulMetadata {
    return (bpm ?? 0) > 0 ||
        energyLevel != null ||
        valence != null ||
        (sunoClipId != null && sunoClipId!.isNotEmpty) ||
        generatedAt != null ||
        (lyricsUrl != null && lyricsUrl!.isNotEmpty);
  }

  bool get isStreamReady => hlsUrl != null && hlsUrl!.isNotEmpty;

  TrackMetadataStatus get metadataStatus {
    if (metadataStatusOverride != null) {
      return metadataStatusOverride!;
    }
    if (hasMeaningfulMetadata) {
      return TrackMetadataStatus.metadataReady;
    }

    final age = DateTime.now().toUtc().difference(createdAt.toUtc());
    if (age <= const Duration(minutes: 2)) {
      return TrackMetadataStatus.metadataPending;
    }
    return TrackMetadataStatus.metadataUnknown;
  }

  /// Formatted duration string (e.g., "3:30")
  String get formattedDuration {
    if (durationSec == null) return '--:--';
    final minutes = durationSec! ~/ 60;
    final seconds = durationSec! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  ApiTrack copyWith({
    String? id,
    String? brandId,
    String? title,
    String? artist,
    String? moodId,
    String? moodName,
    String? genre,
    MusicProviderEnum? provider,
    int? durationSec,
    int? bpm,
    double? energyLevel,
    double? valence,
    String? hlsUrl,
    String? sourceAudioUrl,
    String? transcodeStatus,
    String? coverImageUrl,
    int? playCount,
    bool? isAiGenerated,
    String? sunoClipId,
    String? generationPrompt,
    DateTime? generatedAt,
    String? lyricsUrl,
    DateTime? lastPlayedAt,
    TrackMetadataStatus? metadataStatusOverride,
    EntityStatusEnum? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ApiTrack(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      moodId: moodId ?? this.moodId,
      moodName: moodName ?? this.moodName,
      genre: genre ?? this.genre,
      provider: provider ?? this.provider,
      durationSec: durationSec ?? this.durationSec,
      bpm: bpm ?? this.bpm,
      energyLevel: energyLevel ?? this.energyLevel,
      valence: valence ?? this.valence,
      hlsUrl: hlsUrl ?? this.hlsUrl,
      sourceAudioUrl: sourceAudioUrl ?? this.sourceAudioUrl,
      transcodeStatus: transcodeStatus ?? this.transcodeStatus,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      playCount: playCount ?? this.playCount,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      sunoClipId: sunoClipId ?? this.sunoClipId,
      generationPrompt: generationPrompt ?? this.generationPrompt,
      generatedAt: generatedAt ?? this.generatedAt,
      lyricsUrl: lyricsUrl ?? this.lyricsUrl,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      metadataStatusOverride:
          metadataStatusOverride ?? this.metadataStatusOverride,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        brandId,
        title,
        artist,
        moodId,
        moodName,
        genre,
        provider,
        durationSec,
        bpm,
        energyLevel,
        valence,
        hlsUrl,
        sourceAudioUrl,
        transcodeStatus,
        coverImageUrl,
        playCount,
        isAiGenerated,
        sunoClipId,
        generationPrompt,
        generatedAt,
        lyricsUrl,
        lastPlayedAt,
        metadataStatusOverride,
        status,
        createdAt,
        updatedAt,
      ];
}
