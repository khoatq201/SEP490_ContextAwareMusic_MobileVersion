import 'package:equatable/equatable.dart';

import '../../../home/domain/entities/song_entity.dart';

/// Represents a music album returned by search.
class AlbumEntity extends Equatable {
  final String id;
  final String name;
  final String artistName;
  final String? coverUrl;
  final int? releaseYear;
  final List<SongEntity> songs;

  const AlbumEntity({
    required this.id,
    required this.name,
    required this.artistName,
    this.coverUrl,
    this.releaseYear,
    this.songs = const [],
  });

  int get totalTracks => songs.length;

  int get totalDuration => songs.fold(0, (sum, s) => sum + s.duration);

  @override
  List<Object?> get props =>
      [id, name, artistName, coverUrl, releaseYear, songs];
}
