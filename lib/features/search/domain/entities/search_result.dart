import '../../../../core/enums/entity_status_enum.dart';
import '../../../tracks/domain/entities/track_copyright_clearance_status.dart';

/// A lightweight result item returned by a song/artist search.
class SearchResult {
  final String id;
  final String? brandId;
  final String title;
  final String subtitle; // artist name or type label
  final String? thumbnailUrl;
  final String? imageUrl;
  final List<String> playlistCoverUrls;
  final SearchResultType type;

  /// Optional duration string for songs (e.g. "3:25")
  final String? duration;
  final int? durationSeconds;
  final String? streamUrl;
  final TrackCopyrightClearanceStatus? copyrightClearanceStatus;
  final EntityStatusEnum? trackStatus;

  const SearchResult({
    required this.id,
    this.brandId,
    required this.title,
    required this.subtitle,
    this.thumbnailUrl,
    this.imageUrl,
    this.playlistCoverUrls = const [],
    required this.type,
    this.duration,
    this.durationSeconds,
    this.streamUrl,
    this.copyrightClearanceStatus,
    this.trackStatus,
  });

  bool get isSharedCatalog => brandId == null || brandId!.trim().isEmpty;

  bool get isPlayableTrack {
    if (type != SearchResultType.song) return false;
    return trackStatus == EntityStatusEnum.active &&
        copyrightClearanceStatus?.isPlayable == true;
  }
}

enum SearchResultType { song, artist, playlist, album, category }
