import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../error/error_mapper.dart';
import '../error/exceptions.dart';
import '../presentation/app_feedback.dart';
import 'app_feedback_presenter.dart';
import 'app_inline_error_card.dart';
import 'playlist_cover_collage.dart';
import 'shared_catalog_badge.dart';
import '../../features/home/domain/entities/playlist_entity.dart';
import '../../features/home/domain/entities/song_entity.dart';
import '../../features/playlists/data/datasources/playlist_remote_datasource.dart';
import '../../features/playlists/domain/entities/api_playlist.dart';
import '../../injection_container.dart';
import '../theme/cams_theme_tokens.dart';

class SelectPlaylistBottomSheet extends StatefulWidget {
  const SelectPlaylistBottomSheet({super.key, required this.song});

  final SongEntity song;

  @override
  State<SelectPlaylistBottomSheet> createState() =>
      _SelectPlaylistBottomSheetState();
}

class _SelectPlaylistBottomSheetState extends State<SelectPlaylistBottomSheet> {
  List<PlaylistEntity> _playlists = const [];
  bool _loadingPlaylists = true;
  String? _errorMessage;
  String? _loadingId;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _loadingPlaylists = true;
      _errorMessage = null;
    });

    try {
      final response = await sl<PlaylistRemoteDataSource>().getPlaylists(
        page: 1,
        pageSize: 100,
      );
      final playlistDs = sl<PlaylistRemoteDataSource>();
      final detailsById = await _loadPlaylistDetails(
        playlistDs,
        response.items,
      );
      if (!mounted) return;
      setState(() {
        _playlists = response.items
            .map(
              (playlist) => _playlistEntityFromApi(
                playlist,
                detailsById[playlist.id],
              ),
            )
            .toList();
        _loadingPlaylists = false;
      });
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPlaylists = false;
        _errorMessage = ErrorMapper.sanitizeMessageForDisplay(
          e.message,
          kind: e.kind,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingPlaylists = false;
        _errorMessage = 'Failed to load playlists.';
      });
    }
  }

  Future<Map<String, ApiPlaylist>> _loadPlaylistDetails(
    PlaylistRemoteDataSource playlistDs,
    List<ApiPlaylist> playlists,
  ) async {
    final entries = await Future.wait(
      playlists.map((playlist) async {
        try {
          final detail = await playlistDs.getPlaylistById(playlist.id);
          return MapEntry(playlist.id, detail);
        } catch (_) {
          return null;
        }
      }),
    );

    return {
      for (final entry in entries)
        if (entry != null) entry.key: entry.value,
    };
  }

  PlaylistEntity _playlistEntityFromApi(
    ApiPlaylist playlist,
    ApiPlaylist? detail,
  ) {
    final tracks = detail?.tracks ?? const [];
    return PlaylistEntity(
      id: playlist.id,
      brandId: playlist.brandId,
      title: playlist.name,
      description: playlist.description,
      coverUrl: null,
      songs: tracks
          .map(
            (track) => SongEntity(
              id: track.trackId,
              brandId: track.brandId,
              title: track.title ?? 'Unknown',
              artist: track.artist ?? 'Unknown',
              duration: track.effectiveDuration,
              coverUrl: track.coverImageUrl,
              streamUrl: track.hlsUrl,
            ),
          )
          .toList(growable: false),
      overrideTrackCount: playlist.trackCount,
    );
  }

  Future<void> _addSongToPlaylist(PlaylistEntity playlist) async {
    setState(() => _loadingId = playlist.id);
    try {
      await sl<PlaylistRemoteDataSource>().addTracksToPlaylist(
        playlistId: playlist.id,
        trackIds: [widget.song.id],
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added to ${playlist.title}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    } on ServerException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(
        ErrorMapper.sanitizeMessageForDisplay(
          e.message,
          kind: e.kind,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showErrorSnackBar('Failed to add song to playlist.');
    } finally {
      if (mounted) {
        setState(() => _loadingId = null);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    AppFeedbackPresenter.show(
      context,
      AppFeedback.error(message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = context.camsTokens;
    final bgColor = tokens.bgElevated;
    final textPrimary = tokens.textPrimary;
    final textMuted = tokens.textSecondary;
    final dividerColor = tokens.divider;
    final chipBg = tokens.bgLayout;

    return SafeArea(
      bottom: true,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Add to Playlist',
                    style: GoogleFonts.poppins(
                      color: textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child:
                        Icon(LucideIcons.xCircle, color: textMuted, size: 22),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.audiotrack_rounded, color: textMuted, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${widget.song.title} - ${widget.song.artist}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          color: textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(color: dividerColor, height: 1, indent: 16, endIndent: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: _buildPlaylistBody(
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaylistBody({
    required bool isDark,
    required Color textPrimary,
    required Color textMuted,
  }) {
    if (_loadingPlaylists) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: AppInlineErrorCard(
          title: 'Cannot load playlists',
          message: _errorMessage!,
          onRetry: _loadPlaylists,
          retryLabel: 'Retry',
        ),
      );
    }

    if (_playlists.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.music4,
                size: 40, color: textMuted.withValues(alpha: 0.35)),
            const SizedBox(height: 12),
            Text(
              'No playlists yet',
              style: GoogleFonts.inter(color: textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        final isLoading = _loadingId == playlist.id;

        return ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 46,
              height: 46,
              child: PlaylistCoverCollage(
                coverUrls: playlist.trackCoverUrls,
                fallbackCoverUrl: playlist.coverUrl,
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                iconColor: Theme.of(context).colorScheme.primary,
                iconSize: 22,
              ),
            ),
          ),
          title: Text(
            playlist.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Row(
            children: [
              Text(
                '${playlist.totalTracks} tracks',
                style: GoogleFonts.inter(
                  color: textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (playlist.isSharedCatalog) ...[
                const SizedBox(width: 8),
                const SharedCatalogBadge(compact: true),
              ],
            ],
          ),
          trailing: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.camsTokens.textSecondary,
                  ),
                )
              : Icon(Icons.add_rounded, color: textMuted, size: 22),
          onTap: isLoading ? null : () => _addSongToPlaylist(playlist),
        );
      },
    );
  }
}
