import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/home/domain/entities/song_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/session/session_cubit.dart';
import '../../core/enums/user_role.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enum: the set of actions the user can pick from the bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
enum SongOption {
  addToPlaylist,
  playNow,
  playNext,
  addToQueue,
  goToAlbum,
  goToArtist,
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
  const SongOptionsBottomSheet({
    super.key,
    required this.song,
    this.showPlayNow = true,
    this.showPlayNext = false,
    this.playNowLabel = 'Play now',
    this.playNextLabel = 'Play next',
    this.enableAddToQueue = false,
    this.addToQueueLabel = 'Add to queue',
    this.enableGoToAlbum = false,
    this.enableGoToArtist = false,
  });

  final SongEntity song;
  final bool showPlayNow;
  final bool showPlayNext;
  final String playNowLabel;
  final String playNextLabel;
  final bool enableAddToQueue;
  final String addToQueueLabel;
  final bool enableGoToAlbum;
  final bool enableGoToArtist;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final canAddToPlaylist = !session.isPlaybackDevice &&
        (session.currentRole == UserRole.brandManager ||
            session.currentRole == UserRole.storeManager);
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

            if (canAddToPlaylist)
              _OptionTile(
                icon: Icons.playlist_add,
                label: 'Add to Playlist',
                enabled: true,
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
                onTap: () => Navigator.pop(context, SongOption.addToPlaylist),
              ),
            if (showPlayNow)
              _OptionTile(
                icon: Icons.play_circle_outline,
                label: playNowLabel,
                enabled: true,
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
                onTap: () => Navigator.pop(context, SongOption.playNow),
              ),
            if (showPlayNext)
              _OptionTile(
                icon: Icons.skip_next_outlined,
                label: playNextLabel,
                enabled: true,
                isDark: isDark,
                textPrimary: textPrimary,
                textMuted: textMuted,
                onTap: () => Navigator.pop(context, SongOption.playNext),
              ),
            _OptionTile(
              icon: Icons.queue_music_outlined,
              label: addToQueueLabel,
              enabled: enableAddToQueue,
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
              onTap: enableAddToQueue
                  ? () => Navigator.pop(context, SongOption.addToQueue)
                  : null,
            ),
            _OptionTile(
              icon: Icons.album_outlined,
              label: 'Go to album',
              enabled: enableGoToAlbum,
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
              onTap: enableGoToAlbum
                  ? () => Navigator.pop(context, SongOption.goToAlbum)
                  : null,
            ),
            _OptionTile(
              icon: Icons.person_outline,
              label: 'Go to artist',
              enabled: enableGoToArtist,
              isDark: isDark,
              textPrimary: textPrimary,
              textMuted: textMuted,
              onTap: enableGoToArtist
                  ? () => Navigator.pop(context, SongOption.goToArtist)
                  : null,
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

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = enabled
        ? (isDark ? Colors.white70 : Colors.black54)
        : (isDark ? Colors.white24 : Colors.black26);
    final textColor = enabled ? textPrimary : textMuted;

    return ListTile(
      enabled: enabled,
      leading: Icon(icon, color: iconColor, size: 24),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: textColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}
