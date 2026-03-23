import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/error/exceptions.dart';
import '../../features/home/domain/entities/playlist_entity.dart';
import '../../features/home/domain/entities/song_entity.dart';
import '../../features/playlists/data/datasources/playlist_remote_datasource.dart';
import '../../injection_container.dart';

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
      if (!mounted) return;
      setState(() {
        _playlists = response.items
            .map(
              (playlist) => PlaylistEntity(
                id: playlist.id,
                title: playlist.name,
                description: playlist.description,
                coverUrl: null,
                songs: const [],
                overrideTrackCount: playlist.trackCount,
              ),
            )
            .toList();
        _loadingPlaylists = false;
      });
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingPlaylists = false;
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingPlaylists = false;
        _errorMessage = 'Failed to load playlists.';
      });
    }
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
      _showErrorSnackBar(e.message);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.white60 : Colors.black45;
    final dividerColor = isDark ? Colors.white12 : Colors.black12;
    final chipBg = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.04);

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
                  color: isDark ? Colors.white24 : Colors.black26,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 32,
              color: textMuted,
            ),
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: textMuted,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadPlaylists,
              child: Text(
                'Retry',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
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
                size: 40, color: textMuted.withOpacity(0.35)),
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
              child: playlist.coverUrl != null
                  ? Image.network(
                      playlist.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _CoverFallback(isDark: isDark),
                    )
                  : _CoverFallback(isDark: isDark),
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
          subtitle: Text(
            '${playlist.totalTracks} tracks',
            style: GoogleFonts.inter(
              color: textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                )
              : Icon(Icons.add_rounded, color: textMuted, size: 22),
          onTap: isLoading ? null : () => _addSongToPlaylist(playlist),
        );
      },
    );
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark
          ? Colors.white.withOpacity(0.07)
          : Colors.black.withOpacity(0.06),
      child: Icon(
        LucideIcons.music4,
        size: 18,
        color: isDark ? Colors.white30 : Colors.black26,
      ),
    );
  }
}
