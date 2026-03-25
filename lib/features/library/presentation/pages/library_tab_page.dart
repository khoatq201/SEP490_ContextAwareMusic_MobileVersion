import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/music_provider_enum.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../injection_container.dart';
import '../../../cams/data/services/store_hub_service.dart';
import '../../../home/domain/entities/playlist_entity.dart';
import '../../../home/domain/entities/song_entity.dart';
import '../../../playlists/data/datasources/playlist_remote_datasource.dart';
import '../../../suno/data/datasources/suno_remote_datasource.dart';
import '../../../suno/domain/entities/suno_config.dart';
import '../../../suno/domain/entities/suno_generation.dart';
import '../../../suno/domain/entities/suno_generation_status.dart';
import '../../../suno/domain/services/suno_playback_orchestrator.dart';
import '../../../suno/domain/usecases/suno_usecases.dart';
import '../../../tracks/data/datasources/track_remote_datasource.dart';
import '../../../tracks/domain/entities/api_track.dart';
import '../../../tracks/domain/entities/track_filter.dart';
import '../../../tracks/domain/entities/track_metadata_status.dart';
import '../../../tracks/domain/usecases/track_usecases.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Filter options
// ─────────────────────────────────────────────────────────────────────────────
enum _LibraryFilter { playlists, tracks, blocked }

enum _TrackProviderScope { all, custom, suno }

