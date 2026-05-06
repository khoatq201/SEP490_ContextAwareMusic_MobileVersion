import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../features/home/domain/entities/song_entity.dart';
import '../theme/cams_theme_tokens.dart';
import 'select_playlist_bottom_sheet.dart';
import 'shared_catalog_badge.dart';
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
    this.showPlayNow = true,
    this.showPlayNext = false,
    this.playNowLabel = 'Play now',
    this.playNextLabel = 'Play next',
    this.enableAddToQueue = false,
    this.addToQueueLabel = 'Add to queue',
    this.enableGoToAlbum = false,
    this.enableGoToArtist = true,
    this.forwardPlayNowToOptionHandler = false,
    this.enabled = true,
    this.optionsEnabled,
    this.badge,
  });

  final SongEntity song;
  final VoidCallback? onTap;

  /// Called for any [SongOption] not handled internally.
  /// `addToPlaylist` → opens [SelectPlaylistBottomSheet].
  /// `playNow`       → calls [onTap].
  /// Everything else is forwarded here.
  final ValueChanged<SongOption>? onOptionSelected;
  final bool showPlayNow;
  final bool showPlayNext;
  final String playNowLabel;
  final String playNextLabel;
  final bool enableAddToQueue;
  final String addToQueueLabel;
  final bool enableGoToAlbum;
  final bool enableGoToArtist;
  final bool forwardPlayNowToOptionHandler;
  final bool enabled;
  final bool? optionsEnabled;
  final Widget? badge;

  void _openOptions(BuildContext context) {
    if (!(optionsEnabled ?? enabled)) return;
    showModalBottomSheet<SongOption>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SongOptionsBottomSheet(
        song: song,
        showPlayNow: showPlayNow,
        showPlayNext: showPlayNext,
        playNowLabel: playNowLabel,
        playNextLabel: playNextLabel,
        enableAddToQueue: enableAddToQueue,
        addToQueueLabel: addToQueueLabel,
        enableGoToAlbum: enableGoToAlbum,
        enableGoToArtist: enableGoToArtist,
      ),
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
          return;
        case SongOption.playNow:
          if (forwardPlayNowToOptionHandler && onOptionSelected != null) {
            onOptionSelected!.call(option);
          } else {
            onTap?.call();
          }
          return;
        case SongOption.goToArtist:
          final artist = navigableSongArtist(song.artist);
          if (artist == null) return;
          context.go('/search/artist/${Uri.encodeComponent(artist)}');
          return;
        default:
          onOptionSelected?.call(option);
          return;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final mutedColor = tokens.textSecondary;
    final primaryColor = tokens.textPrimary;

    return Opacity(
      opacity: enabled ? 1 : 0.58,
      child: InkWell(
        onTap: enabled ? onTap : null,
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
                          errorBuilder: (_, __, ___) => const _ArtFallback(),
                        )
                      : const _ArtFallback(),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            song.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: mutedColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          badge!,
                        ],
                        if (song.isSharedCatalog) ...[
                          const SizedBox(width: 8),
                          const SharedCatalogBadge(compact: true),
                        ],
                      ],
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
                onPressed: (optionsEnabled ?? enabled)
                    ? () => _openOptions(context)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Internal fallback artwork ─────────────────────────────────────────────────
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
