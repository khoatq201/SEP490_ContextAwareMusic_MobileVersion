import 'package:equatable/equatable.dart';

import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/enums/music_provider_enum.dart';

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
  final String? hlsUrl;
  final String? coverImageUrl;
  final int playCount;
  final bool? isAiGenerated;
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
    this.hlsUrl,
    this.coverImageUrl,
    this.playCount = 0,
    this.isAiGenerated,
    this.status = EntityStatusEnum.active,
    required this.createdAt,
    this.updatedAt,
  });

  /// Legacy alias during migration from `audioUrl` to `hlsUrl`.
  @Deprecated('Use hlsUrl instead')
  String? get audioUrl => hlsUrl;

  /// Formatted duration string (e.g., "3:30")
  String get formattedDuration {
    if (durationSec == null) return '--:--';
    final minutes = durationSec! ~/ 60;
    final seconds = durationSec! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
        hlsUrl,
        coverImageUrl,
        playCount,
        isAiGenerated,
        status,
        createdAt,
        updatedAt,
      ];
}
