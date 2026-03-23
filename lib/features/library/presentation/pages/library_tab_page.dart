import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../injection_container.dart';
import '../../../home/domain/entities/playlist_entity.dart';
import '../../../home/domain/entities/song_entity.dart';
import '../../../playlists/data/datasources/playlist_remote_datasource.dart';
import '../../../tracks/data/datasources/track_remote_datasource.dart';

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

  List<PlaylistEntity> _savedPlaylists = [];
  List<SongEntity> _blockedSongs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    try {
      final playlistDs = sl<PlaylistRemoteDataSource>();
      final resp = await playlistDs.getPlaylists(page: 1, pageSize: 50);
      if (!mounted) return;
      setState(() {
        _savedPlaylists = resp.items
            .map((p) => PlaylistEntity(
                  id: p.id,
                  title: p.name,
                  description: p.description,
                  coverUrl: null,
                  songs: const [],
                  overrideTrackCount: p.trackCount,
                ))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
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
          'Create New Playlist',
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
            hintText: 'E.g.: Lunch music...',
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
            child: Text('Cancel',
                style: GoogleFonts.inter(color: palette.textMuted)),
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
            child: Text('Create',
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
        description: 'New Playlist',
        songs: const [],
      );
      setState(() => _savedPlaylists.insert(0, newPlaylist));

      if (mounted) {
        context.push('/home/playlist-detail', extra: newPlaylist.id);
      }
    }
  }

  Future<void> _openUploadTrackSheet() async {
    final uploaded = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _UploadTrackBottomSheet(),
    );

    if (!mounted || uploaded != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Track uploaded successfully.',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _unblockSong(String songId) {
    setState(() => _blockedSongs.removeWhere((s) => s.id == songId));
  }

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.fromBrightness(Theme.of(context).brightness);
    final session = context.watch<SessionCubit>().state;
    final canUploadTrack = !session.isPlaybackDevice &&
        session.currentRole == UserRole.brandManager;
    final playerState = context.watch<PlayerBloc>().state;
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    // Some Android devices/reporting modes can return 0 here while the shell
    // still renders a tall bottom bar. Keep a conservative fallback so FAB
    // never sinks into the tab bar.
    final effectiveSafeBottom = safeBottom > 0 ? safeBottom : 32.0;
    final miniPlayerHeight = playerState.hasTrack ? 72.0 : 0.0;
    final shellOverlayHeight = 64.0 + effectiveSafeBottom + miniPlayerHeight;
    final fabBottomOffset = shellOverlayHeight + 32.0;
    final contentBottomSpacing = shellOverlayHeight + 164.0;

    return Scaffold(
      backgroundColor: palette.bg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── SliverAppBar ───────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                expandedHeight: 92,
                backgroundColor: palette.bg,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 14),
                  title: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'REMOTE CONTROLLING',
                        style: GoogleFonts.inter(
                          color: palette.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Music Library',
                        style: GoogleFonts.poppins(
                          color: palette.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      margin:
                          const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                      decoration: BoxDecoration(
                        color: palette.overlay,
                        shape: BoxShape.circle,
                        border: Border.all(color: palette.border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          LucideIcons.search,
                          color: palette.textPrimary,
                          size: 18,
                        ),
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
                          color: selected
                              ? palette.textOnAccent
                              : palette.textMuted,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                        backgroundColor: palette.card,
                        side: BorderSide(
                          color: selected ? palette.accent : palette.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                  color: palette.border,
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                ),
              ),

              // ── Body ───────────────────────────────────────────────────────
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_filter == _LibraryFilter.playlists)
                _savedPlaylists.isEmpty
                    ? _emptyPlaylistsSliver(palette)
                    : _playlistsSliver(palette)
              else if (_filter == _LibraryFilter.blocked)
                _blockedSongs.isEmpty
                    ? _emptyBlockedSliver(palette)
                    : _blockedSliver(palette)
              else
                _stationsSliver(palette),

              SliverToBoxAdapter(child: SizedBox(height: contentBottomSpacing)),
            ],
          ),
          Positioned(
            right: 16,
            bottom: fabBottomOffset,
            child: FloatingActionButton(
              onPressed: _showCreatePlaylistDialog,
              backgroundColor: palette.accent,
              foregroundColor: palette.textOnAccent,
              elevation: 6,
              child: const Icon(Icons.add, size: 26),
            ),
          ),
          if (canUploadTrack)
            Positioned(
              right: 16,
              bottom: fabBottomOffset + 74,
              child: FloatingActionButton.small(
                heroTag: 'upload-track-fab',
                onPressed: _openUploadTrackSheet,
                backgroundColor: palette.card,
                foregroundColor: palette.textPrimary,
                elevation: 4,
                child: const Icon(Icons.upload_file_rounded, size: 20),
              ),
            ),
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
        return '${_blockedSongs.length} tracks';
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
          onTap: () =>
              context.push('/home/playlist-detail', extra: playlist.id),
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
        title: 'No playlists yet',
        subtitle: 'Save favorite playlists to view here',
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
        title: 'Empty List',
        subtitle: 'You haven\'t blocked any songs',
        palette: palette,
      ),
    );
  }

  Widget _stationsSliver(_Palette palette) {
    return SliverFillRemaining(
      child: _EmptyState(
        icon: LucideIcons.radio,
        title: 'No stations yet',
        subtitle: 'Saved radio stations will appear here',
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
                      playlist.description ?? '${playlist.totalTracks} songs',
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
                    '${playlist.totalTracks} tracks',
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
              'Unblock',
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
class _UploadTrackBottomSheet extends StatefulWidget {
  const _UploadTrackBottomSheet();

  @override
  State<_UploadTrackBottomSheet> createState() =>
      _UploadTrackBottomSheetState();
}

class _UploadTrackBottomSheetState extends State<_UploadTrackBottomSheet> {
  static const int _maxAudioBytes = 50 * 1024 * 1024;
  static const int _maxCoverBytes = 5 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _genreController = TextEditingController();

  PlatformFile? _audioFile;
  PlatformFile? _coverFile;
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _genreController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'],
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return;

    final selected = result.files.single;
    if (selected.size > _maxAudioBytes) {
      _showError('Audio file must be 50 MB or smaller.');
      return;
    }

    setState(() => _audioFile = selected);
  }

  Future<void> _pickCoverFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (!mounted || result == null || result.files.isEmpty) return;

    final selected = result.files.single;
    if (selected.size > _maxCoverBytes) {
      _showError('Cover image must be 5 MB or smaller.');
      return;
    }

    setState(() => _coverFile = selected);
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_audioFile == null) {
      _showError('Please select an audio file.');
      return;
    }

    setState(() => _submitting = true);

    try {
      await sl<TrackRemoteDataSource>().createTrack(
        CreateTrackRequest(
          title: _titleController.text.trim(),
          artist: _nullableText(_artistController.text),
          genre: _nullableText(_genreController.text),
          audioFile: _toUploadFile(_audioFile!),
          coverImageFile:
              _coverFile != null ? _toUploadFile(_coverFile!) : null,
        ),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } on ServerException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Failed to upload track.');
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String? _nullableText(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  TrackUploadFile _toUploadFile(PlatformFile file) {
    return TrackUploadFile(
      fileName: file.name,
      filePath: file.path,
      bytes: file.bytes,
    );
  }

  void _showError(String message) {
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
    final cardColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.04);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  Row(
                    children: [
                      Text(
                        'Upload Track',
                        style: GoogleFonts.poppins(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.pop(context, false),
                        icon: Icon(LucideIcons.x, color: textMuted, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Only Brand Manager can upload new tracks.',
                    style: GoogleFonts.inter(
                      color: textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _titleController,
                    enabled: !_submitting,
                    style: GoogleFonts.inter(color: textPrimary),
                    decoration: _inputDecoration(
                      label: 'Title *',
                      isDark: isDark,
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return 'Title is required.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _artistController,
                    enabled: !_submitting,
                    style: GoogleFonts.inter(color: textPrimary),
                    decoration: _inputDecoration(
                      label: 'Artist',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _genreController,
                    enabled: !_submitting,
                    style: GoogleFonts.inter(color: textPrimary),
                    decoration: _inputDecoration(
                      label: 'Genre',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _FilePickerTile(
                    title: 'Audio File *',
                    subtitle: _audioFile?.name ??
                        'mp3, wav, aac, flac, ogg, m4a (max 50 MB)',
                    onTap: _submitting ? null : _pickAudioFile,
                    icon: Icons.audiotrack_rounded,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    cardColor: cardColor,
                  ),
                  const SizedBox(height: 10),
                  _FilePickerTile(
                    title: 'Cover Image',
                    subtitle:
                        _coverFile?.name ?? 'jpg, jpeg, png, webp (max 5 MB)',
                    onTap: _submitting ? null : _pickCoverFile,
                    icon: Icons.image_outlined,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                    cardColor: cardColor,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.upload_file_rounded, size: 18),
                      label: Text(
                        _submitting ? 'Uploading...' : 'Upload Track',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
        color: isDark ? Colors.white60 : Colors.black54,
        fontSize: 12,
      ),
      filled: true,
      fillColor: isDark
          ? Colors.white.withOpacity(0.06)
          : Colors.black.withOpacity(0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

class _FilePickerTile extends StatelessWidget {
  const _FilePickerTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.icon,
    required this.textPrimary,
    required this.textMuted,
    required this.cardColor,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final IconData icon;
  final Color textPrimary;
  final Color textMuted;
  final Color cardColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: textMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      color: textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textMuted),
          ],
        ),
      ),
    );
  }
}

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
    return const _Palette(
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
