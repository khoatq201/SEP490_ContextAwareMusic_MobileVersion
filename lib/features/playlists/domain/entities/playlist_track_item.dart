import 'package:equatable/equatable.dart';

/// Track item within a playlist detail response.
/// Matches backend PlaylistTrackItem DTO.
class PlaylistTrackItem extends Equatable {
  final String trackId;
  final String? title;
  final String? artist;
  final int? durationSec;
  final int? orderIndex;
  final String? coverImageUrl;
  final int? actualDurationSec;
  final String? hlsUrl;

  /// Cumulative offset (seconds) — server-calculated.
  /// Used for skip-to-track seeking in HLS stream.
  final int seekOffsetSeconds;

  const PlaylistTrackItem({
    required this.trackId,
    this.title,
    this.artist,
    this.durationSec,
    this.orderIndex,
    this.coverImageUrl,
    this.actualDurationSec,
    this.hlsUrl,
    this.seekOffsetSeconds = 0,
  });

  /// Effective duration: prefer actual (from transcode) over metadata.
  int get effectiveDuration => actualDurationSec ?? durationSec ?? 0;

  /// Track-level stream readiness based on per-track HLS URL.
  bool get isStreamReady => (hlsUrl?.trim().isNotEmpty ?? false);

  /// Formatted duration string (e.g., "3:30")
  String get formattedDuration {
    final dur = effectiveDuration;
    final minutes = dur ~/ 60;
    final seconds = dur % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        trackId,
        title,
        artist,
        durationSec,
        orderIndex,
        coverImageUrl,
        actualDurationSec,
        hlsUrl,
        seekOffsetSeconds,
      ];
}