extension _LibraryFilterLabel on _LibraryFilter {
  String get label {
    switch (this) {
      case _LibraryFilter.playlists:
        return 'Saved';
      case _LibraryFilter.tracks:
        return 'Tracks';
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
  _TrackProviderScope _trackProviderScope = _TrackProviderScope.all;
  bool _showAiOnly = false;

  List<PlaylistEntity> _savedPlaylists = [];
  List<ApiTrack> _tracks = [];
  final List<SongEntity> _blockedSongs = [];
  bool _loading = true;
  bool _trackMutationInFlight = false;
  SunoConfig? _sunoConfig;
  final List<SunoGeneration> _sunoGenerations = [];
  final Set<String> _activeMetadataPollTrackIds = <String>{};
  late final SunoPlaybackOrchestrator _sunoPlaybackOrchestrator;
  StoreHubService? _sunoHubService;
  StreamSubscription<SunoGenerationStatusChangedEvent>? _sunoGenerationSub;
  StreamSubscription<SunoPlaybackUpdate>? _sunoPlaybackUpdateSub;
  String? _subscribedBrandId;

  @override
  void initState() {
    super.initState();
    _sunoPlaybackOrchestrator = sl<SunoPlaybackOrchestrator>();
    _sunoPlaybackUpdateSub =
        _sunoPlaybackOrchestrator.updates.listen(_handleSunoPlaybackUpdate);
    unawaited(_loadInitialData());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    unawaited(_ensureSunoRealtimeSubscription());
  }

  @override
  void dispose() {
    _sunoGenerationSub?.cancel();
    _sunoPlaybackUpdateSub?.cancel();
    _sunoHubService?.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      await Future.wait([
        _loadPlaylists(),
        _loadTracks(),
        _loadSunoConfig(),
      ]);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
      });
    } catch (_) {
      // Keep library usable even when playlists fail to load.
    }
  }

  TrackFilter _buildTrackFilter() {
    MusicProviderEnum? provider;
    switch (_trackProviderScope) {
      case _TrackProviderScope.all:
        provider = null;
      case _TrackProviderScope.custom:
        provider = MusicProviderEnum.custom;
      case _TrackProviderScope.suno:
        provider = MusicProviderEnum.suno;
    }

    return TrackFilter(
      page: 1,
      pageSize: 50,
      provider: provider,
      isAiGenerated: _showAiOnly ? true : null,
    );
  }

  Future<void> _loadTracks({bool silent = false}) async {
    final result = await sl<GetTracks>()(filter: _buildTrackFilter());
    if (!mounted) return;

    result.fold(
      (_) {
        if (!silent && _tracks.isEmpty) {
          setState(() => _tracks = const []);
        }
      },
      (response) {
        final nextTracks = response.items
            .map<ApiTrack>(_mergeTrackWithCurrentState)
            .toList(growable: false);
        setState(() => _tracks = nextTracks);
      },
    );
  }

  ApiTrack _mergeTrackWithCurrentState(ApiTrack incoming) {
    final existingIndex =
        _tracks.indexWhere((track) => track.id == incoming.id);
    if (existingIndex < 0) {
      return incoming;
    }

    final existing = _tracks[existingIndex];
    if (incoming.hasMeaningfulMetadata) {
      return incoming.copyWith(
        metadataStatusOverride: TrackMetadataStatus.metadataReady,
      );
    }

    if (_activeMetadataPollTrackIds.contains(incoming.id)) {
      return incoming.copyWith(
        metadataStatusOverride: existing.metadataStatusOverride ??
            TrackMetadataStatus.metadataPending,
      );
    }

    return incoming.copyWith(
      metadataStatusOverride: existing.metadataStatusOverride,
    );
  }

  Future<void> _loadSunoConfig() async {
    final result = await sl<GetSunoConfig>()();
    if (!mounted) return;
    result.fold(
      (_) {},
      (config) => setState(() => _sunoConfig = config),
    );
  }

  Future<void> _ensureSunoRealtimeSubscription() async {
    final session = context.read<SessionCubit>().state;
    final canManageTracks = !session.isPlaybackDevice &&
        session.currentRole == UserRole.brandManager;
    final brandId = session.currentStore?.brandId;
    if (!canManageTracks ||
        brandId == null ||
        brandId.isEmpty ||
        brandId == _subscribedBrandId) {
      return;
    }

    await _sunoGenerationSub?.cancel();
    _sunoHubService?.dispose();

    final hubService = sl<StoreHubService>();
    _sunoHubService = hubService;
    _sunoGenerationSub =
        hubService.onSunoGenerationStatusChanged.listen(_handleSunoEvent);

    try {
      await hubService.connect();
      await hubService.joinBrandManagerRoom(brandId);
      _subscribedBrandId = brandId;
    } catch (_) {
      // Realtime is optional. Polling still keeps the UI updated.
    }
  }

  SunoPlaybackContext? _currentSunoPlaybackContext() {
    final session = context.read<SessionCubit>().state;
    final spaceId = session.currentSpace?.id;
    if (spaceId == null || spaceId.isEmpty) {
      return null;
    }
    return SunoPlaybackContext(
      spaceId: spaceId,
      usePlaybackDeviceScope: session.isPlaybackDevice,
    );
  }

  void _handleSunoPlaybackUpdate(SunoPlaybackUpdate update) {
    if (!mounted) return;

    if (update.generation != null) {
      _upsertGeneration(update.generation!);
    }
    if (update.track != null) {
      _upsertTrack(update.track!);
    }
    if (update.message != null && update.message!.trim().isNotEmpty) {
      _showSnackBar(
        update.message!,
        isError: update.kind == SunoPlaybackUpdateKind.error,
      );
    }
  }

  void _handleSunoEvent(SunoGenerationStatusChangedEvent event) {
    final playbackContext = _currentSunoPlaybackContext();
    if (!mounted || event.id.isEmpty || playbackContext == null) return;

    _sunoPlaybackOrchestrator.handleRealtimeStatusChanged(
      event: event,
      context: playbackContext,
    );
  }

  SunoGeneration? _findGenerationById(String id) {
    for (final generation in _sunoGenerations) {
      if (generation.id == id) return generation;
    }
    return null;
  }

  void _upsertGeneration(SunoGeneration generation) {
    final next = List<SunoGeneration>.from(_sunoGenerations);
    final index = next.indexWhere((item) => item.id == generation.id);
    if (index >= 0) {
      next[index] = generation;
    } else {
      next.insert(0, generation);
    }

    if (!mounted) return;
    setState(() {
      _sunoGenerations
        ..clear()
        ..addAll(next.take(6));
    });
  }

  void _upsertTrack(ApiTrack track) {
    final next = List<ApiTrack>.from(_tracks);
    final index = next.indexWhere((item) => item.id == track.id);
    if (index >= 0) {
      next[index] = track;
    } else {
      next.insert(0, track);
    }

    if (!mounted) return;
    setState(() => _tracks = next);
  }

  Future<void> _lookupAndPollNewestTrackByTitle(String title) async {
    final result = await sl<GetTracks>()(
      filter: TrackFilter(
        page: 1,
        pageSize: 10,
        search: title,
      ),
    );
    if (!mounted) return;

    result.fold(
      (_) => unawaited(_loadTracks(silent: true)),
      (response) {
        if (response.items.isEmpty) return;
        response.items
            .sort((left, right) => right.createdAt.compareTo(left.createdAt));
        final candidate = response.items.first;
        _upsertTrack(candidate.copyWith(
          metadataStatusOverride: TrackMetadataStatus.metadataPending,
        ));
        _startMetadataPollingForTrackId(candidate.id);
      },
    );
  }

  void _startMetadataPollingForTrackId(String trackId) {
    if (trackId.isEmpty || _activeMetadataPollTrackIds.contains(trackId)) {
      return;
    }

    _activeMetadataPollTrackIds.add(trackId);
    unawaited(_pollTrackMetadata(trackId));
  }

  Future<void> _pollTrackMetadata(String trackId) async {
    const totalAttempts = 12;
    for (var attempt = 0; attempt < totalAttempts; attempt++) {
      if (!mounted) break;
      if (attempt > 0) {
        await Future<void>.delayed(const Duration(seconds: 5));
      }

      final result = await sl<GetTrackById>()(trackId);
      if (!mounted) break;

      var isDone = false;
      result.fold(
        (_) {},
        (track) {
          final status = track.hasMeaningfulMetadata
              ? TrackMetadataStatus.metadataReady
              : attempt == totalAttempts - 1
                  ? TrackMetadataStatus.metadataUnknown
                  : TrackMetadataStatus.metadataPending;
          _upsertTrack(track.copyWith(metadataStatusOverride: status));
          if (track.hasMeaningfulMetadata ||
              status == TrackMetadataStatus.metadataUnknown) {
            isDone = true;
          }
        },
      );

      if (isDone) break;
    }

    _activeMetadataPollTrackIds.remove(trackId);
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
              color: palette.textMuted.withValues(alpha: 0.55),
              fontSize: 14,
            ),
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
      if (!mounted) return;
      final name = controller.text.trim();
      if (name.isEmpty) return;
      final session = context.read<SessionCubit>().state;
      if (session.isPlaybackDevice) {
        _showSnackBar(
          'Playback device cannot create playlists.',
          isError: true,
        );
        return;
      }
      if (session.currentRole != UserRole.brandManager &&
          session.currentRole != UserRole.storeManager) {
        _showSnackBar(
          'Your role cannot create playlists.',
          isError: true,
        );
        return;
      }

      final storeId = session.currentStore?.id;
      if (storeId == null || storeId.isEmpty) {
        _showSnackBar(
          'Select a store before creating a playlist.',
          isError: true,
        );
        return;
      }

      try {
        await sl<PlaylistRemoteDataSource>().createPlaylist(
          PlaylistMutationRequest(
            name: name,
            storeId: storeId,
          ),
        );

        await _loadPlaylists();
        if (!mounted) return;

        _showSnackBar('Playlist created.');

        String? createdPlaylistId;
        final normalizedName = name.toLowerCase();
        for (final playlist in _savedPlaylists) {
          if (playlist.title.trim().toLowerCase() == normalizedName) {
            createdPlaylistId = playlist.id;
            break;
          }
        }

        if (createdPlaylistId != null && createdPlaylistId.isNotEmpty) {
          context.push('/home/playlist-detail', extra: createdPlaylistId);
        }
      } on ServerException catch (e) {
        if (!mounted) return;
        _showSnackBar(e.message, isError: true);
      } catch (_) {
        if (!mounted) return;
        _showSnackBar('Failed to create playlist.', isError: true);
      }
    }
  }

  Future<void> _openTrackEditorSheet({ApiTrack? track}) async {
    final result = await showModalBottomSheet<_TrackEditorResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UploadTrackBottomSheet(track: track),
    );

    if (!mounted || result == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.successMessage,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    await _loadTracks();
    if (result.trackId != null && result.trackId!.isNotEmpty) {
      _startMetadataPollingForTrackId(result.trackId!);
    } else {
      await _lookupAndPollNewestTrackByTitle(result.title);
    }
  }

  Future<void> _openSunoGenerationSheet() async {
    final playbackContext = _currentSunoPlaybackContext();
    if (playbackContext == null) {
      _showSnackBar(
        'Select a space first so Suno tracks can stream to the live queue.',
        isError: true,
      );
      return;
    }

    final request = await showModalBottomSheet<CreateSunoGenerationRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GenerateSunoTrackBottomSheet(
        playlists: _savedPlaylists,
        initialConfig: _sunoConfig,
      ),
    );

    if (!mounted || request == null) return;

    setState(() => _trackMutationInFlight = true);
    final result = await _sunoPlaybackOrchestrator.createAndTrack(
      request: request,
      context: playbackContext,
    );
    if (!mounted) return;
    setState(() => _trackMutationInFlight = false);

    result.fold(
      (failure) => _showSnackBar(failure.message, isError: true),
      (generation) {
        _upsertGeneration(generation);
        _showSnackBar('Suno generation queued.');
      },
    );
  }

  Future<void> _openSunoConfigSheet() async {
    final request = await showModalBottomSheet<UpdateSunoConfigRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SunoConfigBottomSheet(
        currentConfig: _sunoConfig,
        playlists: _savedPlaylists,
      ),
    );

    if (!mounted || request == null) return;

    final result = await sl<UpdateSunoConfig>()(request);
    if (!mounted) return;

    result.fold(
      (failure) => _showSnackBar(failure.message, isError: true),
      (config) {
        setState(() => _sunoConfig = config);
        _showSnackBar('Suno config updated.');
      },
    );
  }

  Future<void> _cancelSunoGeneration(String generationId) async {
    final result = await sl<CancelSunoGeneration>()(generationId);
    if (!mounted) return;

    result.fold(
      (failure) => _showSnackBar(failure.message, isError: true),
      (_) {
        final generation = _findGenerationById(generationId);
        if (generation != null) {
          final cancelledGeneration = generation.copyWith(
            generationStatus: SunoGenerationStatus.cancelled,
          );
          _upsertGeneration(cancelledGeneration);
          final playbackContext = _currentSunoPlaybackContext();
          if (playbackContext != null) {
            unawaited(
              _sunoPlaybackOrchestrator.handleGenerationSnapshot(
                generation: cancelledGeneration,
                context: playbackContext,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _toggleTrackStatus(ApiTrack track) async {
    final result = await sl<ToggleTrackStatus>()(track.id);
    if (!mounted) return;

    result.fold(
      (failure) => _showSnackBar(failure.message, isError: true),
      (_) async {
        await _loadTracks();
        _showSnackBar('Track status updated.');
      },
    );
  }

  Future<void> _retranscodeTrack(ApiTrack track) async {
    final result = await sl<RetranscodeTrack>()(track.id);
    if (!mounted) return;

    result.fold(
      (failure) => _showSnackBar(failure.message, isError: true),
      (_) {
        _upsertTrack(
          track.copyWith(
            metadataStatusOverride: TrackMetadataStatus.metadataPending,
          ),
        );
        _startMetadataPollingForTrackId(track.id);
        _showSnackBar('Retranscode requested.');
      },
    );
  }

  Future<void> _deleteTrack(ApiTrack track) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete track?'),
        content: Text(
          'This will remove "${track.title}" from the library if the backend allows it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await sl<DeleteTrack>()(track.id);
    if (!mounted) return;

    result.fold(
      (failure) => _showSnackBar(failure.message, isError: true),
      (_) {
        setState(() => _tracks.removeWhere((item) => item.id == track.id));
        _showSnackBar('Track deleted.');
      },
    );
  }

  void _unblockSong(String songId) {
    setState(() => _blockedSongs.removeWhere((s) => s.id == songId));
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: isError ? Colors.red.shade600 : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.fromBrightness(Theme.of(context).brightness);
    final session = context.watch<SessionCubit>().state;
    final canManagePlaylists = !session.isPlaybackDevice &&
        (session.currentRole == UserRole.brandManager ||
            session.currentRole == UserRole.storeManager);
    final canManageTracks = !session.isPlaybackDevice &&
        session.currentRole == UserRole.brandManager;
    final canAutoStreamSuno =
        canManageTracks && ((session.currentSpace?.id ?? '').isNotEmpty);
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
              if (_filter == _LibraryFilter.tracks)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTrackScopeChip(
                          palette: palette,
                          label: 'All',
                          selected:
                              _trackProviderScope == _TrackProviderScope.all,
                          onTap: () {
                            setState(() {
                              _trackProviderScope = _TrackProviderScope.all;
                            });
                            unawaited(_loadTracks());
                          },
                        ),
                        _buildTrackScopeChip(
                          palette: palette,
                          label: 'Custom',
                          selected:
                              _trackProviderScope == _TrackProviderScope.custom,
                          onTap: () {
                            setState(() {
                              _trackProviderScope = _TrackProviderScope.custom;
                            });
                            unawaited(_loadTracks());
                          },
                        ),
                        _buildTrackScopeChip(
                          palette: palette,
                          label: 'Suno',
                          selected:
                              _trackProviderScope == _TrackProviderScope.suno,
                          onTap: () {
                            setState(() {
                              _trackProviderScope = _TrackProviderScope.suno;
                            });
                            unawaited(_loadTracks());
                          },
                        ),
                        _buildTrackScopeChip(
                          palette: palette,
                          label: _showAiOnly ? 'AI Only' : 'All Origins',
                          selected: _showAiOnly,
                          onTap: () {
                            setState(() => _showAiOnly = !_showAiOnly);
                            unawaited(_loadTracks());
                          },
                        ),
                        if (canManageTracks)
                          _buildTrackScopeChip(
                            palette: palette,
                            label: 'Suno Config',
                            selected: false,
                            onTap: _openSunoConfigSheet,
                          ),
                      ],
                    ),
                  ),
                ),
              if (_filter == _LibraryFilter.tracks &&
                  _sunoGenerations.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _SunoGenerationPanel(
                      palette: palette,
                      generations: _sunoGenerations,
                      onCancel: canManageTracks ? _cancelSunoGeneration : null,
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
                _tracks.isEmpty
                    ? _emptyTracksSliver(palette)
                    : _tracksSliver(
                        palette,
                        canManageTracks: canManageTracks,
                      ),

              SliverToBoxAdapter(child: SizedBox(height: contentBottomSpacing)),
            ],
          ),
          if (_filter == _LibraryFilter.playlists && canManagePlaylists)
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
          if (canManageTracks)
            Positioned(
              right: 16,
              bottom: fabBottomOffset + 148,
              child: FloatingActionButton.small(
                heroTag: 'suno-track-fab',
                onPressed: _trackMutationInFlight || !canAutoStreamSuno
                    ? null
                    : _openSunoGenerationSheet,
                backgroundColor: palette.overlay,
                foregroundColor: palette.accent,
                elevation: 4,
                child: _trackMutationInFlight
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: palette.accent,
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 18),
              ),
            ),
          if (canManageTracks)
            Positioned(
              right: 16,
              bottom: fabBottomOffset + 74,
              child: FloatingActionButton.small(
                heroTag: 'upload-track-fab',
                onPressed: () => _openTrackEditorSheet(),
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
      case _LibraryFilter.tracks:
        return 'Brand Tracks';
      case _LibraryFilter.blocked:
        return 'Blocked Songs';
    }
  }

  String get _sectionCount {
    switch (_filter) {
      case _LibraryFilter.playlists:
        return '${_savedPlaylists.length} playlist';
      case _LibraryFilter.tracks:
        return '${_tracks.length} track';
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

  Widget _emptyTracksSliver(_Palette palette) {
    return SliverFillRemaining(
      child: _EmptyState(
        icon: LucideIcons.music4,
        title: 'No tracks yet',
        subtitle: 'Tracks from uploads and Suno generation will appear here.',
        palette: palette,
      ),
    );
  }

  Widget _tracksSliver(
    _Palette palette, {
    required bool canManageTracks,
  }) {
    return SliverList.builder(
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        return _TrackLibraryTile(
          track: track,
          palette: palette,
          canManage: canManageTracks,
          onTap: () => _showTrackDetailSheet(track, canManage: canManageTracks),
        );
      },
    );
  }

  Widget _buildTrackScopeChip({
    required _Palette palette,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: palette.accent,
      showCheckmark: false,
      labelStyle: GoogleFonts.inter(
        color: selected ? palette.textOnAccent : palette.textMuted,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      backgroundColor: palette.card,
      side: BorderSide(
        color: selected ? palette.accent : palette.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }

  Future<void> _showTrackDetailSheet(
    ApiTrack track, {
    required bool canManage,
  }) async {
    final action = await showModalBottomSheet<_TrackLibraryAction>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrackDetailBottomSheet(
        track: track,
        canManage: canManage,
      ),
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _TrackLibraryAction.edit:
        await _openTrackEditorSheet(track: track);
        break;
      case _TrackLibraryAction.toggleStatus:
        await _toggleTrackStatus(track);
        break;
      case _TrackLibraryAction.retranscode:
        await _retranscodeTrack(track);
        break;
      case _TrackLibraryAction.delete:
        await _deleteTrack(track);
        break;
    }
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
enum _TrackLibraryAction { edit, toggleStatus, retranscode, delete }

class _TrackLibraryTile extends StatelessWidget {
  const _TrackLibraryTile({
    required this.track,
    required this.palette,
    required this.canManage,
    required this.onTap,
  });

  final ApiTrack track;
  final _Palette palette;
  final bool canManage;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: track.coverImageUrl != null
                      ? Image.network(
                          track.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _CoverFallback(palette: palette),
                        )
                      : _CoverFallback(palette: palette),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
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
                      track.artist ?? 'Unknown artist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _TrackBadge(
                          palette: palette,
                          label: track.provider?.displayName ?? 'Track',
                        ),
                        _TrackBadge(
                          palette: palette,
                          label: track.metadataStatus.displayName,
                          accentColor: _metadataColor(track.metadataStatus),
                        ),
                        _TrackBadge(
                          palette: palette,
                          label: track.isStreamReady
                              ? 'Stream Ready'
                              : 'Waiting HLS',
                          accentColor: track.isStreamReady
                              ? Colors.green.shade600
                              : Colors.blueGrey.shade600,
                        ),
                        if (track.isAiGenerated == true)
                          _TrackBadge(
                            palette: palette,
                            label: 'AI',
                            accentColor: palette.accentAlt,
                          ),
                        if ((track.transcodeStatus ?? '').isNotEmpty)
                          _TrackBadge(
                            palette: palette,
                            label: track.transcodeStatus!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    track.formattedDuration,
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (canManage)
                    Icon(Icons.more_horiz_rounded,
                        color: palette.textMuted, size: 18)
                  else
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

  Color _metadataColor(TrackMetadataStatus status) {
    switch (status) {
      case TrackMetadataStatus.metadataPending:
        return Colors.amber.shade700;
      case TrackMetadataStatus.metadataReady:
        return Colors.green.shade600;
      case TrackMetadataStatus.metadataUnknown:
        return Colors.orange.shade800;
    }
  }
}

class _TrackBadge extends StatelessWidget {
  const _TrackBadge({
    required this.palette,
    required this.label,
    this.accentColor,
  });

  final _Palette palette;
  final String label;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? palette.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TrackDetailBottomSheet extends StatelessWidget {
  const _TrackDetailBottomSheet({
    required this.track,
    required this.canManage,
  });

  final ApiTrack track;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.fromBrightness(Theme.of(context).brightness);
    final metadataRows = <MapEntry<String, String?>>[
      MapEntry('Provider', track.provider?.displayName),
      MapEntry('Metadata', track.metadataStatus.displayName),
      MapEntry('Stream', track.isStreamReady ? 'Ready' : 'Waiting for HLS'),
      MapEntry('Status', track.status.displayName),
      MapEntry('BPM', track.bpm?.toString()),
      MapEntry('Energy', track.energyLevel?.toStringAsFixed(2)),
      MapEntry('Valence', track.valence?.toStringAsFixed(2)),
      MapEntry('Suno Clip', track.sunoClipId),
      MapEntry('Generated At', track.generatedAt?.toLocal().toString()),
      MapEntry('Last Played', track.lastPlayedAt?.toLocal().toString()),
      MapEntry('HLS', track.hlsUrl),
      MapEntry('Source Audio', track.sourceAudioUrl),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  track.title,
                  style: GoogleFonts.poppins(
                    color: palette.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  track.artist ?? 'Unknown artist',
                  style: GoogleFonts.inter(
                    color: palette.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                ...metadataRows
                    .where((entry) => (entry.value ?? '').trim().isNotEmpty)
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 110,
                              child: Text(
                                entry.key,
                                style: GoogleFonts.inter(
                                  color: palette.textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value!,
                                style: GoogleFonts.inter(
                                  color: palette.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                if (canManage) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _TrackActionButton(
                        label: 'Edit',
                        icon: Icons.edit_outlined,
                        onTap: () => Navigator.pop(
                          context,
                          _TrackLibraryAction.edit,
                        ),
                      ),
                      _TrackActionButton(
                        label:
                            track.status.isActive ? 'Deactivate' : 'Activate',
                        icon: track.status.isActive
                            ? Icons.toggle_off_outlined
                            : Icons.toggle_on_outlined,
                        onTap: () => Navigator.pop(
                          context,
                          _TrackLibraryAction.toggleStatus,
                        ),
                      ),
                      _TrackActionButton(
                        label: 'Retranscode',
                        icon: Icons.sync_rounded,
                        onTap: () => Navigator.pop(
                          context,
                          _TrackLibraryAction.retranscode,
                        ),
                      ),
                      _TrackActionButton(
                        label: 'Delete',
                        icon: Icons.delete_outline_rounded,
                        isDestructive: true,
                        onTap: () => Navigator.pop(
                          context,
                          _TrackLibraryAction.delete,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackActionButton extends StatelessWidget {
  const _TrackActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red.shade600 : null;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, color: color, size: 18),
      label: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SunoGenerationPanel extends StatelessWidget {
  const _SunoGenerationPanel({
    required this.palette,
    required this.generations,
    this.onCancel,
  });

  final _Palette palette;
  final List<SunoGeneration> generations;
  final Future<void> Function(String generationId)? onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Suno Jobs',
            style: GoogleFonts.poppins(
              color: palette.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...generations.map(
            (generation) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.overlay,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            generation.title ?? generation.id,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              color: palette.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _TrackBadge(
                          palette: palette,
                          label: generation.generationStatus.displayName,
                          accentColor:
                              _statusColor(generation.generationStatus),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: ((generation.progressPercent ?? 0).clamp(0, 100)) /
                          100,
                      minHeight: 6,
                      backgroundColor: palette.border,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      generation.errorMessage ??
                          'Progress ${generation.progressPercent ?? 0}%',
                      style: GoogleFonts.inter(
                        color: palette.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    if (onCancel != null &&
                        !generation.generationStatus.isTerminal) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => onCancel!(generation.id),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(SunoGenerationStatus status) {
    switch (status) {
      case SunoGenerationStatus.queued:
        return Colors.amber.shade700;
      case SunoGenerationStatus.generating:
        return Colors.blue.shade600;
      case SunoGenerationStatus.completed:
        return Colors.green.shade600;
      case SunoGenerationStatus.failed:
        return Colors.red.shade600;
      case SunoGenerationStatus.cancelled:
        return Colors.orange.shade700;
      case SunoGenerationStatus.unknown:
        return Colors.grey.shade600;
    }
  }
}

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
          color: Colors.green.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
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
      child: Icon(
        LucideIcons.music4,
        color: palette.textMuted.withValues(alpha: 0.5),
        size: size * 0.4,
      ),
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
              child: Icon(
                icon,
                size: 38,
                color: palette.textMuted.withValues(alpha: 0.5),
              ),
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
class _TrackEditorResult {
  final String title;
  final String? trackId;
  final bool isEditMode;

  const _TrackEditorResult({
    required this.title,
    required this.trackId,
    required this.isEditMode,
  });

  String get successMessage => isEditMode
      ? 'Track updated successfully.'
      : 'Track uploaded successfully.';
}

class _UploadTrackBottomSheet extends StatefulWidget {
  const _UploadTrackBottomSheet({this.track});

  final ApiTrack? track;

  bool get isEditMode => track != null;

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
  void initState() {
    super.initState();
    final existingTrack = widget.track;
    if (existingTrack != null) {
      _titleController.text = existingTrack.title;
      _artistController.text = existingTrack.artist ?? '';
      _genreController.text = existingTrack.genre ?? '';
    }
  }

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

    if (!widget.isEditMode && _audioFile == null) {
      _showError('Please select an audio file.');
      return;
    }

    setState(() => _submitting = true);

    try {
      if (widget.isEditMode) {
        final trackId = widget.track!.id;
        final result = await sl<UpdateTrack>()(
          trackId,
          UpdateTrackRequest(
            title: _titleController.text.trim(),
            artist: _nullableText(_artistController.text),
            genre: _nullableText(_genreController.text),
            audioFile: _audioFile != null ? _toUploadFile(_audioFile!) : null,
            coverImageFile:
                _coverFile != null ? _toUploadFile(_coverFile!) : null,
          ),
        );

        if (!mounted) return;
        result.fold(
          (failure) => _showError(failure.message),
          (_) => Navigator.pop(
            context,
            _TrackEditorResult(
              title: _titleController.text.trim(),
              trackId: trackId,
              isEditMode: true,
            ),
          ),
        );
      } else {
        final result = await sl<CreateTrack>()(
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
        result.fold(
          (failure) => _showError(failure.message),
          (_) => Navigator.pop(
            context,
            _TrackEditorResult(
              title: _titleController.text.trim(),
              trackId: null,
              isEditMode: false,
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      _showError(
        widget.isEditMode
            ? 'Failed to update track.'
            : 'Failed to upload track.',
      );
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
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04);

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
                        widget.isEditMode ? 'Edit Track' : 'Upload Track',
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
                    widget.isEditMode
                        ? 'Update metadata, audio, or cover for this track.'
                        : 'Only Brand Manager can upload new tracks.',
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
                    title: widget.isEditMode
                        ? 'Replace Audio File'
                        : 'Audio File *',
                    subtitle: _audioFile?.name ??
                        (widget.isEditMode
                            ? 'Optional replacement audio'
                            : 'mp3, wav, aac, flac, ogg, m4a (max 50 MB)'),
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
                        _submitting
                            ? (widget.isEditMode ? 'Saving...' : 'Uploading...')
                            : (widget.isEditMode
                                ? 'Save Changes'
                                : 'Upload Track'),
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
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.04),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }
}

class _GenerateSunoTrackBottomSheet extends StatefulWidget {
  const _GenerateSunoTrackBottomSheet({
    required this.playlists,
    required this.initialConfig,
  });

  final List<PlaylistEntity> playlists;
  final SunoConfig? initialConfig;

  @override
  State<_GenerateSunoTrackBottomSheet> createState() =>
      _GenerateSunoTrackBottomSheetState();
}

class _GenerateSunoTrackBottomSheetState
    extends State<_GenerateSunoTrackBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _promptController = TextEditingController();
  String? _selectedPlaylistId;
  bool _autoAddToTargetPlaylist = false;

  @override
  void initState() {
    super.initState();
    _selectedPlaylistId = widget.initialConfig?.sunoDefaultPlaylistId;
    _autoAddToTargetPlaylist = _selectedPlaylistId != null;
    _promptController.text = widget.initialConfig?.sunoPromptTemplate ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.white60 : Colors.black54;

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
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Form(
              key: _formKey,
              child: Column(
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
                  const SizedBox(height: 16),
                  Text(
                    'Generate with Suno',
                    style: GoogleFonts.poppins(
                      color: textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create an AI track request and let realtime updates drive progress.',
                    style: GoogleFonts.inter(
                      color: textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _titleController,
                    decoration: _editorDecoration(
                      label: 'Title *',
                      isDark: isDark,
                    ),
                    validator: (value) => (value?.trim().isEmpty ?? true)
                        ? 'Title is required.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _artistController,
                    decoration: _editorDecoration(
                      label: 'Artist',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _promptController,
                    maxLines: 4,
                    decoration: _editorDecoration(
                      label: 'Prompt (optional)',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: widget.playlists.any(
                            (playlist) => playlist.id == _selectedPlaylistId)
                        ? _selectedPlaylistId
                        : null,
                    decoration: _editorDecoration(
                      label: 'Target playlist',
                      isDark: isDark,
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No target playlist'),
                      ),
                      ...widget.playlists.map(
                        (playlist) => DropdownMenuItem<String?>(
                          value: playlist.id,
                          child: Text(playlist.title),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedPlaylistId = value;
                        if (value == null) {
                          _autoAddToTargetPlaylist = false;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value:
                        _autoAddToTargetPlaylist && _selectedPlaylistId != null,
                    onChanged: _selectedPlaylistId == null
                        ? null
                        : (value) =>
                            setState(() => _autoAddToTargetPlaylist = value),
                    title: Text(
                      'Auto-add to selected playlist',
                      style: GoogleFonts.inter(
                        color: textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        final isValid =
                            _formKey.currentState?.validate() ?? false;
                        if (!isValid) return;
                        Navigator.pop(
                          context,
                          CreateSunoGenerationRequest(
                            prompt: _nullable(_promptController.text),
                            title: _titleController.text.trim(),
                            artist: _nullable(_artistController.text),
                            targetPlaylistId: _selectedPlaylistId,
                            autoAddToTargetPlaylist: _autoAddToTargetPlaylist,
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: const Text('Queue Generation'),
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
}

class _SunoConfigBottomSheet extends StatefulWidget {
  const _SunoConfigBottomSheet({
    required this.currentConfig,
    required this.playlists,
  });

  final SunoConfig? currentConfig;
  final List<PlaylistEntity> playlists;

  @override
  State<_SunoConfigBottomSheet> createState() => _SunoConfigBottomSheetState();
}

class _SunoConfigBottomSheetState extends State<_SunoConfigBottomSheet> {
  final _promptTemplateController = TextEditingController();
  String? _selectedPlaylistId;

  @override
  void initState() {
    super.initState();
    _promptTemplateController.text =
        widget.currentConfig?.sunoPromptTemplate ?? '';
    _selectedPlaylistId = widget.currentConfig?.sunoDefaultPlaylistId;
  }

  @override
  void dispose() {
    _promptTemplateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
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
                const SizedBox(height: 16),
                Text(
                  'Suno Config',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _promptTemplateController,
                  maxLines: 5,
                  decoration: _editorDecoration(
                    label: 'Prompt template',
                    isDark: isDark,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: widget.playlists
                          .any((playlist) => playlist.id == _selectedPlaylistId)
                      ? _selectedPlaylistId
                      : null,
                  decoration: _editorDecoration(
                    label: 'Default playlist',
                    isDark: isDark,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No default playlist'),
                    ),
                    ...widget.playlists.map(
                      (playlist) => DropdownMenuItem<String?>(
                        value: playlist.id,
                        child: Text(playlist.title),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedPlaylistId = value),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      UpdateSunoConfigRequest(
                        sunoPromptTemplate: _nullable(
                          _promptTemplateController.text,
                        ),
                        sunoDefaultPlaylistId: _selectedPlaylistId,
                      ),
                    ),
                    child: const Text('Save Config'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _editorDecoration({
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
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
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
        overlay: Colors.white.withValues(alpha: 0.06),
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
