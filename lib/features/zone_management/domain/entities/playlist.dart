import 'package:equatable/equatable.dart';
import '../../../space_control/domain/entities/track.dart';

/// Full playlist entity with tracks and metadata
/// Extends the existing Track concept to playlist level
class Playlist extends Equatable {
  final String id;
  final String name;
  final String description;

  /// List of tracks in this playlist
  final List<Track> tracks;

  /// Mood tags this playlist is suitable for
  final List<String> moodTags;

  /// Genre classification
  final String genre;

  /// Cover art URL
  final String? coverArt;

  /// Total duration in seconds
  final int totalDuration;

  /// Whether all tracks are available for offline playback
  final bool isAvailableOffline;

  /// Number of times this playlist has been played
  final int playCount;

  /// When this playlist was created
  final DateTime createdAt;

  /// Last update timestamp
  final DateTime? updatedAt;

  const Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.tracks,
    required this.moodTags,
    required this.genre,
    this.coverArt,
    required this.totalDuration,
    required this.isAvailableOffline,
    this.playCount = 0,
    required this.createdAt,
    this.updatedAt,
  });

  /// Get total number of tracks
  int get trackCount => tracks.length;

  /// Get formatted duration string (e.g., "45:23")
  String get formattedDuration {
    final hours = totalDuration ~/ 3600;
    final minutes = (totalDuration % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}h';
    }
    return '${minutes}min';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        tracks,
        moodTags,
        genre,
        coverArt,
        totalDuration,
        isAvailableOffline,
        playCount,
        createdAt,
        updatedAt,
      ];
}
