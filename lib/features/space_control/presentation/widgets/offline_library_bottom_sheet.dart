import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/cams_theme_tokens.dart';
import '../../domain/entities/offline_playlist.dart';
import '../bloc/offline_library_bloc.dart';
import '../bloc/offline_library_event.dart';
import '../bloc/offline_library_state.dart';
import '../utils/mood_color_helper.dart';

class OfflineLibraryBottomSheet extends StatelessWidget {
  final bool isDarkMode;

  const OfflineLibraryBottomSheet({
    super.key,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.75,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: tokens.bgContainer.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: tokens.shadow.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? tokens.textOnAccent.withValues(alpha: 0.3)
                          : tokens.textPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? tokens.textOnAccent.withValues(alpha: 0.1)
                                : tokens.textPrimary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            LucideIcons.download,
                            color: tokens.textPrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Offline Library',
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: tokens.textPrimary,
                              ),
                            ),
                            Text(
                              'Download playlists for offline playback',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: tokens.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Playlist Grid
                  Expanded(
                    child: BlocBuilder<OfflineLibraryBloc, OfflineLibraryState>(
                      builder: (context, state) {
                        if (state.status == OfflineLibraryStatus.loading) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: isDarkMode
                                  ? tokens.techAccent
                                  : tokens.techAccent,
                            ),
                          );
                        }

                        if (state.status == OfflineLibraryStatus.error) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.alertCircle,
                                  size: 48,
                                  color: tokens.error.withValues(alpha: 0.7),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  state.errorMessage ?? 'Failed to load',
                                  style: GoogleFonts.inter(
                                    color: isDarkMode
                                        ? tokens.textSecondary
                                        : tokens.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        if (state.playlists.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.folderOpen,
                                  size: 56,
                                  color: tokens.textTertiary
                                      .withValues(alpha: 0.55),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No playlists available',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    color: tokens.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          itemCount: state.playlists.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final playlist = state.playlists[index];
                            return OfflinePlaylistCard(
                              playlist: playlist,
                              isDarkMode: isDarkMode,
                              onDownload: () {
                                context.read<OfflineLibraryBloc>().add(
                                      StartDownloadPlaylist(playlist.id),
                                    );
                              },
                              onDelete: () {
                                context.read<OfflineLibraryBloc>().add(
                                      RemovePlaylist(playlist.id),
                                    );
                              },
                            );
                          },
                        );
                      },
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
}

class OfflinePlaylistCard extends StatelessWidget {
  final OfflinePlaylist playlist;
  final bool isDarkMode;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const OfflinePlaylistCard({
    super.key,
    required this.playlist,
    required this.isDarkMode,
    required this.onDownload,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final moodGradient = MoodColorHelper.gradientFor(playlist.moodName);
    final shadowColor = MoodColorHelper.shadowColorFor(playlist.moodName);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.bgContainer,
            tokens.bgElevated,
          ],
        ),
        border: Border.all(
          color: tokens.borderSecondary,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: playlist.downloadStatus == DownloadStatus.downloading
                ? null
                : () {},
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Mood Icon with Gradient
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: moodGradient,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: shadowColor,
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      LucideIcons.music,
                      color: tokens.textOnAccent,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Playlist Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${playlist.moodName} Backup',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${playlist.trackCount} tracks • ${playlist.totalSizeMB.toStringAsFixed(1)} MB',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: tokens.textSecondary,
                          ),
                        ),
                        if (playlist.downloadStatus ==
                            DownloadStatus.downloading) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: playlist.downloadProgress ?? 0.0,
                              backgroundColor: tokens.trackBg,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                moodGradient.colors.first,
                              ),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${((playlist.downloadProgress ?? 0.0) * 100).toStringAsFixed(0)}%',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: moodGradient.colors.first,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Action Button
                  _buildActionButton(context, moodGradient),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, LinearGradient gradient) {
    final tokens = context.camsTokens;

    switch (playlist.downloadStatus) {
      case DownloadStatus.notDownloaded:
        return GestureDetector(
          onTap: onDownload,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              LucideIcons.download,
              color: tokens.textOnAccent,
              size: 20,
            ),
          ),
        );

      case DownloadStatus.downloading:
        return SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(
            value: playlist.downloadProgress,
            strokeWidth: 3,
            backgroundColor: tokens.trackBg,
            valueColor: AlwaysStoppedAnimation<Color>(
              gradient.colors.first,
            ),
          ),
        );

      case DownloadStatus.downloaded:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tokens.success.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: tokens.success.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                LucideIcons.checkCircle2,
                color: tokens.success,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tokens.error.withValues(
                    alpha: isDarkMode ? 0.15 : 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.trash2,
                  color: tokens.error,
                  size: 18,
                ),
              ),
            ),
          ],
        );
    }
  }
}
