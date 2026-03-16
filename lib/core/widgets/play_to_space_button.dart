import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/space_control/domain/entities/space.dart';
import '../../features/space_control/domain/entities/track.dart';
import '../player/player_bloc.dart';
import '../player/player_event.dart';
import '../player/local_preview_feedback.dart';
import '../session/session_cubit.dart';

/// A reusable "Play to Space" button used on Search detail pages.
///
/// Behaviour depends on the current role:
/// - **playbackDevice**: auto-plays into the linked space immediately.
/// - **storeManager / brandManager**: shows [PlayToSpaceBottomSheet] to
///   let the user choose a space first.
///
/// [tracks] — the full list of tracks to enqueue.
/// [startIndex] — index to start at (default `0`).
/// [playlistName] — label shown in the mini-player queue title.
/// [availableSpaces] — optional list; if null, a mock list is used for now.
class PlayToSpaceButton extends StatelessWidget {
  final List<Track> tracks;
  final int startIndex;
  final String playlistName;
  final List<Space>? availableSpaces;

  const PlayToSpaceButton({
    super.key,
    required this.tracks,
    this.startIndex = 0,
    required this.playlistName,
    this.availableSpaces,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(LucideIcons.speaker, size: 18),
        label: Text(
          'Play to Space',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        onPressed: tracks.isEmpty ? null : () => _handleTap(context),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    final session = context.read<SessionCubit>().state;

    if (session.isPlaybackDevice) {
      // Auto-play — playback device is locked to its own space
      _play(context, space: session.currentSpace);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(kManagerPlaylistOnlyMessage)),
    );
  }

  void _play(BuildContext context, {Space? space}) {
    // Current implementation is a local preview on the paired device only.
    context.read<PlayerBloc>().add(PlayerPlaylistStarted(
          tracks: tracks,
          startIndex: startIndex,
          playlistName: playlistName,
        ));

    showLocalPreviewStartedSnackBar(
      context,
      spaceName: space?.name,
    );
  }
}
