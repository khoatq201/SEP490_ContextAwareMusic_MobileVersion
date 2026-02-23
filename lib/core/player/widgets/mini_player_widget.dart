import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_dimensions.dart';
import '../player_bloc.dart';
import '../player_event.dart';
import '../player_state.dart' as ps;

/// Persistent mini-player bar that sits just above the BottomNavigationBar.
/// Height: 64dp.  Only visible when [PlayerState.hasTrack] is true.
class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerBloc, ps.PlayerState>(
      builder: (context, state) {
        if (!state.hasTrack) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final track = state.currentTrack!;
        final colorScheme = Theme.of(context).colorScheme;

        return GestureDetector(
          onTap: () => context.go('/now-playing'),
          child: Container(
            height: 64,
            margin: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingSm,
              vertical: AppDimensions.spacingXs,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDarkElevated : Colors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              child: Stack(
                children: [
                  // Progress strip at the bottom of the mini bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: state.progress,
                      minHeight: 2,
                      backgroundColor: Colors.transparent,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    ),
                  ),

                  // Content row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.spacingMd,
                    ),
                    child: Row(
                      children: [
                        // Album art
                        _AlbumArt(
                          url: track.albumArt,
                          isDark: isDark,
                        ),
                        const SizedBox(width: AppDimensions.spacingMd),

                        // Track info (takes remaining space)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textDarkPrimary
                                      : AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textDarkSecondary
                                      : AppColors.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Play / Pause button
                        IconButton(
                          icon: Icon(
                            state.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 32,
                            color: colorScheme.primary,
                          ),
                          onPressed: () => context
                              .read<PlayerBloc>()
                              .add(const PlayerPlayPauseToggled()),
                        ),

                        // Skip button
                        IconButton(
                          icon: Icon(
                            Icons.skip_next_rounded,
                            size: 28,
                            color: isDark
                                ? AppColors.textDarkSecondary
                                : AppColors.textSecondary,
                          ),
                          onPressed: () => context
                              .read<PlayerBloc>()
                              .add(const PlayerSkipRequested()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Navigation is now handled inline via context.go('/now-playing').
}

// ---------------------------------------------------------------------------
// Album art thumbnail
// ---------------------------------------------------------------------------
class _AlbumArt extends StatelessWidget {
  final String? url;
  final bool isDark;
  const _AlbumArt({this.url, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        color: isDark
            ? AppColors.backgroundDarkTertiary
            : AppColors.backgroundSecondary,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        child: url != null
            ? Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        child: Center(
          child: Icon(Icons.music_note, color: Colors.grey.shade400, size: 22),
        ),
      );
}
