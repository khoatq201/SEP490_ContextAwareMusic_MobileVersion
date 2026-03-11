import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/space_control/domain/entities/space.dart';
import '../../features/space_control/domain/entities/track.dart';
import '../constants/app_colors.dart';
import '../enums/entity_status_enum.dart';
import '../enums/space_type_enum.dart';
import '../enums/user_role.dart';
import '../player/player_bloc.dart';
import '../player/player_event.dart';
import '../session/session_cubit.dart';
import 'play_to_space_bottom_sheet.dart';

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

    if (session.currentRole == UserRole.playbackDevice) {
      // Auto-play — playback device is locked to its own space
      _play(context, space: session.currentSpace);
      return;
    }

    // Show space selection bottom sheet
    final spaces = availableSpaces ?? _mockSpaces();

    PlayToSpaceBottomSheet.show(context, spaces: spaces).then((selected) {
      if (selected != null && context.mounted) {
        _play(context, space: selected);
      }
    });
  }

  void _play(BuildContext context, {Space? space}) {
    // For now, just starts the local player queue.
    // When MQTT is wired, this would also push to the selected space.
    context.read<PlayerBloc>().add(PlayerPlaylistStarted(
          tracks: tracks,
          startIndex: startIndex,
          playlistName: playlistName,
        ));

    if (space != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Playing to ${space.name}'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  /// Temporary mock spaces until the real store/space API is wired.
  List<Space> _mockSpaces() {
    return const [
      Space(
        id: 'space-1',
        name: 'Main Floor',
        status: EntityStatusEnum.active,
        type: SpaceTypeEnum.hall,
        assignedHubId: 'hub-1',
        storeId: 'store-1',
      ),
      Space(
        id: 'space-2',
        name: 'VIP Lounge',
        status: EntityStatusEnum.active,
        type: SpaceTypeEnum.hall,
        assignedHubId: 'hub-2',
        storeId: 'store-1',
      ),
      Space(
        id: 'space-3',
        name: 'Outdoor Patio',
        status: EntityStatusEnum.inactive,
        type: SpaceTypeEnum.hall,
        assignedHubId: 'hub-3',
        storeId: 'store-1',
      ),
      Space(
        id: 'space-4',
        name: 'Bar Area',
        status: EntityStatusEnum.active,
        type: SpaceTypeEnum.hall,
        assignedHubId: 'hub-4',
        storeId: 'store-1',
      ),
    ];
  }
}
