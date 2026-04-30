import 'package:dartz/dartz.dart' show Either, Left, Right;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/player/player_event.dart';
import '../../../../core/player/playlist_queue_builder.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/cams_skeleton.dart';
import '../../../../injection_container.dart';
import '../../data/datasources/playlist_remote_datasource.dart';
import '../../domain/entities/api_playlist.dart';
import 'api_playlist_detail_page.dart';

class PlaylistDetailLoader extends StatefulWidget {
  const PlaylistDetailLoader({super.key, required this.playlistId});

  final String playlistId;

  @override
  State<PlaylistDetailLoader> createState() => _PlaylistDetailLoaderState();
}

class _PlaylistDetailLoaderState extends State<PlaylistDetailLoader> {
  late Future<Either<Failure, ApiPlaylist>> _future;
  bool _playerSeeded = false;

  @override
  void initState() {
    super.initState();
    _future = _loadPlaylist();
  }

  Future<Either<Failure, ApiPlaylist>> _loadPlaylist() async {
    try {
      final playlist = await sl<PlaylistRemoteDataSource>()
          .getPlaylistById(widget.playlistId);
      return Right(playlist);
    } catch (error, stackTrace) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'We could not load this playlist right now.',
          stackTrace: stackTrace,
        ),
      );
    }
  }

  void _seedPlayer(BuildContext context, ApiPlaylist playlist) {
    if (_playerSeeded) return;
    final session = context.read<SessionCubit>().state;
    if (session.currentSpace != null || session.isPlaybackDevice) {
      return;
    }
    final playerState = context.read<PlayerBloc>().state;
    if (playerState.isSyncedCamsPlayback) {
      return;
    }
    _playerSeeded = true;

    final queue = buildPlaylistQueue(playlist);

    context.read<PlayerBloc>().add(
          PlayerQueueSeeded(
            tracks: queue,
            playlistName: playlist.name,
            playlistId: playlist.id,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            LucideIcons.chevronLeft,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );

    return FutureBuilder<Either<Failure, ApiPlaylist>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: appBar,
            body: const CamsSkeletonDetailPage(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 32),
            ),
          );
        }

        final result = snapshot.data;
        if (result == null) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: appBar,
            body: AppErrorView(
              title: 'Playlist unavailable',
              message: 'We could not load this playlist right now.',
              onRetry: () => setState(() => _future = _loadPlaylist()),
              onSecondaryAction: () => context.pop(),
              secondaryLabel: 'Go back',
            ),
          );
        }

        return result.fold(
          (failure) => Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: appBar,
            body: AppErrorView(
              failure: failure,
              title: 'Playlist unavailable',
              onRetry: () => setState(() => _future = _loadPlaylist()),
              onSecondaryAction: () => context.pop(),
              secondaryLabel: 'Go back',
            ),
          ),
          (playlist) {
            _seedPlayer(context, playlist);
            return ApiPlaylistDetailPage(playlist: playlist);
          },
        );
      },
    );
  }
}
