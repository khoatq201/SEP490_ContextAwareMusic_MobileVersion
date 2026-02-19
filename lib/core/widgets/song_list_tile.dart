import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/home/domain/entities/song_entity.dart';
import 'select_playlist_bottom_sheet.dart';
import 'song_options_bottom_sheet.dart';

/// A reusable list-tile for displaying a [SongEntity] anywhere in the app
/// (Library, Search results, Playlist detail, etc.).
///
/// Layout:
///   leading  — album art thumbnail (48×48, rounded-10)
///   title    — song.title (bold, 14sp)
///   subtitle — song.artist (muted, 12sp)
///   trailing — [IconButton] Icons.more_vert → [SongOptionsBottomSheet]
class SongListTile extends StatelessWidget {
  const SongListTile({
    super.key,
    required this.song,
    this.onTap,
    this.onOptionSelected,
  });

  final SongEntity song;
  final VoidCallback? onTap;

  /// Called for any [SongOption] not handled internally.
  /// `addToPlaylist` → opens [SelectPlaylistBottomSheet].
  /// `playNow`       → calls [onTap].
  /// Everything else is forwarded here.
  final ValueChanged<SongOption>? onOptionSelected;

  void _openOptions(BuildContext context) {
    showModalBottomSheet<SongOption>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SongOptionsBottomSheet(song: song),
    ).then((option) {
      if (option == null) return;
      if (!context.mounted) return;

      switch (option) {
        case SongOption.addToPlaylist:
          showModalBottomSheet<void>(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => SelectPlaylistBottomSheet(song: song),
          );
        case SongOption.playNow:
          onTap?.call();
        default:
          onOptionSelected?.call(option);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? Colors.white54 : Colors.black45;
    final primaryColor = isDark ? Colors.white : Colors.black87;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // ── Leading: album art ───────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 48,
                height: 48,
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

            const SizedBox(width: 14),

            // ── Title + Subtitle ─────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: mutedColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // ── Trailing: more options ───────────────────────────────────
            IconButton(
              icon: Icon(Icons.more_vert, color: mutedColor, size: 20),
              splashRadius: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              onPressed: () => _openOptions(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Internal fallback artwork ─────────────────────────────────────────────────
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
