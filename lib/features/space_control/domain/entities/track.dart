import 'package:equatable/equatable.dart';

class Track extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String fileUrl;
  final String? localPath;
  final List<String> moodTags;
  final int? duration; // in seconds
  final String? albumArt;
  final int? seekOffsetSeconds;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.fileUrl,
    this.localPath,
    required this.moodTags,
    this.duration,
    this.albumArt,
    this.seekOffsetSeconds,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        fileUrl,
        localPath,
        moodTags,
        duration,
        albumArt,
        seekOffsetSeconds,
      ];

  bool get isAvailableOffline => localPath != null && localPath!.isNotEmpty;
}
