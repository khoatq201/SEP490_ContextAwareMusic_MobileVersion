import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/home/domain/entities/playlist_entity.dart';
import '../../features/home/domain/entities/song_entity.dart';
import '../../features/library/data/datasources/mock_library_data_source.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SelectPlaylistBottomSheet
//
// Shows all user-created playlists so the user can pick where to add [song].
//
// Backend wiring checklist:
//   1. Replace _fetchPlaylists() with a PlaylistRepository / Bloc call.
//   2. Replace the body of _addSongToPlaylist() with:
//        await AddSongToPlaylistUseCase()(songId: song.id, playlistId: playlist.id)
//   3. Handle errors and show appropriate feedback.
// ─────────────────────────────────────────────────────────────────────────────
class SelectPlaylistBottomSheet extends StatefulWidget {
  const SelectPlaylistBottomSheet({super.key, required this.song});

  final SongEntity song;

  @override
  State<SelectPlaylistBottomSheet> createState() =>
      _SelectPlaylistBottomSheetState();
}

class _SelectPlaylistBottomSheetState extends State<SelectPlaylistBottomSheet> {
  late List<PlaylistEntity> _playlists;
  String? _loadingId; // id of the playlist currently being processed

  @override
  void initState() {
    super.initState();
    _playlists = _fetchPlaylists();
  }

  // ── Data fetching stub ───────────────────────────────────────────────────
  /// TODO: Replace with a call to PlaylistRepository / LibraryBloc.
  List<PlaylistEntity> _fetchPlaylists() =>
      MockLibraryDataSource.getSavedPlaylists();

  // ── Add logic stub ───────────────────────────────────────────────────────
  /// TODO: Replace body with:
  ///   await AddSongToPlaylistUseCase()(
  ///     songId: widget.song.id, playlistId: playlist.id);
  Future<void> _addSongToPlaylist(PlaylistEntity playlist) async {
    setState(() => _loadingId = playlist.id);

    // Mock 500ms processing delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.pop(context); // close this sheet

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã thêm vào ${playlist.title}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
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
            // ── Drag handle ──────────────────────────────────────────────
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

            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Thêm vào Playlist',
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

            // ── Song identity chip ───────────────────────────────────────
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
                        '${widget.song.title} · ${widget.song.artist}',
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

            // ── Playlist list ─────────────────────────────────────────────
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340),
              child: _playlists.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(36),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.music4,
                              size: 40, color: textMuted.withOpacity(0.35)),
                          const SizedBox(height: 12),
                          Text(
                            'Chưa có playlist nào',
                            style: GoogleFonts.inter(
                                color: textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      itemCount: _playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = _playlists[index];
                        final isLoading = _loadingId == playlist.id;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
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
                            '${playlist.totalTracks} bài',
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
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                )
                              : Icon(Icons.add_rounded,
                                  color: textMuted, size: 22),
                          onTap: isLoading
                              ? null
                              : () => _addSongToPlaylist(playlist),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ── Cover fallback ────────────────────────────────────────────────────────────
class _CoverFallback extends StatelessWidget {
  const _CoverFallback({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark
          ? Colors.white.withOpacity(0.07)
          : Colors.black.withOpacity(0.06),
      child: Icon(LucideIcons.music4,
          size: 18, color: isDark ? Colors.white30 : Colors.black26),
    );
  }
}
