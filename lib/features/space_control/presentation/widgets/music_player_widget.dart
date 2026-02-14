import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/music_control_bloc.dart';
import '../bloc/music_control_event.dart';
import '../bloc/music_control_state.dart';

class MusicPlayerWidget extends StatelessWidget {
  const MusicPlayerWidget({Key? key}) : super(key: key);

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicControlBloc, MusicControlState>(
      builder: (context, state) {
        final track = state.playerState?.currentTrack;
        final isPlaying = state.status == MusicControlStatus.playing;
        final currentPosition = state.playerState?.currentPosition ?? 0;
        final duration = track?.duration ?? 0;

        return Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Now Playing',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Album Art
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: track?.albumArt != null
                          ? Image.network(
                              track!.albumArt!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderArt();
                              },
                            )
                          : _buildPlaceholderArt(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Track Info
                Text(
                  track?.title ?? 'No track playing',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  track?.artist ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Progress Bar
                if (duration > 0)
                  Column(
                    children: [
                      LinearProgressIndicator(
                        value: currentPosition / duration,
                        backgroundColor: Colors.grey.shade300,
                        minHeight: 4,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(currentPosition),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            _formatDuration(duration),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // Playing from cache indicator
                if (state.playerState?.isPlayingFromCache ?? false)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.offline_pin,
                          size: 16,
                          color: Colors.blue.shade900,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Playing from Local Cache',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Player Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous),
                      iconSize: 40,
                      onPressed: () {
                        // Skip previous not implemented in this version
                      },
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).primaryColor,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                        iconSize: 40,
                        onPressed: () {
                          final spaceId = context
                              .read<MusicControlBloc>()
                              .state
                              .playerState
                              ?.currentTrack
                              ?.id;

                          if (spaceId != null) {
                            if (isPlaying) {
                              context.read<MusicControlBloc>().add(
                                    PauseMusic(spaceId),
                                  );
                            } else {
                              context.read<MusicControlBloc>().add(
                                    PlayMusic(spaceId),
                                  );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.skip_next),
                      iconSize: 40,
                      onPressed: () {
                        final spaceId = context
                            .read<MusicControlBloc>()
                            .state
                            .playerState
                            ?.currentTrack
                            ?.id;

                        if (spaceId != null) {
                          context.read<MusicControlBloc>().add(
                                SkipMusic(spaceId),
                              );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholderArt() {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(
        Icons.music_note,
        size: 80,
        color: Colors.grey,
      ),
    );
  }
}
