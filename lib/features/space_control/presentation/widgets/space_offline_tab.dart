import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    return BlocBuilder<OfflineLibraryBloc, OfflineLibraryState>(
      builder: (context, state) {
        if (state.status == OfflineLibraryStatus.loading) {
          return Center(
            child: CircularProgressIndicator(
              color: isDarkMode
                  ? const Color(0xFF00E5FF)
                  : const Color(0xFF2196F3),
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
                  color: Colors.red.withOpacity(0.7),
                ),
                const SizedBox(height: 16),
                Text(
                  state.errorMessage ?? 'Failed to load playlists',
                  style: GoogleFonts.inter(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
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
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Available Playlists',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${state.playlists.length} playlists',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white60 : Colors.black45,
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
                        color: isDarkMode ? Colors.white30 : Colors.black26,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No playlists available',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: isDarkMode ? Colors.white60 : Colors.black45,
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
          colors: isDarkMode
              ? [
                  const Color(0xFF1A1A1A).withOpacity(0.95),
                  const Color(0xFF121212).withOpacity(0.95),
                ]
              : [
                  Colors.white.withOpacity(0.95),
                  Colors.grey.shade50.withOpacity(0.95),
                ],
        ),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
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
                      color: isDarkMode
                          ? const Color(0xFF00E5FF).withOpacity(0.15)
                          : const Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.database,
                      color: isDarkMode
                          ? const Color(0xFF00E5FF)
                          : const Color(0xFF2196F3),
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
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${usedGB.toStringAsFixed(1)} GB / ${totalGB.toStringAsFixed(0)} GB Used',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: isDarkMode ? Colors.white60 : Colors.black54,
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
                      color: isDarkMode
                          ? Colors.green.withOpacity(0.15)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
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
                  backgroundColor: isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.08),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDarkMode
                        ? const Color(0xFF00E5FF)
                        : const Color(0xFF2196F3),
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
    final moodGradient = MoodColorHelper.gradientFor(playlist.moodName);
    final shadowColor = MoodColorHelper.shadowColorFor(playlist.moodName);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDarkMode
              ? [
                  const Color(0xFF1A1A1A),
                  const Color(0xFF121212),
                ]
              : [
                  Colors.white,
                  Colors.grey.shade50,
                ],
        ),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.15),
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
                        color: shadowColor.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.music,
                    color: Colors.white,
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
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${playlist.trackCount} tracks • ${playlist.totalSizeMB.toStringAsFixed(1)} MB',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white60 : Colors.black54,
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
                                  backgroundColor: isDarkMode
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.08),
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
                            const Icon(
                              LucideIcons.checkCircle2,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Ready for playback',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
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
                _buildActionButton(moodGradient),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(LinearGradient gradient) {
    switch (playlist.downloadStatus) {
      case DownloadStatus.notDownloaded:
        return GestureDetector(
          onTap: onDownload,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              border: Border.all(
                color: gradient.colors.first.withOpacity(0.5),
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
            backgroundColor: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
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
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.green.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                LucideIcons.checkCircle2,
                color: Colors.green,
                size: 18,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.red.withOpacity(0.15)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  LucideIcons.trash2,
                  color: Colors.red.shade400,
                  size: 18,
                ),
              ),
            ),
          ],
        );
    }
  }
}
