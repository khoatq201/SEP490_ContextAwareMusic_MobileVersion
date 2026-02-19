import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/player/player_state.dart' as ps;
import '../../../home/domain/entities/playlist_entity.dart';
import '../../../home/domain/entities/song_entity.dart';
import '../../data/datasources/mock_library_data_source.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Filter options
// ─────────────────────────────────────────────────────────────────────────────
enum _LibraryFilter { playlists, stations, blocked }

extension _LibraryFilterLabel on _LibraryFilter {
  String get label {
    switch (this) {
      case _LibraryFilter.playlists:
        return 'Saved';
      case _LibraryFilter.stations:
        return 'Stations';
      case _LibraryFilter.blocked:
        return 'Blocked';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────
class LibraryTabPage extends StatefulWidget {
  const LibraryTabPage({super.key});

  @override
  State<LibraryTabPage> createState() => _LibraryTabPageState();
}

class _LibraryTabPageState extends State<LibraryTabPage> {
  _LibraryFilter _filter = _LibraryFilter.playlists;

  // ── Mock state — swap for Bloc when backend is ready ──────────────────────
  late List<PlaylistEntity> _savedPlaylists;
  late List<SongEntity> _blockedSongs;

  @override
  void initState() {
    super.initState();
    _savedPlaylists = MockLibraryDataSource.getSavedPlaylists();
    _blockedSongs = MockLibraryDataSource.getBlockedSongs();
  }

  // ── Create playlist dialog ─────────────────────────────────────────────────
  Future<void> _showCreatePlaylistDialog() async {
    final palette = _Palette.fromBrightness(Theme.of(context).brightness);
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Tạo Playlist mới',
          style: GoogleFonts.poppins(
            color: palette.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: GoogleFonts.inter(color: palette.textPrimary, fontSize: 14),
          cursorColor: palette.accent,
          decoration: InputDecoration(
            hintText: 'VD: Nhạc buổi trưa...',
            hintStyle: GoogleFonts.inter(
                color: palette.textMuted.withOpacity(0.55), fontSize: 14),
            filled: true,
            fillColor: palette.overlay,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: palette.accent, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child:
                Text('Huỷ', style: GoogleFonts.inter(color: palette.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: palette.accent,
              foregroundColor: palette.textOnAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Tạo',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final name = controller.text.trim();
      if (name.isEmpty) return;
      final newPlaylist = PlaylistEntity(
        id: 'new-${DateTime.now().millisecondsSinceEpoch}',
        title: name,
        description: 'Playlist mới',
        songs: const [],
      );
      setState(() => _savedPlaylists.insert(0, newPlaylist));

      if (mounted) {
        context.push('/home/playlist-detail', extra: newPlaylist);
      }
    }
  }

  void _unblockSong(String songId) {
    setState(() => _blockedSongs.removeWhere((s) => s.id == songId));
  }

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.fromBrightness(Theme.of(context).brightness);

    return Scaffold(
      backgroundColor: palette.bg,
      floatingActionButton: BlocBuilder<PlayerBloc, ps.PlayerState>(
        builder: (context, playerState) {
          final bottomPad = playerState.hasTrack ? 144.0 : 80.0;
          return Padding(
            padding: EdgeInsets.only(bottom: bottomPad),
            child: FloatingActionButton(
              onPressed: _showCreatePlaylistDialog,
              backgroundColor: palette.accent,
              foregroundColor: palette.textOnAccent,
              elevation: 6,
              child: const Icon(Icons.add, size: 26),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar ───────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor: palette.bg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 20, bottom: 14, right: 60),
              title: Text(
                'Thư viện nhạc',
                style: GoogleFonts.poppins(
                  color: palette.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              collapseMode: CollapseMode.pin,
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: palette.overlay,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.border),
                  ),
                  child: IconButton(
                    icon: Icon(LucideIcons.search,
                        color: palette.textPrimary, size: 18),
                    splashRadius: 20,
                    onPressed: () {},
                  ),
                ),
              ),
            ],
          ),

          // ── Filter chips ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Wrap(
                spacing: 8,
                children: _LibraryFilter.values.map((f) {
                  final selected = _filter == f;
                  return FilterChip(
                    label: Text(f.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: palette.accent,
                    checkmarkColor: palette.textOnAccent,
                    showCheckmark: false,
                    labelStyle: GoogleFonts.inter(
                      color:
                          selected ? palette.textOnAccent : palette.textMuted,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                    backgroundColor: palette.card,
                    side: BorderSide(
                      color: selected ? palette.accent : palette.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  );
                }).toList(),
              ),
            ),
          ),

          // ── Section label ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Row(
                children: [
                  Text(
                    _sectionTitle,
                    style: GoogleFonts.poppins(
                      color: palette.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _sectionCount,
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Divider ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Divider(
                color: palette.border, height: 1, indent: 20, endIndent: 20),
          ),

          // ── Body ───────────────────────────────────────────────────────
          if (_filter == _LibraryFilter.playlists)
            _savedPlaylists.isEmpty
                ? _emptyPlaylistsSliver(palette)
                : _playlistsSliver(palette)
          else if (_filter == _LibraryFilter.blocked)
            _blockedSongs.isEmpty
                ? _emptyBlockedSliver(palette)
                : _blockedSliver(palette)
          else
            _stationsSliver(palette),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ── Computed helpers ───────────────────────────────────────────────────────

  String get _sectionTitle {
    switch (_filter) {
      case _LibraryFilter.playlists:
        return 'Saved Playlists';
      case _LibraryFilter.stations:
        return 'Your Stations';
      case _LibraryFilter.blocked:
        return 'Blocked Songs';
    }
  }

  String get _sectionCount {
    switch (_filter) {
      case _LibraryFilter.playlists:
        return '${_savedPlaylists.length} playlist';
      case _LibraryFilter.stations:
        return '0 station';
      case _LibraryFilter.blocked:
        return '${_blockedSongs.length} bài';
    }
  }

  // ── Sliver builders ────────────────────────────────────────────────────────

  Widget _playlistsSliver(_Palette palette) {
    return SliverList.builder(
      itemCount: _savedPlaylists.length,
      itemBuilder: (context, index) {
        final playlist = _savedPlaylists[index];
        return _PlaylistTile(
          playlist: playlist,
          palette: palette,
          onTap: () => context.push('/home/playlist-detail', extra: playlist),
        );
      },
    );
  }

  Widget _blockedSliver(_Palette palette) {
    return SliverList.builder(
      itemCount: _blockedSongs.length,
      itemBuilder: (context, index) {
        final song = _blockedSongs[index];
        return _BlockedSongTile(
          song: song,
          palette: palette,
          onUnblock: () => _unblockSong(song.id),
        );
      },
    );
  }

  Widget _emptyPlaylistsSliver(_Palette palette) {
    return SliverFillRemaining(
      child: _EmptyState(
        icon: LucideIcons.bookMarked,
        title: 'Chưa có playlist nào',
        subtitle: 'Lưu playlist yêu thích để xem tại đây',
        actionLabel: 'Browse Playlists',
        onAction: () => context.go('/search'),
        palette: palette,
      ),
    );
  }

  Widget _emptyBlockedSliver(_Palette palette) {
    return SliverFillRemaining(
      child: _EmptyState(
        icon: LucideIcons.shield,
        title: 'Danh sách trống',
        subtitle: 'Bạn chưa chặn bài hát nào',
        palette: palette,
      ),
    );
  }

  Widget _stationsSliver(_Palette palette) {
    return SliverFillRemaining(
      child: _EmptyState(
        icon: LucideIcons.radio,
        title: 'Chưa có station nào',
        subtitle: 'Các radio station bạn lưu sẽ hiện ở đây',
        palette: palette,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Playlist tile
// ─────────────────────────────────────────────────────────────────────────────
class _PlaylistTile extends StatelessWidget {
  const _PlaylistTile({
    required this.playlist,
    required this.palette,
    required this.onTap,
  });

  final PlaylistEntity playlist;
  final _Palette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Cover thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: playlist.coverUrl != null
                      ? Image.network(
                          playlist.coverUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _CoverFallback(palette: palette),
                        )
                      : _CoverFallback(palette: palette),
                ),
              ),
              const SizedBox(width: 14),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: palette.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      playlist.description ??
                          '${playlist.totalTracks} bài nhạc',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Trailing: downloaded badge + track count + chevron
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (playlist.isDownloaded) ...[
                    const Icon(Icons.download_done_rounded,
                        color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    '${playlist.totalTracks} bài',
                    style: GoogleFonts.inter(
                        color: palette.textMuted, fontSize: 11),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      color: palette.textMuted, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Blocked song tile
// ─────────────────────────────────────────────────────────────────────────────
class _BlockedSongTile extends StatelessWidget {
  const _BlockedSongTile({
    required this.song,
    required this.palette,
    required this.onUnblock,
  });

  final SongEntity song;
  final _Palette palette;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(song.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_open_rounded, color: Colors.green, size: 18),
            const SizedBox(width: 6),
            Text(
              'Bỏ chặn',
              style: GoogleFonts.inter(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onUnblock(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: song.coverUrl != null
                    ? Image.network(
                        song.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _CoverFallback(palette: palette, size: 44),
                      )
                    : _CoverFallback(palette: palette, size: 44),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: palette.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Block icon + duration
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(LucideIcons.ban, color: Colors.red.shade300, size: 16),
                const SizedBox(height: 3),
                Text(
                  song.formattedDuration,
                  style:
                      GoogleFonts.inter(color: palette.textMuted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cover fallback
// ─────────────────────────────────────────────────────────────────────────────
class _CoverFallback extends StatelessWidget {
  const _CoverFallback({required this.palette, this.size = 56});
  final _Palette palette;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: palette.overlay,
      child: Icon(LucideIcons.music4,
          color: palette.textMuted.withOpacity(0.5), size: size * 0.4),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Generic empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.palette,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final _Palette palette;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.overlay,
                border: Border.all(color: palette.border, width: 1.5),
              ),
              child: Icon(icon,
                  size: 38, color: palette.textMuted.withOpacity(0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: palette.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(color: palette.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.textOnAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                ),
                icon: const Icon(Icons.search, size: 18),
                label: Text(
                  actionLabel!,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Palette
// ─────────────────────────────────────────────────────────────────────────────
class _Palette {
  const _Palette({
    required this.isDark,
    required this.bg,
    required this.card,
    required this.overlay,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.accentAlt,
    required this.textOnAccent,
    required this.shadow,
  });

  factory _Palette.fromBrightness(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    if (isDark) {
      return _Palette(
        isDark: true,
        bg: AppColors.backgroundDarkPrimary,
        card: AppColors.surfaceDark,
        overlay: Colors.white.withOpacity(0.06),
        border: AppColors.borderDarkMedium,
        textPrimary: AppColors.textDarkPrimary,
        textMuted: AppColors.textDarkSecondary,
        accent: AppColors.primaryCyan,
        accentAlt: AppColors.secondaryLime,
        textOnAccent: AppColors.textDarkPrimary,
        shadow: AppColors.shadowDark,
      );
    }
    return _Palette(
      isDark: false,
      bg: AppColors.backgroundPrimary,
      card: AppColors.surface,
      overlay: AppColors.backgroundSecondary,
      border: AppColors.borderLight,
      textPrimary: AppColors.textPrimary,
      textMuted: AppColors.textTertiary,
      accent: AppColors.primaryOrange,
      accentAlt: AppColors.secondaryTeal,
      textOnAccent: AppColors.textInverse,
      shadow: AppColors.shadow,
    );
  }

  final bool isDark;
  final Color bg;
  final Color card;
  final Color overlay;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
  final Color accentAlt;
  final Color textOnAccent;
  final Color shadow;
}
