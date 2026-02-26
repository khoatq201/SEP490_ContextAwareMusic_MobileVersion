import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/home/domain/entities/song_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/session/session_cubit.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enum: the set of actions the user can pick from the bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
enum SongOption {
  addToPlaylist,
  playNow,
  // Reserved for future use:
  addToQueue,
  viewArtist,
  block,
  share,
}

// ─────────────────────────────────────────────────────────────────────────────
// SongOptionsBottomSheet
//
// Usage:
//   final option = await showModalBottomSheet<SongOption>(
//     context: context,
//     useRootNavigator: true,
//     isScrollControlled: true,
//     backgroundColor: Colors.transparent,
//     builder: (_) => SongOptionsBottomSheet(song: song),
//   );
// ─────────────────────────────────────────────────────────────────────────────
class SongOptionsBottomSheet extends StatelessWidget {
  const SongOptionsBottomSheet({super.key, required this.song});

  final SongEntity song;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final isPlayback = session.isPlaybackDevice;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final cardColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.04);
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.white60 : Colors.black45;
    final dividerColor = isDark ? Colors.white12 : Colors.black12;

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
            const SizedBox(height: 16),

            // ── Song identity card ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // Album art
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 50,
                        height: 50,
                        child: song.coverUrl != null
                            ? Image.network(
                                song.coverUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _ArtFallback(isDark: isDark),
                              )
                            : _ArtFallback(isDark: isDark),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title + artist
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Duration badge
                    Text(
                      song.formattedDuration,
                      style: GoogleFonts.inter(
                        color: textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),
            Divider(color: dividerColor, height: 1, indent: 16, endIndent: 16),

            if (!isPlayback)
              // ── Thêm vào Playlist ────────────────────────────────────────
              ListTile(
              leading: Icon(
                Icons.playlist_add,
                color: isDark ? Colors.white70 : Colors.black54,
                size: 24,
              ),
              title: Text(
                'Thêm vào Playlist',
                style: GoogleFonts.inter(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => Navigator.pop(context, SongOption.addToPlaylist),
            ),

            // ── Phát ngay ────────────────────────────────────────────────
            ListTile(
              leading: Icon(
                Icons.play_circle_outline,
                color: isDark ? Colors.white70 : Colors.black54,
                size: 24,
              ),
              title: Text(
                'Phát ngay',
                style: GoogleFonts.inter(
                  color: textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => Navigator.pop(context, SongOption.playNow),
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
} // ── Art fallback ──────────────────────────────────────────────────────────────

class _ArtFallback extends StatelessWidget {
  const _ArtFallback({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark
          ? Colors.white.withOpacity(0.07)
          : Colors.black.withOpacity(0.06),
      child: Icon(
        LucideIcons.music4,
        size: 22,
        color: isDark ? Colors.white30 : Colors.black26,
      ),
    );
  }
}
