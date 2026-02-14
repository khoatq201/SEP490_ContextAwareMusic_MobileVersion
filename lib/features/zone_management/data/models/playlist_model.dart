import '../../domain/entities/playlist.dart';
import '../../../space_control/data/models/track_model.dart';

class PlaylistModel extends Playlist {
  const PlaylistModel({
    required super.id,
    required super.name,
    required super.description,
    required super.tracks,
    required super.moodTags,
    required super.genre,
    super.coverArt,
    required super.totalDuration,
    required super.isAvailableOffline,
    super.playCount = 0,
    required super.createdAt,
    super.updatedAt,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) => TrackModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      moodTags:
          (json['moodTags'] as List<dynamic>).map((e) => e as String).toList(),
      genre: json['genre'] as String,
      coverArt: json['coverArt'] as String?,
      totalDuration: json['totalDuration'] as int,
      isAvailableOffline: json['isAvailableOffline'] as bool,
      playCount: json['playCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'tracks': tracks.map((e) => (e as TrackModel).toJson()).toList(),
      'moodTags': moodTags,
      'genre': genre,
      'coverArt': coverArt,
      'totalDuration': totalDuration,
      'isAvailableOffline': isAvailableOffline,
      'playCount': playCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory PlaylistModel.fromEntity(Playlist playlist) {
    return PlaylistModel(
      id: playlist.id,
      name: playlist.name,
      description: playlist.description,
      tracks: playlist.tracks,
      moodTags: playlist.moodTags,
      genre: playlist.genre,
      coverArt: playlist.coverArt,
      totalDuration: playlist.totalDuration,
      isAvailableOffline: playlist.isAvailableOffline,
      playCount: playlist.playCount,
      createdAt: playlist.createdAt,
      updatedAt: playlist.updatedAt,
    );
  }
}
