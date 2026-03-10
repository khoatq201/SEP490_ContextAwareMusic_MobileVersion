import 'package:equatable/equatable.dart';

import '../../../home/domain/entities/song_entity.dart';
import 'album_entity.dart';

/// Represents a music artist returned by search.
class ArtistEntity extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final String? bio;
  final List<SongEntity> popularSongs;
  final List<AlbumEntity> albums;

  const ArtistEntity({
    required this.id,
    required this.name,
    this.imageUrl,
    this.bio,
    this.popularSongs = const [],
    this.albums = const [],
  });

  @override
  List<Object?> get props => [id, name, imageUrl, bio, popularSongs, albums];
}
