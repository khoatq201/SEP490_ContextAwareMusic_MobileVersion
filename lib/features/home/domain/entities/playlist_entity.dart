import 'package:equatable/equatable.dart';
import 'song_entity.dart';

/// A curated playlist card shown inside a [CategoryEntity] row.
class PlaylistEntity extends Equatable {
  final String id;
  final String title;
  final String? description;

  /// Remote image URL for the playlist cover art
  final String? coverUrl;

  final List<SongEntity> songs;

  /// Whether this playlist has been downloaded for offline use
  final bool isDownloaded;

  const PlaylistEntity({
    required this.id,
    required this.title,
    this.description,
    this.coverUrl,
    this.songs = const [],
    this.isDownloaded = false,
  });

  int get totalTracks => songs.length;

  /// Total duration of all songs in seconds
  int get totalDuration => songs.fold(0, (sum, s) => sum + s.duration);

  @override
  List<Object?> get props =>
      [id, title, description, coverUrl, songs, isDownloaded];

  PlaylistEntity copyWith({
    String? id,
    String? title,
    String? description,
    String? coverUrl,
    List<SongEntity>? songs,
    bool? isDownloaded,
  }) =>
      PlaylistEntity(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        coverUrl: coverUrl ?? this.coverUrl,
        songs: songs ?? this.songs,
        isDownloaded: isDownloaded ?? this.isDownloaded,
      );
}
