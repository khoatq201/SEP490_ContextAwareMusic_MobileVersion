import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/enums/queue_insert_mode_enum.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/widgets/shared_catalog_badge.dart';
import '../../../../features/cams/presentation/bloc/cams_playback_bloc.dart';
import '../../../../features/cams/presentation/bloc/cams_playback_event.dart';
import '../../../../features/moods/domain/entities/mood.dart';
import '../../../../features/playlists/data/repositories/playlist_repository_impl.dart';
import '../../../../features/playlists/domain/entities/api_playlist.dart';
import '../../../../features/tracks/domain/entities/api_track.dart';
import '../../../../features/tracks/domain/entities/track_copyright_clearance_status.dart';
import '../../../../features/tracks/domain/entities/track_filter.dart';
import '../../../../features/tracks/domain/usecases/track_usecases.dart';
import '../../../../injection_container.dart';

enum _MusicSourceTab {
  tracks,
  playlist,
  mood,
}

const int _trackPageSize = 10;

String _queueModeLabel(QueueInsertModeEnum mode) {
  switch (mode) {
    case QueueInsertModeEnum.playNow:
      return 'Play now';
    case QueueInsertModeEnum.playNext:
      return 'Play next';
    case QueueInsertModeEnum.addToQueue:
      return 'Add to queue';
  }
}

TrackFilter _playableTrackFilter({
  int page = 1,
  int pageSize = _trackPageSize,
}) {
  return TrackFilter(
    page: page,
    pageSize: pageSize,
    status: EntityStatusEnum.active,
    copyrightClearanceStatuses: const [
      TrackCopyrightClearanceStatus.notApplicable,
      TrackCopyrightClearanceStatus.cleared,
    ],
  );
}

Future<List<ApiTrack>> _loadPlaybackDeviceTracksFromPlaylists({
  String? storeId,
}) async {
  final playlistRepository = sl<PlaylistRepository>();
  final playlistsResult = await playlistRepository.getPlaylists(
    page: 1,
    pageSize: 50,
    storeId: storeId,
  );

  var playlists = const <ApiPlaylist>[];
  playlistsResult.fold(
    (_) {},
    (response) {
      playlists = response.items
          .where(
            (playlist) =>
                playlist.status == EntityStatusEnum.active &&
                playlist.trackCount > 0,
          )
          .toList();
    },
  );

  final tracksById = <String, ApiTrack>{};
  for (final playlist in playlists) {
    final detailResult = await playlistRepository.getPlaylistById(playlist.id);
    detailResult.fold(
      (_) {},
      (detail) {
        final playlistTracks = detail.tracks ?? const [];
        for (final item in playlistTracks) {
          final title = item.title?.trim();
          tracksById.putIfAbsent(
            item.trackId,
            () => ApiTrack(
              id: item.trackId,
              brandId: item.brandId,
              title: title == null || title.isEmpty ? 'Untitled track' : title,
              artist: item.artist,
              moodId: detail.moodId,
              moodName: detail.moodName,
              durationSec: item.actualDurationSec ?? item.durationSec,
              hlsUrl: item.hlsUrl,
              coverImageUrl: item.coverImageUrl,
              status: EntityStatusEnum.active,
              createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
            ),
          );
        }
      },
    );
  }

  return tracksById.values.toList()
    ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
}

class _SheetPalette {
  const _SheetPalette({
    required this.card,
    required this.overlay,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
    required this.textOnAccent,
  });

  final Color card;
  final Color overlay;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;
  final Color textOnAccent;

  factory _SheetPalette.fromContext(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _SheetPalette(
      card: colorScheme.surface,
      overlay: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      border: colorScheme.outlineVariant,
      textPrimary: colorScheme.onSurface,
      textMuted: colorScheme.onSurfaceVariant,
      accent: colorScheme.primary,
      textOnAccent: colorScheme.onPrimary,
    );
  }
}

class NowPlayingAddToQueueSheet extends StatefulWidget {
  const NowPlayingAddToQueueSheet({
    super.key,
    this.initialTrackId,
  });

  final String? initialTrackId;

  @override
  State<NowPlayingAddToQueueSheet> createState() =>
      _NowPlayingAddToQueueSheetState();
}

