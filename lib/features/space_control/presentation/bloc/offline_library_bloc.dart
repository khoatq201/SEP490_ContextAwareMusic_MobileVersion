import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/offline_playlist.dart';
import '../../domain/repositories/offline_playlist_repository.dart';
import 'offline_library_event.dart';
import 'offline_library_state.dart';

class OfflineLibraryBloc
    extends Bloc<OfflineLibraryEvent, OfflineLibraryState> {
  final OfflinePlaylistRepository repository;
  final Map<String, StreamSubscription> _downloadSubscriptions = {};

  OfflineLibraryBloc({required this.repository})
      : super(const OfflineLibraryState()) {
    on<LoadOfflinePlaylists>(_onLoadOfflinePlaylists);
    on<StartDownloadPlaylist>(_onStartDownloadPlaylist);
    on<RemovePlaylist>(_onRemovePlaylist);
    on<DownloadProgressUpdated>(_onDownloadProgressUpdated);
  }

  Future<void> _onLoadOfflinePlaylists(
    LoadOfflinePlaylists event,
    Emitter<OfflineLibraryState> emit,
  ) async {
    emit(state.copyWith(status: OfflineLibraryStatus.loading));

    final result = await repository.getAvailablePlaylists();

    result.fold(
      (failure) => emit(state.copyWith(
        status: OfflineLibraryStatus.error,
        errorMessage: failure.message,
      )),
      (playlists) => emit(state.copyWith(
        status: OfflineLibraryStatus.loaded,
        playlists: playlists,
      )),
    );
  }

  Future<void> _onStartDownloadPlaylist(
    StartDownloadPlaylist event,
    Emitter<OfflineLibraryState> emit,
  ) async {
    // Update status to downloading
    final updatedPlaylists = state.playlists.map((p) {
      if (p.id == event.playlistId) {
        return p.copyWith(
          downloadStatus: DownloadStatus.downloading,
          downloadProgress: 0.0,
        );
      }
      return p;
    }).toList();

    emit(state.copyWith(playlists: updatedPlaylists));

    // Cancel any existing download for this playlist
    _downloadSubscriptions[event.playlistId]?.cancel();

    // Start new download stream
    final subscription =
        repository.downloadPlaylist(event.playlistId).listen((progressResult) {
      progressResult.fold(
        (failure) {
          add(DownloadProgressUpdated(
            playlistId: event.playlistId,
            progress: -1, // Indicates error
          ));
        },
        (progress) {
          add(DownloadProgressUpdated(
            playlistId: event.playlistId,
            progress: progress,
          ));
        },
      );
    });

    _downloadSubscriptions[event.playlistId] = subscription;
  }

  Future<void> _onDownloadProgressUpdated(
    DownloadProgressUpdated event,
    Emitter<OfflineLibraryState> emit,
  ) async {
    final updatedPlaylists = state.playlists.map((p) {
      if (p.id == event.playlistId) {
        if (event.progress < 0) {
          // Error occurred
          return p.copyWith(
            downloadStatus: DownloadStatus.notDownloaded,
            downloadProgress: null,
          );
        } else if (event.progress >= 1.0) {
          // Download complete
          return p.copyWith(
            downloadStatus: DownloadStatus.downloaded,
            downloadProgress: 1.0,
          );
        } else {
          // Progress update
          return p.copyWith(
            downloadStatus: DownloadStatus.downloading,
            downloadProgress: event.progress,
          );
        }
      }
      return p;
    }).toList();

    emit(state.copyWith(playlists: updatedPlaylists));

    // Clean up subscription if download is complete or failed
    if (event.progress >= 1.0 || event.progress < 0) {
      _downloadSubscriptions[event.playlistId]?.cancel();
      _downloadSubscriptions.remove(event.playlistId);
    }
  }

  Future<void> _onRemovePlaylist(
    RemovePlaylist event,
    Emitter<OfflineLibraryState> emit,
  ) async {
    final result = await repository.deleteLocalPlaylist(event.playlistId);

    result.fold(
      (failure) => emit(state.copyWith(
        status: OfflineLibraryStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        final updatedPlaylists = state.playlists.map((p) {
          if (p.id == event.playlistId) {
            return p.copyWith(
              downloadStatus: DownloadStatus.notDownloaded,
              downloadProgress: null,
            );
          }
          return p;
        }).toList();

        emit(state.copyWith(
          status: OfflineLibraryStatus.loaded,
          playlists: updatedPlaylists,
        ));
      },
    );
  }

  @override
  Future<void> close() {
    // Cancel all active downloads
    for (final subscription in _downloadSubscriptions.values) {
      subscription.cancel();
    }
    _downloadSubscriptions.clear();
    return super.close();
  }
}
