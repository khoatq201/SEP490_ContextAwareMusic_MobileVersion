import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/player/player_bloc.dart';
import '../../../../core/player/player_event.dart';
import '../../../../injection_container.dart';
import '../../../space_control/domain/entities/track.dart';
import '../../data/datasources/playlist_remote_datasource.dart';
import '../../domain/entities/api_playlist.dart';
import 'api_playlist_detail_page.dart';

/// Loads a playlist by ID (with tracks) and initialises [CamsPlaybackBloc]
/// before rendering [ApiPlaylistDetailPage].
class PlaylistDetailLoader extends StatefulWidget {
  final String playlistId;

  const PlaylistDetailLoader({super.key, required this.playlistId});

  @override
  State<PlaylistDetailLoader> createState() => _PlaylistDetailLoaderState();
}

class _PlaylistDetailLoaderState extends State<PlaylistDetailLoader> {
  late Future<ApiPlaylist> _future;
  bool _playerSeeded = false;

  @override
  void initState() {
    super.initState();
    _future = sl<PlaylistRemoteDataSource>().getPlaylistById(widget.playlistId);
  }

  void _seedPlayer(BuildContext context, ApiPlaylist playlist) {
    if (_playerSeeded) return;
    _playerSeeded = true;

    final queue = (playlist.tracks ?? const [])
        .map((track) => Track(
              id: track.trackId,
              title: track.title ?? 'Unknown Track',
              artist: track.artist ?? 'Unknown Artist',
              fileUrl: '',
              moodTags: const [],
              duration: track.effectiveDuration,
              albumArt: track.coverImageUrl,
            ))
        .toList();

    context.read<PlayerBloc>().add(PlayerQueueSeeded(
          tracks: queue,
          playlistName: playlist.name,
          playlistId: playlist.id,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<ApiPlaylist>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.chevronLeft,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.chevronLeft,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.alertCircle,
                      color: isDark ? Colors.white54 : Colors.black38,
                      size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load playlist',
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _future = sl<PlaylistRemoteDataSource>()
                            .getPlaylistById(widget.playlistId);
                      });
                    },
                    icon: const Icon(LucideIcons.refreshCw, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final playlist = snapshot.data!;
        _seedPlayer(context, playlist);
        return ApiPlaylistDetailPage(playlist: playlist);
      },
    );
  }
}