class _NowPlayingAddToQueueSheetState extends State<NowPlayingAddToQueueSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final ScrollController _trackScrollController = ScrollController();

  _MusicSourceTab _sourceTab = _MusicSourceTab.tracks;
  QueueInsertModeEnum _queueMode = QueueInsertModeEnum.addToQueue;
  bool _clearExistingQueue = false;

  List<ApiTrack> _tracks = const <ApiTrack>[];
  List<ApiPlaylist> _playlists = const <ApiPlaylist>[];
  bool _isLoadingTracks = true;
  bool _isLoadingMoreTracks = false;
  bool _hasMoreTracks = true;
  bool _isLoadingPlaylists = true;
  String? _tracksError;
  String? _playlistsError;
  final Set<String> _selectedTrackIds = <String>{};
  String? _selectedPlaylistId;
  int _trackPage = 0;

  @override
  void initState() {
    super.initState();
    final initialTrackId = widget.initialTrackId?.trim();
    if (initialTrackId != null && initialTrackId.isNotEmpty) {
      _selectedTrackIds.add(initialTrackId);
    }
    _trackScrollController.addListener(_handleTrackScroll);
    _loadTracks();
    _loadPlaylists();
  }

  @override
  void dispose() {
    _trackScrollController.removeListener(_handleTrackScroll);
    _trackScrollController.dispose();
    _searchController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_sourceTab == _MusicSourceTab.tracks) {
      return _selectedTrackIds.isNotEmpty;
    }
    return _selectedPlaylistId != null && _selectedPlaylistId!.isNotEmpty;
  }

  List<ApiTrack> get _filteredTracks {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _tracks;
    return _tracks.where((track) {
      return track.title.toLowerCase().contains(query) ||
          (track.artist?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<ApiPlaylist> get _filteredPlaylists {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _playlists;
    return _playlists.where((playlist) {
      return playlist.name.toLowerCase().contains(query) ||
          (playlist.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _handleTrackScroll() {
    if (!_trackScrollController.hasClients ||
        _isLoadingTracks ||
        _isLoadingMoreTracks ||
        !_hasMoreTracks ||
        _searchController.text.trim().isNotEmpty) {
      return;
    }

    final position = _trackScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 96) {
      _loadTracks(reset: false);
    }
  }

  Future<void> _loadTracks({bool reset = true}) async {
    if (!reset && (!_hasMoreTracks || _isLoadingMoreTracks)) return;

    setState(() {
      if (reset) {
        _isLoadingTracks = true;
        _tracksError = null;
        _trackPage = 0;
        _hasMoreTracks = true;
      } else {
        _isLoadingMoreTracks = true;
      }
    });

    final sessionState = context.read<SessionCubit>().state;
    final isPlaybackDevice = sessionState.isPlaybackDevice;
    final storeId = sessionState.currentStore?.id;
    final nextPage = reset ? 1 : _trackPage + 1;
    final result = await sl<GetTracks>()(
      filter: _playableTrackFilter(page: nextPage),
    );
    if (!mounted) return;

    await result.fold(
      (failure) async {
        setState(() {
          if (reset) {
            _isLoadingTracks = false;
            _tracksError = failure.message;
          } else {
            _isLoadingMoreTracks = false;
          }
        });
      },
      (response) async {
        List<ApiTrack> items = response.items.toList();
        var hasMore = response.hasNext;
        if (reset && items.isEmpty && isPlaybackDevice) {
          items = await _loadPlaybackDeviceTracksFromPlaylists(
            storeId: storeId,
          );
          if (!mounted) return;
          hasMore = false;
        }
        final tracksById = <String, ApiTrack>{
          if (!reset)
            for (final track in _tracks) track.id: track,
          for (final track in items) track.id: track,
        };
        final mergedTracks = tracksById.values.toList()
          ..sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          );
        setState(() {
          _isLoadingTracks = false;
          _isLoadingMoreTracks = false;
          _tracks = mergedTracks;
          _trackPage = response.currentPage;
          _hasMoreTracks = hasMore;
        });
      },
    );
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoadingPlaylists = true;
      _playlistsError = null;
    });

    final storeId = context.read<SessionCubit>().state.currentStore?.id;
    final result = await sl<PlaylistRepository>().getPlaylists(
      page: 1,
      pageSize: 50,
      storeId: storeId,
    );
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoadingPlaylists = false;
          _playlistsError = failure.message;
        });
      },
      (response) {
        final items = response.items
            .where((playlist) => playlist.status == EntityStatusEnum.active)
            .toList()
          ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        setState(() {
          _isLoadingPlaylists = false;
          _playlists = items;
        });
      },
    );
  }

  void _setQueueMode(QueueInsertModeEnum mode) {
    setState(() {
      _queueMode = mode;
      if (mode == QueueInsertModeEnum.addToQueue) {
        _clearExistingQueue = false;
      }
    });
  }

  void _toggleTrack(String trackId) {
    setState(() {
      if (_selectedTrackIds.contains(trackId)) {
        _selectedTrackIds.remove(trackId);
      } else {
        _selectedTrackIds.add(trackId);
      }
    });
  }

  void _submit() {
    if (!_canSubmit) return;

    final reason = _reasonController.text.trim();
    final normalizedReason = reason.isEmpty ? null : reason;
    final resolvedClearExistingQueue =
        _queueMode == QueueInsertModeEnum.addToQueue
            ? false
            : _clearExistingQueue;

    final bloc = context.read<CamsPlaybackBloc>();
    if (_sourceTab == _MusicSourceTab.tracks) {
      bloc.add(
        CamsPlayTracks(
          trackIds: _selectedTrackIds.toList(growable: false),
          requestedMode: _queueMode,
          clearExistingQueue: resolvedClearExistingQueue,
          reason: normalizedReason,
        ),
      );
    } else {
      bloc.add(
        CamsPlayPlaylist(
          playlistId: _selectedPlaylistId!,
          requestedMode: _queueMode,
          clearExistingQueue: resolvedClearExistingQueue,
          reason: normalizedReason,
        ),
      );
    }

    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _SheetPalette.fromContext(context);
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHandle(palette: palette),
              const SizedBox(height: 16),
              _SheetHeader(
                title: 'Add to queue',
                subtitle:
                    'Choose a source, pick where it should land in the queue, and optionally describe why.',
                palette: palette,
              ),
              const SizedBox(height: 16),
              _SelectionChips<_MusicSourceTab>(
                values: const [
                  _MusicSourceTab.tracks,
                  _MusicSourceTab.playlist
                ],
                selectedValue: _sourceTab,
                labelBuilder: (value) =>
                    value == _MusicSourceTab.tracks ? 'Tracks' : 'Playlist',
                onSelected: (value) => setState(() => _sourceTab = value),
                palette: palette,
              ),
              const SizedBox(height: 12),
              _SelectionChips<QueueInsertModeEnum>(
                values: QueueInsertModeEnum.values,
                selectedValue: _queueMode,
                labelBuilder: _queueModeLabel,
                onSelected: _setQueueMode,
                palette: palette,
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: _queueMode == QueueInsertModeEnum.addToQueue
                    ? false
                    : _clearExistingQueue,
                onChanged: _queueMode == QueueInsertModeEnum.addToQueue
                    ? null
                    : (value) => setState(() => _clearExistingQueue = value),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Clear existing queue before adding',
                  style: GoogleFonts.inter(
                    color: palette.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _queueMode == QueueInsertModeEnum.addToQueue
                      ? 'Disabled for Add to queue.'
                      : 'Use this for play-now or play-next replacement flows.',
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.inter(color: palette.textPrimary),
                decoration: InputDecoration(
                  hintText: _sourceTab == _MusicSourceTab.tracks
                      ? 'Search tracks'
                      : 'Search playlists',
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              _sourceTab == _MusicSourceTab.tracks
                  ? _buildTrackList(palette)
                  : _buildPlaylistList(palette),
              const SizedBox(height: 12),
              TextField(
                controller: _reasonController,
                maxLines: 2,
                style: GoogleFonts.inter(color: palette.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  hintText: 'Manual queue request',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canSubmit ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: palette.accent,
                    foregroundColor: palette.textOnAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(_queueModeLabel(_queueMode)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrackList(_SheetPalette palette) {
    if (_isLoadingTracks) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_tracksError != null) {
      return _InlineMessage(
        message: _tracksError!,
        palette: palette,
        actionLabel: 'Retry',
        onAction: _loadTracks,
      );
    }

    final tracks = _filteredTracks;
    if (tracks.isEmpty) {
      return _InlineMessage(
        message: 'No tracks found.',
        palette: palette,
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: ListView.separated(
        controller: _trackScrollController,
        primary: false,
        shrinkWrap: true,
        itemCount: tracks.length + (_isLoadingMoreTracks ? 1 : 0),
        separatorBuilder: (_, __) => Divider(color: palette.border),
        itemBuilder: (context, index) {
          if (index >= tracks.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.accent,
                  ),
                ),
              ),
            );
          }
          final track = tracks[index];
          final selected = _selectedTrackIds.contains(track.id);
          return CheckboxListTile(
            value: selected,
            onChanged: (_) => _toggleTrack(track.id),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: palette.accent,
            title: Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: palette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  track.artist?.trim().isNotEmpty == true
                      ? track.artist!
                      : 'Unknown artist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (isSharedCatalogItem(track.brandId))
                  const SharedCatalogBadge(compact: true),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaylistList(_SheetPalette palette) {
    if (_isLoadingPlaylists) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_playlistsError != null) {
      return _InlineMessage(
        message: _playlistsError!,
        palette: palette,
        actionLabel: 'Retry',
        onAction: _loadPlaylists,
      );
    }

    final playlists = _filteredPlaylists;
    if (playlists.isEmpty) {
      return _InlineMessage(
        message: 'No playlists found.',
        palette: palette,
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: playlists.length,
        separatorBuilder: (_, __) => Divider(color: palette.border),
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          final selected = _selectedPlaylistId == playlist.id;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? palette.accent : palette.textMuted,
            ),
            title: Text(
              playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: palette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${playlist.trackCount} tracks',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (isSharedCatalogItem(playlist.brandId))
                  const SharedCatalogBadge(compact: true),
              ],
            ),
            trailing: selected
                ? Icon(Icons.check_circle, color: palette.accent)
                : null,
            onTap: () => setState(() {
              _selectedPlaylistId = playlist.id;
            }),
          );
        },
      ),
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle({required this.palette});

  final _SheetPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: palette.border,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.title,
    required this.subtitle,
    required this.palette,
  });

  final String title;
  final String subtitle;
  final _SheetPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: palette.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: palette.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          child: Text(
            'Close',
            style: GoogleFonts.inter(
              color: palette.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionChips<T> extends StatelessWidget {
  const _SelectionChips({
    required this.values,
    required this.selectedValue,
    required this.labelBuilder,
    required this.onSelected,
    required this.palette,
  });

  final List<T> values;
  final T selectedValue;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onSelected;
  final _SheetPalette palette;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final selected = value == selectedValue;
        return ChoiceChip(
          label: Text(
            labelBuilder(value),
            style: GoogleFonts.inter(
              color: selected ? palette.textOnAccent : palette.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          selected: selected,
          selectedColor: palette.accent,
          backgroundColor: palette.overlay,
          side: BorderSide(
            color: selected ? palette.accent : palette.border,
          ),
          onSelected: (_) => onSelected(value),
        );
      }).toList(),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.message,
    required this.palette,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final _SheetPalette palette;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.overlay,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: palette.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class NowPlayingOverrideMusicSheet extends StatefulWidget {
  const NowPlayingOverrideMusicSheet({
    super.key,
    required this.moods,
  });

  final List<Mood> moods;

  @override
  State<NowPlayingOverrideMusicSheet> createState() =>
      _NowPlayingOverrideMusicSheetState();
}

class _NowPlayingOverrideMusicSheetState
    extends State<NowPlayingOverrideMusicSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _ttlController = TextEditingController();
  final ScrollController _trackScrollController = ScrollController();

  _MusicSourceTab _sourceTab = _MusicSourceTab.tracks;
  List<ApiTrack> _tracks = const <ApiTrack>[];
  List<ApiPlaylist> _playlists = const <ApiPlaylist>[];
  bool _isLoadingTracks = true;
  bool _isLoadingMoreTracks = false;
  bool _hasMoreTracks = true;
  bool _isLoadingPlaylists = true;
  String? _tracksError;
  String? _playlistsError;
  final Set<String> _selectedTrackIds = <String>{};
  String? _selectedPlaylistId;
  String? _selectedMoodId;
  bool _clearManagerSelectedQueues = false;
  bool _isCutOver = false;
  int _trackPage = 0;

  @override
  void initState() {
    super.initState();
    _ttlController.addListener(_handleTtlChanged);
    _trackScrollController.addListener(_handleTrackScroll);
    _loadTracks();
    _loadPlaylists();
  }

  @override
  void dispose() {
    _ttlController.removeListener(_handleTtlChanged);
    _trackScrollController.removeListener(_handleTrackScroll);
    _trackScrollController.dispose();
    _searchController.dispose();
    _reasonController.dispose();
    _ttlController.dispose();
    super.dispose();
  }

  int? get _ttlSeconds {
    final parsed = int.tryParse(_ttlController.text.trim());
    return parsed != null && parsed > 0 ? parsed : null;
  }

  bool get _requiresMoodTtl =>
      _sourceTab == _MusicSourceTab.mood &&
      (_selectedMoodId?.trim().isNotEmpty ?? false);

  bool get _hasValidMoodTtl => !_requiresMoodTtl || _ttlSeconds != null;

  bool get _canSubmit {
    return _hasValidMoodTtl;
  }

  void _handleTtlChanged() {
    if (_requiresMoodTtl && mounted) {
      setState(() {});
    }
  }

  List<ApiTrack> get _filteredTracks {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _tracks;
    return _tracks.where((track) {
      return track.title.toLowerCase().contains(query) ||
          (track.artist?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<ApiPlaylist> get _filteredPlaylists {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _playlists;
    return _playlists.where((playlist) {
      return playlist.name.toLowerCase().contains(query) ||
          (playlist.description?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  List<Mood> get _availableMoods {
    final items = widget.moods
        .where((mood) => mood.status == EntityStatusEnum.active)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  void _handleTrackScroll() {
    if (!_trackScrollController.hasClients ||
        _isLoadingTracks ||
        _isLoadingMoreTracks ||
        !_hasMoreTracks ||
        _searchController.text.trim().isNotEmpty) {
      return;
    }

    final position = _trackScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 96) {
      _loadTracks(reset: false);
    }
  }

  Future<void> _loadTracks({bool reset = true}) async {
    if (!reset && (!_hasMoreTracks || _isLoadingMoreTracks)) return;

    setState(() {
      if (reset) {
        _isLoadingTracks = true;
        _tracksError = null;
        _trackPage = 0;
        _hasMoreTracks = true;
      } else {
        _isLoadingMoreTracks = true;
      }
    });

    final sessionState = context.read<SessionCubit>().state;
    final isPlaybackDevice = sessionState.isPlaybackDevice;
    final storeId = sessionState.currentStore?.id;
    final nextPage = reset ? 1 : _trackPage + 1;
    final result = await sl<GetTracks>()(
      filter: _playableTrackFilter(page: nextPage),
    );
    if (!mounted) return;

    await result.fold(
      (failure) async {
        setState(() {
          if (reset) {
            _isLoadingTracks = false;
            _tracksError = failure.message;
          } else {
            _isLoadingMoreTracks = false;
          }
        });
      },
      (response) async {
        List<ApiTrack> items = response.items.toList();
        var hasMore = response.hasNext;
        if (reset && items.isEmpty && isPlaybackDevice) {
          items = await _loadPlaybackDeviceTracksFromPlaylists(
            storeId: storeId,
          );
          if (!mounted) return;
          hasMore = false;
        }
        final tracksById = <String, ApiTrack>{
          if (!reset)
            for (final track in _tracks) track.id: track,
          for (final track in items) track.id: track,
        };
        final mergedTracks = tracksById.values.toList()
          ..sort(
            (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
          );
        setState(() {
          _isLoadingTracks = false;
          _isLoadingMoreTracks = false;
          _tracks = mergedTracks;
          _trackPage = response.currentPage;
          _hasMoreTracks = hasMore;
        });
      },
    );
  }

  Future<void> _loadPlaylists() async {
    setState(() {
      _isLoadingPlaylists = true;
      _playlistsError = null;
    });

    final storeId = context.read<SessionCubit>().state.currentStore?.id;
    final result = await sl<PlaylistRepository>().getPlaylists(
      page: 1,
      pageSize: 50,
      storeId: storeId,
    );
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isLoadingPlaylists = false;
          _playlistsError = failure.message;
        });
      },
      (response) {
        final items = response.items
            .where((playlist) => playlist.status == EntityStatusEnum.active)
            .toList()
          ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        setState(() {
          _isLoadingPlaylists = false;
          _playlists = items;
        });
      },
    );
  }

  void _toggleTrack(String trackId) {
    setState(() {
      _selectedPlaylistId = null;
      _selectedMoodId = null;
      if (_selectedTrackIds.contains(trackId)) {
        _selectedTrackIds.remove(trackId);
      } else {
        _selectedTrackIds.add(trackId);
      }
    });
  }

  void _selectPlaylist(String playlistId) {
    setState(() {
      _selectedTrackIds.clear();
      _selectedMoodId = null;
      _selectedPlaylistId =
          _selectedPlaylistId == playlistId ? null : playlistId;
    });
  }

  void _selectMood(String moodId) {
    setState(() {
      _selectedTrackIds.clear();
      _selectedPlaylistId = null;
      _selectedMoodId = _selectedMoodId == moodId ? null : moodId;
    });
  }

  void _submit() {
    if (!_canSubmit) return;
    final reason = _reasonController.text.trim();
    final trackIds =
        _sourceTab == _MusicSourceTab.tracks && _selectedTrackIds.isNotEmpty
            ? _selectedTrackIds.toList()
            : null;
    final playlistId =
        _sourceTab == _MusicSourceTab.playlist ? _selectedPlaylistId : null;
    final moodId = _sourceTab == _MusicSourceTab.mood ? _selectedMoodId : null;
    final ttlSeconds = _ttlSeconds;
    context.read<CamsPlaybackBloc>().add(
          CamsApplyOverride(
            trackIds: trackIds,
            playlistId: playlistId,
            moodId: moodId,
            isClearManagerSelectedQueues: _clearManagerSelectedQueues,
            isCutOver: _isCutOver,
            manualOverrideTtlSeconds:
                ttlSeconds != null && ttlSeconds > 0 ? ttlSeconds : null,
            reason: reason.isEmpty ? null : reason,
          ),
        );
    Navigator.of(context, rootNavigator: true).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = _SheetPalette.fromContext(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(palette: palette),
            const SizedBox(height: 16),
            _SheetHeader(
              title: 'Override space music',
              subtitle:
                  'You can apply an override without choosing a source, or optionally pick one source only. Tracks can contain multiple selections, but playlist and mood stay single-select.',
              palette: palette,
            ),
            const SizedBox(height: 16),
            _SelectionChips<_MusicSourceTab>(
              values: const [
                _MusicSourceTab.tracks,
                _MusicSourceTab.playlist,
                _MusicSourceTab.mood,
              ],
              selectedValue: _sourceTab,
              labelBuilder: (value) {
                switch (value) {
                  case _MusicSourceTab.tracks:
                    return 'Tracks';
                  case _MusicSourceTab.playlist:
                    return 'Playlist';
                  case _MusicSourceTab.mood:
                    return 'Mood';
                }
              },
              onSelected: (value) => setState(() => _sourceTab = value),
              palette: palette,
            ),
            if (_sourceTab != _MusicSourceTab.mood) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.inter(color: palette.textPrimary),
                decoration: InputDecoration(
                  hintText: _sourceTab == _MusicSourceTab.tracks
                      ? 'Search tracks'
                      : 'Search playlists',
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ],
            const SizedBox(height: 12),
            _buildSourceList(palette),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              value: _clearManagerSelectedQueues,
              onChanged: (value) =>
                  setState(() => _clearManagerSelectedQueues = value),
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Clear manager-selected queue items',
                style: GoogleFonts.inter(
                  color: palette.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SwitchListTile.adaptive(
              value: _isCutOver,
              onChanged: (value) => setState(() => _isCutOver = value),
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Cut over immediately',
                style: GoogleFonts.inter(
                  color: palette.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Ask CAMS to transition to the override source right away when supported.',
                style: GoogleFonts.inter(
                  color: palette.textMuted,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ttlController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.inter(color: palette.textPrimary),
              decoration: InputDecoration(
                labelText: _requiresMoodTtl
                    ? 'Override TTL seconds *'
                    : 'Override TTL seconds (optional)',
                hintText: 'Example: 1800',
                helperText: _requiresMoodTtl
                    ? 'Required when mood override has no tracks or playlist.'
                    : 'Required only for mood-only AI take-over.',
                errorText: _requiresMoodTtl && !_hasValidMoodTtl
                    ? 'Enter seconds.'
                    : null,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 2,
              style: GoogleFonts.inter(color: palette.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                hintText: 'Manual override request',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.textOnAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Apply override'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceList(_SheetPalette palette) {
    switch (_sourceTab) {
      case _MusicSourceTab.tracks:
        return _buildTrackList(palette);
      case _MusicSourceTab.playlist:
        return _buildPlaylistList(palette);
      case _MusicSourceTab.mood:
        return _buildMoodList(palette);
    }
  }

  Widget _buildTrackList(_SheetPalette palette) {
    if (_isLoadingTracks) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_tracksError != null) {
      return _InlineMessage(
        message: _tracksError!,
        palette: palette,
        actionLabel: 'Retry',
        onAction: _loadTracks,
      );
    }

    final tracks = _filteredTracks;
    if (tracks.isEmpty) {
      return _InlineMessage(
        message: 'No tracks found.',
        palette: palette,
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: ListView.separated(
        controller: _trackScrollController,
        primary: false,
        shrinkWrap: true,
        itemCount: tracks.length + (_isLoadingMoreTracks ? 1 : 0),
        separatorBuilder: (_, __) => Divider(color: palette.border),
        itemBuilder: (context, index) {
          if (index >= tracks.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.accent,
                  ),
                ),
              ),
            );
          }
          final track = tracks[index];
          return CheckboxListTile(
            value: _selectedTrackIds.contains(track.id),
            onChanged: (_) => _toggleTrack(track.id),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              track.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: palette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  track.artist?.trim().isNotEmpty == true
                      ? track.artist!
                      : 'Unknown artist',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (isSharedCatalogItem(track.brandId))
                  const SharedCatalogBadge(compact: true),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaylistList(_SheetPalette palette) {
    if (_isLoadingPlaylists) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_playlistsError != null) {
      return _InlineMessage(
        message: _playlistsError!,
        palette: palette,
        actionLabel: 'Retry',
        onAction: _loadPlaylists,
      );
    }

    final playlists = _filteredPlaylists;
    if (playlists.isEmpty) {
      return _InlineMessage(
        message: 'No playlists found.',
        palette: palette,
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 280),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: playlists.length,
        separatorBuilder: (_, __) => Divider(color: palette.border),
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          final selected = _selectedPlaylistId == playlist.id;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? palette.accent : palette.textMuted,
            ),
            title: Text(
              playlist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: palette.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '${playlist.trackCount} tracks',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 12,
                  ),
                ),
                if (isSharedCatalogItem(playlist.brandId))
                  const SharedCatalogBadge(compact: true),
              ],
            ),
            trailing: selected
                ? Icon(Icons.check_circle, color: palette.accent)
                : null,
            onTap: () => _selectPlaylist(playlist.id),
          );
        },
      ),
    );
  }

  Widget _buildMoodList(_SheetPalette palette) {
    final moods = _availableMoods;
    if (moods.isEmpty) {
      return _InlineMessage(
        message: 'No moods available.',
        palette: palette,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: moods.map((mood) {
        final selected = _selectedMoodId == mood.id;
        return ChoiceChip(
          label: Text(
            mood.name.toUpperCase(),
            style: GoogleFonts.inter(
              color: selected ? palette.textOnAccent : palette.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          selected: selected,
          selectedColor: palette.accent,
          backgroundColor: palette.overlay,
          side: BorderSide(
            color: selected ? palette.accent : palette.border,
          ),
          onSelected: (_) => _selectMood(mood.id),
        );
      }).toList(),
    );
  }
}
