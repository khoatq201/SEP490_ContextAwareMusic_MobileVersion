import 'package:equatable/equatable.dart';

abstract class OfflineLibraryEvent extends Equatable {
  const OfflineLibraryEvent();

  @override
  List<Object?> get props => [];
}

class LoadOfflinePlaylists extends OfflineLibraryEvent {
  const LoadOfflinePlaylists();
}

class StartDownloadPlaylist extends OfflineLibraryEvent {
  final String playlistId;

  const StartDownloadPlaylist(this.playlistId);

  @override
  List<Object?> get props => [playlistId];
}

class RemovePlaylist extends OfflineLibraryEvent {
  final String playlistId;

  const RemovePlaylist(this.playlistId);

  @override
  List<Object?> get props => [playlistId];
}

class DownloadProgressUpdated extends OfflineLibraryEvent {
  final String playlistId;
  final double progress;

  const DownloadProgressUpdated({
    required this.playlistId,
    required this.progress,
  });

  @override
  List<Object?> get props => [playlistId, progress];
}
