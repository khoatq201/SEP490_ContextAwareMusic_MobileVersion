import '../../../../core/enums/entity_status_enum.dart';
import '../../../tracks/domain/entities/track_copyright_clearance_status.dart';

/// A lightweight result item returned by a song/artist search.
class SearchResult {
  final String id;
  final String title;
  final String subtitle; // artist name or type label
  final String? thumbnailUrl;
  final String? imageUrl;
  final SearchResultType type;

  /// Optional duration string for songs (e.g. "3:25")
  final String? duration;
  final int? durationSeconds;
  final String? streamUrl;
  final TrackCopyrightClearanceStatus? copyrightClearanceStatus;
  final EntityStatusEnum? trackStatus;

  const SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    this.thumbnailUrl,
    this.imageUrl,
    required this.type,
    this.duration,
    this.durationSeconds,
    this.streamUrl,
    this.copyrightClearanceStatus,
    this.trackStatus,
  });

  bool get isPlayableTrack {
    if (type != SearchResultType.song) return false;
    return trackStatus == EntityStatusEnum.active &&
        copyrightClearanceStatus?.isPlayable == true;
  }
}

enum SearchResultType { song, artist, playlist, album, category }
