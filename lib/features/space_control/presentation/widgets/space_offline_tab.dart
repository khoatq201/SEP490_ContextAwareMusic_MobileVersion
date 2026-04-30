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

class SpaceOfflineTab extends StatelessWidget {
  final bool isDarkMode;

  const SpaceOfflineTab({
    super.key,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return BlocBuilder<OfflineLibraryBloc, OfflineLibraryState>(
      builder: (context, state) {
        if (state.status == OfflineLibraryStatus.loading) {
          return Center(
            child: CircularProgressIndicator(
              color: tokens.techAccent,
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
                  size: 56,
                  color: tokens.error.withValues(alpha: 0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  state.errorMessage ?? 'Failed to load playlists',
                  style: GoogleFonts.inter(
                    color: tokens.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            // Storage Status Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: _StorageStatusCard(isDarkMode: isDarkMode),
              ),
            ),

            // Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.hardDrive,
                      size: 20,
                      color: tokens.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Available Playlists',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${state.playlists.length} playlists',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: tokens.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Playlist Cards
            if (state.playlists.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.folderOpen,
                        size: 64,
                        color: tokens.textTertiary.withValues(alpha: 0.55),
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
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final playlist = state.playlists[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OfflinePlaylistCard(
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
                        ),
                      );
                    },
                    childCount: state.playlists.length,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StorageStatusCard extends StatelessWidget {
  final bool isDarkMode;

  const _StorageStatusCard({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    // Mock storage data - replace with real data later
    const usedGB = 1.2;
    const totalGB = 4.0;
    const progress = usedGB / totalGB;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.bgContainer.withValues(alpha: 0.95),
            tokens.bgElevated.withValues(alpha: 0.95),
          ],
        ),
        border: Border.all(
          color: tokens.borderSecondary,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.shadow.withValues(alpha: isDarkMode ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tokens.techAccent.withValues(
                        alpha: isDarkMode ? 0.15 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.database,
                      color: tokens.techAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device Storage',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${usedGB.toStringAsFixed(1)} GB / ${totalGB.toStringAsFixed(0)} GB Used',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: tokens.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: tokens.success.withValues(
                        alpha: isDarkMode ? 0.15 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: tokens.success.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: tokens.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: tokens.trackBg,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    tokens.techAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflinePlaylistCard extends StatelessWidget {
  final OfflinePlaylist playlist;
  final bool isDarkMode;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _OfflinePlaylistCard({
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
            color: shadowColor.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: playlist.downloadStatus == DownloadStatus.downloading
              ? null
              : () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Mood Icon with Gradient
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: moodGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    LucideIcons.music,
                    color: tokens.textOnAccent,
                    size: 26,
                  ),
                ),

                const SizedBox(width: 14),

                // Playlist Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${playlist.moodName} Fallback',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
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
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: playlist.downloadProgress ?? 0.0,
                                  backgroundColor: tokens.trackBg,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    moodGradient.colors.first,
                                  ),
                                  minHeight: 5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${((playlist.downloadProgress ?? 0.0) * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: moodGradient.colors.first,
                              ),
                            ),
                          ],
                        ),
                      ] else if (playlist.downloadStatus ==
                          DownloadStatus.downloaded) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.checkCircle2,
                              size: 14,
                              color: tokens.success,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ready for playback',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: tokens.success,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildActionButton(BuildContext context, LinearGradient gradient) {
    final tokens = context.camsTokens;

    switch (playlist.downloadStatus) {
      case DownloadStatus.notDownloaded:
        return GestureDetector(
          onTap: onDownload,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(
                color: gradient.colors.first.withValues(alpha: 0.5),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.download,
              color: gradient.colors.first,
              size: 20,
            ),
          ),
        );

      case DownloadStatus.downloading:
        return SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: playlist.downloadProgress,
            strokeWidth: 2.5,
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tokens.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: tokens.success.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                LucideIcons.checkCircle2,
                color: tokens.success,
                size: 18,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: tokens.error.withValues(
                    alpha: isDarkMode ? 0.15 : 0.1,
                  ),
                  borderRadius: BorderRadius.circular(10),
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
