import '../../domain/entities/track.dart';

class TrackModel extends Track {
  const TrackModel({
    required super.id,
    required super.title,
    required super.artist,
    required super.fileUrl,
    super.localPath,
    required super.moodTags,
    super.duration,
    super.albumArt,
  });

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      fileUrl: json['fileUrl'] as String,
      localPath: json['localPath'] as String?,
      moodTags:
          (json['moodTags'] as List<dynamic>).map((e) => e as String).toList(),
      duration: json['duration'] as int?,
      albumArt: json['albumArt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'fileUrl': fileUrl,
      'localPath': localPath,
      'moodTags': moodTags,
      'duration': duration,
      'albumArt': albumArt,
    };
  }

  Track toEntity() {
    return Track(
      id: id,
      title: title,
      artist: artist,
      fileUrl: fileUrl,
      localPath: localPath,
      moodTags: moodTags,
      duration: duration,
      albumArt: albumArt,
    );
  }

  factory TrackModel.fromEntity(Track track) {
    return TrackModel(
      id: track.id,
      title: track.title,
      artist: track.artist,
      fileUrl: track.fileUrl,
      localPath: track.localPath,
      moodTags: track.moodTags,
      duration: track.duration,
      albumArt: track.albumArt,
    );
  }
}
