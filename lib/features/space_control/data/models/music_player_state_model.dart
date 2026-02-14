import '../../domain/entities/music_player_state.dart';
import '../../domain/entities/track.dart';

class MusicPlayerStateModel extends MusicPlayerState {
  const MusicPlayerStateModel({
    super.currentTrack,
    required super.status,
    super.currentPosition,
    super.isPlayingFromCache,
  });

  factory MusicPlayerStateModel.fromJson(Map<String, dynamic> json) {
    return MusicPlayerStateModel(
      currentTrack: json['currentTrack'] != null
          ? _trackFromJson(json['currentTrack'])
          : null,
      status: json['status'] as String,
      currentPosition: json['currentPosition'] as int? ?? 0,
      isPlayingFromCache: json['isPlayingFromCache'] as bool? ?? false,
    );
  }

  static Track _trackFromJson(Map<String, dynamic> json) {
    return Track(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      fileUrl: json['fileUrl'] as String,
      localPath: json['localPath'] as String?,
      moodTags: (json['moodTags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      duration: json['duration'] as int?,
      albumArt: json['albumArt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentTrack': currentTrack != null ? _trackToJson(currentTrack!) : null,
      'status': status,
      'currentPosition': currentPosition,
      'isPlayingFromCache': isPlayingFromCache,
    };
  }

  static Map<String, dynamic> _trackToJson(Track track) {
    return {
      'id': track.id,
      'title': track.title,
      'artist': track.artist,
      'fileUrl': track.fileUrl,
      'localPath': track.localPath,
      'moodTags': track.moodTags,
      'duration': track.duration,
      'albumArt': track.albumArt,
    };
  }

  MusicPlayerState toEntity() {
    return MusicPlayerState(
      currentTrack: currentTrack,
      status: status,
      currentPosition: currentPosition,
      isPlayingFromCache: isPlayingFromCache,
    );
  }

  factory MusicPlayerStateModel.fromEntity(MusicPlayerState state) {
    return MusicPlayerStateModel(
      currentTrack: state.currentTrack,
      status: state.status,
      currentPosition: state.currentPosition,
      isPlayingFromCache: state.isPlayingFromCache,
    );
  }
}
