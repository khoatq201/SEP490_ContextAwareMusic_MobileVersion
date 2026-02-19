import 'package:equatable/equatable.dart';

/// A song/track entry used in playlist cards on the Home tab.
/// Deliberately separate from [Track] (space_control domain) which carries
/// MQTT-specific fields (fileUrl, moodTags, localPath).
class SongEntity extends Equatable {
  final String id;
  final String title;
  final String artist;

  /// Duration in seconds
  final int duration;

  /// Remote image URL for the album / track artwork
  final String? coverUrl;

  const SongEntity({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    this.coverUrl,
  });

  /// Returns a formatted mm:ss string, e.g. "03:25"
  String get formattedDuration {
    final m = duration ~/ 60;
    final s = duration % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [id, title, artist, duration, coverUrl];
}
