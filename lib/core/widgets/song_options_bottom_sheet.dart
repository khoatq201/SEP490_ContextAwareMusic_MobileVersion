import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/home/domain/entities/song_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/session/session_cubit.dart';
import '../../core/enums/user_role.dart';
import '../theme/cams_theme_tokens.dart';

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
    final tokens = context.camsTokens;
    final bgColor = tokens.bgElevated;
    final cardColor = tokens.bgLayout;
    final textPrimary = tokens.textPrimary;
    final textMuted = tokens.textSecondary;
    final dividerColor = tokens.divider;

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
                  color: tokens.border,
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
                                    const _ArtFallback(),
                              )
                            : const _ArtFallback(),
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
  const _ArtFallback();

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;

    return Container(
      color: tokens.bgElevated,
      child: Icon(
        LucideIcons.music4,
        size: 22,
        color: tokens.textTertiary.withValues(alpha: 0.65),
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
    final tokens = context.camsTokens;
    final iconColor = enabled
        ? tokens.textSecondary
        : tokens.textTertiary.withValues(alpha: 0.55);
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
