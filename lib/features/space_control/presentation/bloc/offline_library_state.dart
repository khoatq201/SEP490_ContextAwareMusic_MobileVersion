import 'package:equatable/equatable.dart';

import '../../domain/entities/offline_playlist.dart';

enum OfflineLibraryStatus { initial, loading, loaded, error }

class OfflineLibraryState extends Equatable {
  final OfflineLibraryStatus status;
  final List<OfflinePlaylist> playlists;
  final String? errorMessage;

  const OfflineLibraryState({
    this.status = OfflineLibraryStatus.initial,
    this.playlists = const [],
    this.errorMessage,
  });

  OfflineLibraryState copyWith({
    OfflineLibraryStatus? status,
    List<OfflinePlaylist>? playlists,
    String? errorMessage,
  }) {
    return OfflineLibraryState(
      status: status ?? this.status,
      playlists: playlists ?? this.playlists,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, playlists, errorMessage];
}
