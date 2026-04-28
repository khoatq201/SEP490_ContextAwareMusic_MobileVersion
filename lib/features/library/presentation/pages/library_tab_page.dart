import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/ai_generation_mode_enum.dart';
import '../../../../core/enums/music_provider_enum.dart';
import '../../../../core/enums/queue_insert_mode_enum.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../core/utils/cams_queue_actions.dart';
import '../../../../core/widgets/queue_mode_picker_bottom_sheet.dart';
import '../../../../core/widgets/select_playlist_bottom_sheet.dart';
import '../../../../core/widgets/song_options_bottom_sheet.dart';
import '../../../../injection_container.dart';
import '../../../cams/data/services/store_hub_service.dart';
import '../../../home/domain/entities/playlist_entity.dart';
import '../../../home/domain/entities/song_entity.dart';
import '../../../moods/domain/entities/mood.dart';
import '../../../moods/domain/usecases/get_moods.dart';
import '../../domain/create_library_playlist_usecase.dart';
import '../../domain/playlist_creation_guard.dart';
import '../../../playlists/data/datasources/playlist_remote_datasource.dart';
import '../../../suno/data/datasources/suno_remote_datasource.dart';
import '../../../suno/domain/entities/suno_brand_music_profile.dart';
import '../../../suno/domain/entities/suno_config.dart';
import '../../../suno/domain/entities/suno_generation.dart';
import '../../../suno/domain/entities/suno_generation_status.dart';
import '../../../suno/domain/services/brand_profile_suno_prompt.dart';
import '../../../suno/domain/services/suno_playback_orchestrator.dart';
import '../../../suno/domain/usecases/suno_usecases.dart';
import '../../../tracks/data/datasources/track_remote_datasource.dart';
import '../../../tracks/domain/entities/api_track.dart';
import '../../../tracks/domain/entities/copyright_scan_policy_outcome.dart';
import '../../../tracks/domain/entities/track_copyright_clearance_status.dart';
import '../../../tracks/domain/entities/track_filter.dart';
import '../../../tracks/domain/entities/track_metadata_status.dart';
import '../../../tracks/domain/usecases/track_usecases.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Filter options
// ─────────────────────────────────────────────────────────────────────────────
enum _LibraryFilter { playlists, tracks, blocked }

enum _TrackProviderScope { all, custom, suno }

enum _SunoPromptMode { manual, brandProfile }

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
  List<Mood> _moods = [];
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
      final futures = <Future<void>>[
        _loadPlaylists(),
        _loadMoods(),
        _loadTracks(),
        _loadSunoConfig(),
      ];
      if (_canManageSunoTracks()) {
        futures.add(_loadSunoGenerationHistory());
      }
      await Future.wait(futures);
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

  Future<void> _loadMoods() async {
    try {
      final result = await sl<GetMoods>()();
      if (!mounted) return;
      result.fold(
        (_) {},
        (moods) => setState(() => _moods = moods),
      );
    } catch (_) {
      // Suno generation can still work without mood labels.
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

  Future<void> _loadSunoGenerationHistory() async {
    final result = await sl<GetSunoGenerations>()(page: 1, pageSize: 6);
    if (!mounted) return;

    result.fold(
      (_) {},
      (generations) {
        setState(() {
          _sunoGenerations
            ..clear()
            ..addAll(generations.take(6));
        });

        final playbackContext = _currentSunoPlaybackContext();
        if (playbackContext == null) return;
        for (final generation in generations) {
          if (generation.generationStatus.isTerminal) {
            continue;
          }
          unawaited(
            _sunoPlaybackOrchestrator.handleGenerationSnapshot(
              generation: generation,
              context: playbackContext,
            ),
          );
        }
      },
    );
  }

  bool _canManageSunoTracks() {
    final session = context.read<SessionCubit>().state;
    return !session.isPlaybackDevice &&
        session.currentRole == UserRole.brandManager;
  }

  Future<void> _ensureSunoRealtimeSubscription() async {
    final session = context.read<SessionCubit>().state;
    final canManageTracks = _canManageSunoTracks();
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
    if (!mounted || event.id.isEmpty) return;

    final playbackContext = _currentSunoPlaybackContext();
    if (playbackContext == null) {
      final previous = _findGenerationById(event.id);
      _upsertGeneration(
        (previous ?? SunoGeneration(id: event.id)).copyWith(
          brandId: event.brandId.isEmpty ? null : event.brandId,
          generationStatus: event.generationStatus,
          progressPercent: event.progressPercent,
          errorMessage: event.errorMessage,
          generatedTrackId: event.generatedTrackId,
        ),
      );
      return;
    }

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
    final session = context.read<SessionCubit>().state;
    final storeId = session.currentStore?.id;
    final brandId = session.currentStore?.brandId;
    final canCreateBrandWide =
        session.currentRole == UserRole.brandManager && brandId != null;
    final guardResult = evaluatePlaylistCreationGuard(
      isPlaybackDevice: session.isPlaybackDevice,
      currentRole: session.currentRole,
      currentStoreId: storeId,
    );
    if (!guardResult.isAllowed) {
      _showSnackBar(guardResult.errorMessage ?? 'Cannot create playlist.',
          isError: true);
      return;
    }

    final draft = await showModalBottomSheet<_CreatePlaylistDraft>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePlaylistBottomSheet(
        moods: _moods,
        tracks: _tracks,
        storeName: session.currentStore?.name,
        canCreateBrandWide: canCreateBrandWide,
      ),
    );

    if (draft == null) return;
    if (!mounted) return;
    final resolvedStoreId = storeId!;

    try {
      final createdPlaylistId = await createLibraryPlaylist(
        playlistDataSource: sl<PlaylistRemoteDataSource>(),
        name: draft.name,
        storeId: draft.isBrandWide ? null : resolvedStoreId,
        brandId: draft.isBrandWide ? brandId : null,
        description: draft.description,
        moodId: draft.moodId,
        isDefault: draft.isDefault ? true : null,
        trackIds: draft.trackIds,
        createBrandWide: draft.isBrandWide,
      );

      await _loadPlaylists();
      if (!mounted) return;

      _showSnackBar(
        draft.trackIds.isEmpty
            ? (draft.isBrandWide
                ? 'Brand-wide playlist created.'
                : 'Playlist created.')
            : '${draft.isBrandWide ? 'Brand-wide playlist' : 'Playlist'} created with ${draft.trackIds.length} track${draft.trackIds.length == 1 ? '' : 's'}.',
      );

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

  Future<void> _openTrackEditorSheet({ApiTrack? track}) async {
    final result = await showModalBottomSheet<Object?>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UploadTrackBottomSheet(track: track),
    );

    if (!mounted || result is! _TrackEditorResult) return;
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
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GenerateSunoTrackBottomSheet(
        playlists: _savedPlaylists,
        moods: _moods,
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
      useRootNavigator: true,
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

  Future<void> _reviewTrackCopyright(
    ApiTrack track, {
    required bool approve,
  }) async {
    final result = await sl<SetTrackCopyrightClearance>()(
      track.id,
      approve: approve,
    );
    if (!mounted) return;

    result.fold(
      (failure) => _showSnackBar(failure.message, isError: true),
      (_) async {
        final refreshed = await sl<GetTrackById>()(track.id);
        if (!mounted) return;
        refreshed.fold(
          (_) => unawaited(_loadTracks(silent: true)),
          _upsertTrack,
        );
        _showSnackBar(
          approve ? 'Track approved for playback.' : 'Track rejected.',
        );
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
    final canReviewTrackCopyright = !session.isPlaybackDevice &&
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
                      playlists: _savedPlaylists,
                      moods: _moods,
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
                        canReviewTrackCopyright: canReviewTrackCopyright,
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
          onMoreTap: () => _openPlaylistQueueActions(playlist),
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
    required bool canReviewTrackCopyright,
  }) {
    return SliverList.builder(
      itemCount: _tracks.length,
      itemBuilder: (context, index) {
        final track = _tracks[index];
        return _TrackLibraryTile(
          track: track,
          palette: palette,
          canManage: canManageTracks,
          canReviewCopyright: canReviewTrackCopyright,
          onMoreTap: () => _openTrackPlaybackActions(track),
          onTap: () => _showTrackDetailSheet(
            track,
            canManage: canManageTracks,
            canReviewCopyright: canReviewTrackCopyright,
          ),
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
    required bool canReviewCopyright,
  }) async {
    final action = await showModalBottomSheet<_TrackLibraryAction>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TrackDetailBottomSheet(
        track: track,
        canManage: canManage,
        canReviewCopyright: canReviewCopyright,
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
      case _TrackLibraryAction.approveCopyright:
        await _reviewTrackCopyright(track, approve: true);
        break;
      case _TrackLibraryAction.rejectCopyright:
        await _reviewTrackCopyright(track, approve: false);
        break;
    }
  }

  SongEntity _songEntityForTrack(ApiTrack track) {
    return SongEntity(
      id: track.id,
      title: track.title,
      artist: track.artist ?? 'Unknown artist',
      duration: track.durationSec ?? 0,
      coverUrl: track.coverImageUrl,
      streamUrl: track.hlsUrl,
    );
  }

  Future<void> _openTrackPlaybackActions(ApiTrack track) async {
    final song = _songEntityForTrack(track);
    final option = await showModalBottomSheet<SongOption>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SongOptionsBottomSheet(
        song: song,
        showPlayNow: true,
        showPlayNext: true,
        enableAddToQueue: true,
        addToQueueLabel: 'Add to space queue',
      ),
    );

    if (!mounted || option == null) return;

    switch (option) {
      case SongOption.addToPlaylist:
        await showModalBottomSheet<void>(
          context: context,
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => SelectPlaylistBottomSheet(song: song),
        );
        return;
      case SongOption.playNow:
        queueTrackToCurrentSpace(
          context,
          trackId: track.id,
          mode: QueueInsertModeEnum.playNow,
          reason: buildQueueActionReason(
            source: 'Library',
            itemType: 'track',
            mode: QueueInsertModeEnum.playNow,
          ),
        );
        return;
      case SongOption.playNext:
        queueTrackToCurrentSpace(
          context,
          trackId: track.id,
          mode: QueueInsertModeEnum.playNext,
          reason: buildQueueActionReason(
            source: 'Library',
            itemType: 'track',
            mode: QueueInsertModeEnum.playNext,
          ),
        );
        return;
      case SongOption.addToQueue:
        queueTrackToCurrentSpace(
          context,
          trackId: track.id,
          mode: QueueInsertModeEnum.addToQueue,
          reason: buildQueueActionReason(
            source: 'Library',
            itemType: 'track',
            mode: QueueInsertModeEnum.addToQueue,
          ),
        );
        return;
      case SongOption.goToAlbum:
      case SongOption.goToArtist:
      case SongOption.block:
      case SongOption.share:
        return;
    }
  }

  Future<void> _openPlaylistQueueActions(PlaylistEntity playlist) async {
    final mode = await showQueueModePickerBottomSheet(
      context,
      title: 'Add playlist to queue',
      subtitle: playlist.title,
    );

    if (!mounted || mode == null) return;

    queuePlaylistToCurrentSpace(
      context,
      playlistId: playlist.id,
      mode: mode,
      reason: buildQueueActionReason(
        source: 'Library',
        itemType: 'playlist',
        mode: mode,
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
    required this.onMoreTap,
  });

  final PlaylistEntity playlist;
  final _Palette palette;
  final VoidCallback onTap;
  final VoidCallback onMoreTap;

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
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: palette.textMuted,
                      size: 20,
                    ),
                    splashRadius: 20,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: onMoreTap,
                  ),
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
enum _TrackLibraryAction {
  edit,
  toggleStatus,
  retranscode,
  delete,
  approveCopyright,
  rejectCopyright,
}

Color _trackMetadataColor(TrackMetadataStatus status) {
  switch (status) {
    case TrackMetadataStatus.metadataPending:
      return Colors.amber.shade700;
    case TrackMetadataStatus.metadataReady:
      return Colors.green.shade600;
    case TrackMetadataStatus.metadataUnknown:
      return Colors.orange.shade800;
  }
}

Color _copyrightClearanceColorValue(
  TrackCopyrightClearanceStatus status,
) {
  switch (status) {
    case TrackCopyrightClearanceStatus.pending:
      return Colors.amber.shade700;
    case TrackCopyrightClearanceStatus.approved:
      return Colors.green.shade600;
    case TrackCopyrightClearanceStatus.rejected:
      return Colors.red.shade600;
    case TrackCopyrightClearanceStatus.unknown:
      return Colors.blueGrey.shade600;
  }
}

Color _copyrightPolicyColorValue(
  CopyrightScanPolicyOutcome outcome,
) {
  switch (outcome) {
    case CopyrightScanPolicyOutcome.clear:
      return Colors.green.shade600;
    case CopyrightScanPolicyOutcome.flagged:
      return Colors.red.shade600;
    case CopyrightScanPolicyOutcome.manual:
      return Colors.orange.shade700;
    case CopyrightScanPolicyOutcome.unknown:
      return Colors.blueGrey.shade600;
  }
}

class _TrackLibraryTile extends StatelessWidget {
  const _TrackLibraryTile({
    required this.track,
    required this.palette,
    required this.canManage,
    required this.canReviewCopyright,
    required this.onMoreTap,
    required this.onTap,
  });

  final ApiTrack track;
  final _Palette palette;
  final bool canManage;
  final bool canReviewCopyright;
  final VoidCallback onMoreTap;
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
                          accentColor:
                              _trackMetadataColor(track.metadataStatus),
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
                        if (track.copyrightClearanceStatus != null)
                          _TrackBadge(
                            palette: palette,
                            label: track.copyrightClearanceStatus!.displayName,
                            accentColor: _copyrightClearanceColorValue(
                              track.copyrightClearanceStatus!,
                            ),
                          ),
                        if (track.copyrightScanPolicyOutcome != null)
                          _TrackBadge(
                            palette: palette,
                            label:
                                track.copyrightScanPolicyOutcome!.displayName,
                            accentColor: _copyrightPolicyColorValue(
                              track.copyrightScanPolicyOutcome!,
                            ),
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
                  IconButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: palette.textMuted,
                      size: 18,
                    ),
                    splashRadius: 18,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: onMoreTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
    required this.canReviewCopyright,
  });

  final ApiTrack track;
  final bool canManage;
  final bool canReviewCopyright;

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
      MapEntry('Generation Prompt', track.generationPrompt),
      MapEntry('Generated At', track.generatedAt?.toLocal().toString()),
      MapEntry('Lyrics URL', track.lyricsUrl),
      MapEntry(
        'Copyright Clearance',
        track.copyrightClearanceStatus?.displayName,
      ),
      MapEntry(
        'Policy Outcome',
        track.copyrightScanPolicyOutcome?.displayName,
      ),
      MapEntry('Matched Title', track.copyrightMatchTitle),
      MapEntry('Matched Artist', track.copyrightMatchArtist),
      MapEntry(
        'Copyright Scanned',
        track.copyrightScannedAtUtc?.toLocal().toString(),
      ),
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
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TrackBadge(
                      palette: palette,
                      label: track.provider?.displayName ?? 'Track',
                    ),
                    _TrackBadge(
                      palette: palette,
                      label: track.metadataStatus.displayName,
                      accentColor: _trackMetadataColor(track.metadataStatus),
                    ),
                    if (track.copyrightClearanceStatus != null)
                      _TrackBadge(
                        palette: palette,
                        label: track.copyrightClearanceStatus!.displayName,
                        accentColor: _copyrightClearanceColorValue(
                          track.copyrightClearanceStatus!,
                        ),
                      ),
                    if (track.copyrightScanPolicyOutcome != null)
                      _TrackBadge(
                        palette: palette,
                        label: track.copyrightScanPolicyOutcome!.displayName,
                        accentColor: _copyrightPolicyColorValue(
                          track.copyrightScanPolicyOutcome!,
                        ),
                      ),
                  ],
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
                if (canReviewCopyright && track.requiresCopyrightReview) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Copyright Review',
                    style: GoogleFonts.inter(
                      color: palette.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _TrackActionButton(
                        label: 'Approve',
                        icon: Icons.verified_rounded,
                        onTap: () => Navigator.pop(
                          context,
                          _TrackLibraryAction.approveCopyright,
                        ),
                      ),
                      _TrackActionButton(
                        label: 'Reject',
                        icon: Icons.gpp_bad_rounded,
                        isDestructive: true,
                        onTap: () => Navigator.pop(
                          context,
                          _TrackLibraryAction.rejectCopyright,
                        ),
                      ),
                    ],
                  ),
                ],
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
    required this.playlists,
    required this.moods,
    this.onCancel,
  });

  final _Palette palette;
  final List<SunoGeneration> generations;
  final List<PlaylistEntity> playlists;
  final List<Mood> moods;
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
                    ..._metadataRowsFor(generation).map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 108,
                              child: Text(
                                entry.key,
                                style: GoogleFonts.inter(
                                  color: palette.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                entry.value,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  color: palette.textPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  List<MapEntry<String, String>> _metadataRowsFor(SunoGeneration generation) {
    final rows = <MapEntry<String, String>>[];
    final moodLabel = _resolveMoodLabel(generation.moodId);
    final playlistLabel = _resolvePlaylistLabel(generation.targetPlaylistId);
    final bpmBand = _bpmBandLabel(generation);

    if (moodLabel != null) {
      rows.add(MapEntry('Mood', moodLabel));
    }
    if (playlistLabel != null) {
      rows.add(MapEntry('Target Playlist', playlistLabel));
    }
    if (generation.aiGenerationMode != null) {
      rows.add(MapEntry('Mode', generation.aiGenerationMode!.displayName));
    }
    if (generation.provider != null) {
      rows.add(MapEntry('Provider', generation.provider!.displayName));
    }
    if (generation.fuzzyProfileName?.trim().isNotEmpty ?? false) {
      rows.add(MapEntry('Fuzzy Profile', generation.fuzzyProfileName!.trim()));
    }
    if (generation.fuzzyProfileTemplate?.trim().isNotEmpty ?? false) {
      rows.add(
        MapEntry('Template', generation.fuzzyProfileTemplate!.trim()),
      );
    }
    if (bpmBand != null) {
      rows.add(MapEntry('BPM Band', bpmBand));
    }
    if (generation.recommendedBpmTarget != null) {
      rows.add(
        MapEntry('Target BPM', generation.recommendedBpmTarget.toString()),
      );
    }
    if (generation.generatedTrackId?.trim().isNotEmpty ?? false) {
      rows.add(
          MapEntry('Generated Track', generation.generatedTrackId!.trim()));
    }
    if (generation.externalTaskId?.trim().isNotEmpty ?? false) {
      rows.add(MapEntry('External Task', generation.externalTaskId!.trim()));
    }
    if (generation.outputAudioUrl?.trim().isNotEmpty ?? false) {
      rows.add(MapEntry('Output Audio', generation.outputAudioUrl!.trim()));
    }
    final completedAt = _formatDateTime(generation.completedAtUtc);
    if (completedAt != null) {
      rows.add(MapEntry('Completed', completedAt));
    }
    final lastPolledAt = _formatDateTime(generation.lastPolledAtUtc);
    if (lastPolledAt != null) {
      rows.add(MapEntry('Last Polled', lastPolledAt));
    }

    return rows;
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

  String? _resolveMoodLabel(String? moodId) {
    final trimmedMoodId = moodId?.trim();
    if (trimmedMoodId == null || trimmedMoodId.isEmpty) {
      return null;
    }
    for (final mood in moods) {
      if (mood.id == trimmedMoodId) {
        return mood.name;
      }
    }
    return trimmedMoodId;
  }

  String? _resolvePlaylistLabel(String? playlistId) {
    final trimmedPlaylistId = playlistId?.trim();
    if (trimmedPlaylistId == null || trimmedPlaylistId.isEmpty) {
      return null;
    }
    for (final playlist in playlists) {
      if (playlist.id == trimmedPlaylistId) {
        return playlist.title;
      }
    }
    return trimmedPlaylistId;
  }

  String? _formatDateTime(DateTime? value) {
    if (value == null) return null;
    return value.toLocal().toString();
  }

  String? _bpmBandLabel(SunoGeneration generation) {
    final min = generation.recommendedBpmMin;
    final max = generation.recommendedBpmMax;
    if (min == null && max == null) return null;
    if (min != null && max != null) {
      return '$min-$max BPM';
    }
    if (min != null) {
      return '$min+ BPM';
    }
    return 'Up to $max BPM';
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

  void _closeSheet() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
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
                        onPressed: _submitting ? null : _closeSheet,
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
    required this.moods,
    required this.initialConfig,
  });

  final List<PlaylistEntity> playlists;
  final List<Mood> moods;
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
  final _genreController = TextEditingController();
  final _promptController = TextEditingController();
  final _bpmMinController = TextEditingController();
  final _bpmMaxController = TextEditingController();
  final _bpmTargetController = TextEditingController();
  String? _selectedMoodId;
  String? _selectedPlaylistId;
  AiGenerationModeEnum? _selectedGenerationMode;
  String? _selectedFuzzyTemplate;
  BrandProfileSunoMood _selectedProfileMood = BrandProfileSunoMood.focus;
  _SunoPromptMode _promptMode = _SunoPromptMode.manual;
  bool _autoAddToTargetPlaylist = true;
  bool _showAdvanced = false;

  void _closeSheet() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  SunoBrandMusicProfile? get _brandProfile {
    final profile = widget.initialConfig?.brandMusicProfile;
    return hasBrandMusicProfileData(profile) ? profile : null;
  }

  bool get _hasConfiguredPromptTemplate =>
      widget.initialConfig?.sunoPromptTemplate?.trim().isNotEmpty ?? false;

  String get _generatedPrompt {
    final profile = _brandProfile;
    if (profile == null) return '';
    return buildBrandProfileSunoPrompt(
      profile: profile,
      mood: _selectedProfileMood,
      title: _nullable(_titleController.text),
      genre: _nullable(_genreController.text),
      artist: _nullable(_artistController.text),
      sunoPromptTemplate: widget.initialConfig?.sunoPromptTemplate,
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedPlaylistId = widget.initialConfig?.sunoDefaultPlaylistId;
    _autoAddToTargetPlaylist = _selectedPlaylistId != null;
    _promptController.text = '';
    _selectedGenerationMode = widget.initialConfig?.aiGenerationMode;
    if (_selectedGenerationMode == AiGenerationModeEnum.unknown) {
      _selectedGenerationMode = null;
    }
    _selectedFuzzyTemplate = widget.initialConfig?.fuzzyProfileTemplate;
    _promptMode = _brandProfile != null
        ? _SunoPromptMode.brandProfile
        : _SunoPromptMode.manual;
    if (_selectedGenerationMode == null &&
        widget.initialConfig?.availableGenerationModes.isNotEmpty == true) {
      _selectedGenerationMode =
          widget.initialConfig!.availableGenerationModes.first;
    }
    if ((_selectedFuzzyTemplate?.trim().isEmpty ?? true) &&
        widget.initialConfig?.availableFuzzyProfileTemplates.isNotEmpty ==
            true) {
      _selectedFuzzyTemplate =
          widget.initialConfig!.availableFuzzyProfileTemplates.first;
    }
    _bpmMinController.text =
        widget.initialConfig?.recommendedBpmMin?.toString() ?? '';
    _bpmMaxController.text =
        widget.initialConfig?.recommendedBpmMax?.toString() ?? '';
    _bpmTargetController.text =
        widget.initialConfig?.recommendedBpmTarget?.toString() ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _genreController.dispose();
    _promptController.dispose();
    _bpmMinController.dispose();
    _bpmMaxController.dispose();
    _bpmTargetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.viewInsets.top -
        24;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.white60 : Colors.black54;
    final brandProfile = _brandProfile;
    final hasBrandProfile = brandProfile != null;
    final generatedPrompt = _generatedPrompt;
    final sortedMoods = [...widget.moods]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final generationModes = _generationModeOptions;
    final fuzzyTemplates = _fuzzyTemplateOptions;
    final hasAdvancedOptions = generationModes.isNotEmpty ||
        fuzzyTemplates.isNotEmpty ||
        widget.initialConfig?.recommendedBpmMin != null ||
        widget.initialConfig?.recommendedBpmMax != null ||
        widget.initialConfig?.recommendedBpmTarget != null;
    final canSubmit = _promptMode != _SunoPromptMode.brandProfile ||
        generatedPrompt.trim().isNotEmpty;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: mediaQuery.viewInsets.bottom + 16,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
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
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Close',
                                onPressed: _closeSheet,
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Prompt mode',
                            style: GoogleFonts.inter(
                              color: textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ChoiceChip(
                                label: const Text('Manual prompt'),
                                selected: _promptMode == _SunoPromptMode.manual,
                                onSelected: (_) => setState(
                                  () => _promptMode = _SunoPromptMode.manual,
                                ),
                              ),
                              ChoiceChip(
                                label: const Text('Brand music profile'),
                                selected:
                                    _promptMode == _SunoPromptMode.brandProfile,
                                onSelected: hasBrandProfile
                                    ? (_) => setState(
                                          () => _promptMode =
                                              _SunoPromptMode.brandProfile,
                                        )
                                    : null,
                              ),
                            ],
                          ),
                          if (!hasBrandProfile) ...[
                            const SizedBox(height: 10),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                'Brand profile mode is unavailable for this brand because Suno config did not return a CAMS music profile snapshot yet.',
                                style: GoogleFonts.inter(
                                  color: textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                          if (_promptMode == _SunoPromptMode.brandProfile &&
                              hasBrandProfile) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Using brand CAMS profile',
                                    style: GoogleFonts.inter(
                                      color: textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Template: ${brandProfile.fuzzyProfileTemplate?.trim().isNotEmpty == true ? brandProfile.fuzzyProfileTemplate!.trim() : '-'}'
                                    '${brandProfile.storeOverrideLevel != null ? ' | Override: ${brandProfile.storeOverrideLevel!.displayName}' : ''}',
                                    style: GoogleFonts.inter(
                                      color: textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'BPM guide: Chill ${_bpmBandLabel(brandProfile.chillBpmMin, brandProfile.chillBpmMax)}, '
                                    'Focus ${_bpmBandLabel(brandProfile.focusBpmMin, brandProfile.focusBpmMax)}, '
                                    'Energetic ${_bpmBandLabel(brandProfile.energeticBpmMin, brandProfile.energeticBpmMax)}',
                                    style: GoogleFonts.inter(
                                      color: textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<BrandProfileSunoMood>(
                              initialValue: _selectedProfileMood,
                              isExpanded: true,
                              decoration: _editorDecoration(
                                label: 'Primary music zone',
                                isDark: isDark,
                              ),
                              items: BrandProfileSunoMood.values
                                  .map(
                                    (mood) =>
                                        DropdownMenuItem<BrandProfileSunoMood>(
                                      value: mood,
                                      child: _dropdownItemLabel(mood.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _selectedProfileMood = value);
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _titleController,
                              decoration: _editorDecoration(
                                label: 'Track title',
                                isDark: isDark,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _genreController,
                              decoration: _editorDecoration(
                                label: 'Genre',
                                isDark: isDark,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _artistController,
                              decoration: _editorDecoration(
                                label: 'Artist / style hint',
                                isDark: isDark,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String?>(
                              initialValue: sortedMoods
                                      .any((mood) => mood.id == _selectedMoodId)
                                  ? _selectedMoodId
                                  : null,
                              isExpanded: true,
                              decoration: _editorDecoration(
                                label: 'Catalog mood (optional)',
                                isDark: isDark,
                              ),
                              items: [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: _dropdownItemLabel(
                                    'No mood preference',
                                  ),
                                ),
                                ...sortedMoods.map(
                                  (mood) => DropdownMenuItem<String?>(
                                    value: mood.id,
                                    child: _dropdownItemLabel(mood.name),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedMoodId = value);
                              },
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Generated prompt preview',
                                          style: GoogleFonts.inter(
                                            color: textPrimary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${generatedPrompt.length}/4000',
                                        style: GoogleFonts.inter(
                                          color: textMuted,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  SelectableText(
                                    generatedPrompt.isNotEmpty
                                        ? generatedPrompt
                                        : 'Adjust the profile fields to generate a prompt preview.',
                                    style: GoogleFonts.inter(
                                      color: generatedPrompt.isNotEmpty
                                          ? textPrimary
                                          : textMuted,
                                      fontSize: 12,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            TextFormField(
                              controller: _titleController,
                              decoration: _editorDecoration(
                                label: 'Title (optional)',
                                isDark: isDark,
                              ),
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
                            DropdownButtonFormField<String?>(
                              initialValue: sortedMoods
                                      .any((mood) => mood.id == _selectedMoodId)
                                  ? _selectedMoodId
                                  : null,
                              isExpanded: true,
                              decoration: _editorDecoration(
                                label: 'Mood',
                                isDark: isDark,
                              ),
                              items: [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: _dropdownItemLabel(
                                    'No mood preference',
                                  ),
                                ),
                                ...sortedMoods.map(
                                  (mood) => DropdownMenuItem<String?>(
                                    value: mood.id,
                                    child: _dropdownItemLabel(mood.name),
                                  ),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() => _selectedMoodId = value);
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _promptController,
                              maxLines: 4,
                              maxLength: 4000,
                              decoration: _editorDecoration(
                                label: _hasConfiguredPromptTemplate
                                    ? 'Prompt override'
                                    : 'Prompt *',
                                isDark: isDark,
                              ).copyWith(
                                hintText: _hasConfiguredPromptTemplate
                                    ? 'Leave blank to use the brand default prompt template.'
                                    : 'Describe the music you want to generate...',
                                alignLabelWithHint: true,
                              ),
                              validator: (value) {
                                if (!_hasConfiguredPromptTemplate &&
                                    (value?.trim().isEmpty ?? true)) {
                                  return 'Prompt is required when no brand default prompt is configured.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _hasConfiguredPromptTemplate
                                  ? 'Manual mode can stay blank and the backend will resolve the default brand prompt template.'
                                  : 'Enter a prompt because this brand does not have a default Suno prompt yet.',
                              style: GoogleFonts.inter(
                                color: textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String?>(
                            initialValue: widget.playlists.any((playlist) =>
                                    playlist.id == _selectedPlaylistId)
                                ? _selectedPlaylistId
                                : null,
                            isExpanded: true,
                            decoration: _editorDecoration(
                              label: 'Target playlist',
                              isDark: isDark,
                            ),
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: _dropdownItemLabel(
                                  'No target playlist',
                                ),
                              ),
                              ...widget.playlists.map(
                                (playlist) => DropdownMenuItem<String?>(
                                  value: playlist.id,
                                  child: _dropdownItemLabel(playlist.title),
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
                            value: _autoAddToTargetPlaylist &&
                                _selectedPlaylistId != null,
                            onChanged: _selectedPlaylistId == null
                                ? null
                                : (value) => setState(
                                    () => _autoAddToTargetPlaylist = value),
                            title: Text(
                              'Auto-add to selected playlist',
                              style: GoogleFonts.inter(
                                color: textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (hasAdvancedOptions) ...[
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  dividerColor: Colors.transparent,
                                ),
                                child: ExpansionTile(
                                  initiallyExpanded: _showAdvanced,
                                  onExpansionChanged: (value) {
                                    setState(() => _showAdvanced = value);
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  collapsedShape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 4,
                                  ),
                                  childrenPadding:
                                      const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                  title: Text(
                                    'Advanced',
                                    style: GoogleFonts.inter(
                                      color: textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Generation mode, fuzzy profile, and BPM guidance',
                                    style: GoogleFonts.inter(
                                      color: textMuted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  children: [
                                    if (generationModes.isNotEmpty) ...[
                                      DropdownButtonFormField<
                                          AiGenerationModeEnum?>(
                                        initialValue: generationModes.contains(
                                          _selectedGenerationMode,
                                        )
                                            ? _selectedGenerationMode
                                            : generationModes.first,
                                        isExpanded: true,
                                        decoration: _editorDecoration(
                                          label: 'Generation mode',
                                          isDark: isDark,
                                        ),
                                        items: generationModes
                                            .map(
                                              (mode) => DropdownMenuItem<
                                                  AiGenerationModeEnum?>(
                                                value: mode,
                                                child: _dropdownItemLabel(
                                                  mode.displayName,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() =>
                                              _selectedGenerationMode = value);
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (fuzzyTemplates.isNotEmpty) ...[
                                      DropdownButtonFormField<String?>(
                                        initialValue: fuzzyTemplates.contains(
                                          _selectedFuzzyTemplate,
                                        )
                                            ? _selectedFuzzyTemplate
                                            : fuzzyTemplates.first,
                                        isExpanded: true,
                                        decoration: _editorDecoration(
                                          label: 'Fuzzy profile template',
                                          isDark: isDark,
                                        ),
                                        items: fuzzyTemplates
                                            .map(
                                              (template) =>
                                                  DropdownMenuItem<String?>(
                                                value: template,
                                                child: _dropdownItemLabel(
                                                  template,
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (value) {
                                          setState(() =>
                                              _selectedFuzzyTemplate = value);
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: _bpmMinController,
                                            keyboardType: TextInputType.number,
                                            decoration: _editorDecoration(
                                              label: 'BPM min',
                                              isDark: isDark,
                                            ),
                                            validator: _validateIntegerField,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: TextFormField(
                                            controller: _bpmMaxController,
                                            keyboardType: TextInputType.number,
                                            decoration: _editorDecoration(
                                              label: 'BPM max',
                                              isDark: isDark,
                                            ),
                                            validator: _validateIntegerField,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                      controller: _bpmTargetController,
                                      keyboardType: TextInputType.number,
                                      decoration: _editorDecoration(
                                        label: 'Target BPM',
                                        isDark: isDark,
                                      ),
                                      validator: _validateIntegerField,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Only the fields your backend config exposes are shown here. Leave anything blank to keep the default resolver behavior.',
                                      style: GoogleFonts.inter(
                                        color: textMuted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: canSubmit
                                  ? () {
                                      final isValid =
                                          _formKey.currentState?.validate() ??
                                              false;
                                      if (!isValid) return;
                                      final prompt = _promptMode ==
                                              _SunoPromptMode.brandProfile
                                          ? _nullable(generatedPrompt)
                                          : _nullable(_promptController.text);
                                      if (_promptMode ==
                                              _SunoPromptMode.brandProfile &&
                                          prompt == null) {
                                        return;
                                      }
                                      Navigator.pop(
                                        context,
                                        CreateSunoGenerationRequest(
                                          prompt: prompt,
                                          title:
                                              _nullable(_titleController.text),
                                          artist:
                                              _nullable(_artistController.text),
                                          moodId: _selectedMoodId,
                                          targetPlaylistId: _selectedPlaylistId,
                                          autoAddToTargetPlaylist:
                                              _autoAddToTargetPlaylist,
                                          aiGenerationMode:
                                              _selectedGenerationMode,
                                          fuzzyProfileTemplate: _nullable(
                                              _selectedFuzzyTemplate ?? ''),
                                          recommendedBpmMin: _nullableInt(
                                              _bpmMinController.text),
                                          recommendedBpmMax: _nullableInt(
                                              _bpmMaxController.text),
                                          recommendedBpmTarget: _nullableInt(
                                              _bpmTargetController.text),
                                        ),
                                      );
                                    }
                                  : null,
                              icon: const Icon(Icons.auto_awesome_rounded,
                                  size: 18),
                              label: const Text('Generate music'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<AiGenerationModeEnum> get _generationModeOptions {
    final modes = <AiGenerationModeEnum>[];
    final configuredMode = widget.initialConfig?.aiGenerationMode;
    if (configuredMode != null &&
        configuredMode != AiGenerationModeEnum.unknown) {
      modes.add(configuredMode);
    }
    for (final mode in widget.initialConfig?.availableGenerationModes ??
        const <AiGenerationModeEnum>[]) {
      if (mode != AiGenerationModeEnum.unknown && !modes.contains(mode)) {
        modes.add(mode);
      }
    }
    return modes;
  }

  List<String> get _fuzzyTemplateOptions {
    final templates = <String>[];
    final configuredTemplate =
        widget.initialConfig?.fuzzyProfileTemplate?.trim();
    final profileTemplate = _brandProfile?.fuzzyProfileTemplate?.trim();
    if (profileTemplate != null &&
        profileTemplate.isNotEmpty &&
        !templates.contains(profileTemplate)) {
      templates.add(profileTemplate);
    }
    if (configuredTemplate != null &&
        configuredTemplate.isNotEmpty &&
        !templates.contains(configuredTemplate)) {
      templates.add(configuredTemplate);
    }
    for (final template
        in widget.initialConfig?.availableFuzzyProfileTemplates ??
            const <String>[]) {
      final trimmed = template.trim();
      if (trimmed.isEmpty || templates.contains(trimmed)) {
        continue;
      }
      templates.add(trimmed);
    }
    return templates;
  }

  String? _validateIntegerField(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed) == null ? 'Enter a whole number.' : null;
  }

  int? _nullableInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  String _bpmBandLabel(int? min, int? max) {
    if (min != null && max != null) {
      return '$min-$max BPM';
    }
    if (min != null) {
      return '$min+ BPM';
    }
    if (max != null) {
      return 'Up to $max BPM';
    }
    return '-';
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
  AiGenerationModeEnum? _selectedGenerationMode;

  void _closeSheet() {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _promptTemplateController.text =
        widget.currentConfig?.sunoPromptTemplate ?? '';
    _selectedPlaylistId = widget.currentConfig?.sunoDefaultPlaylistId;
    _selectedGenerationMode = widget.currentConfig?.aiGenerationMode;
    if (_selectedGenerationMode == AiGenerationModeEnum.unknown) {
      _selectedGenerationMode = null;
    }
    if (_selectedGenerationMode == null && _generationModeOptions.isNotEmpty) {
      _selectedGenerationMode = _generationModeOptions.first;
    }
  }

  @override
  void dispose() {
    _promptTemplateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final maxSheetHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.viewInsets.top -
        24;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.white60 : Colors.black54;
    final generationModes = _generationModeOptions;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: mediaQuery.viewInsets.bottom + 16,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxSheetHeight),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
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
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Suno Config',
                                    style: GoogleFonts.poppins(
                                      color: textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Configure the default prompt template, generation mode, and playlist for Suno jobs.',
                                    style: GoogleFonts.inter(
                                      color: textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: _closeSheet,
                              icon: Icon(
                                Icons.close_rounded,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prompt template variables',
                                style: GoogleFonts.inter(
                                  color: textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '{mood}, {genre}, {title}, {artist}',
                                style: GoogleFonts.inter(
                                  color: textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Profile mode also fills {fuzzyTemplate}, {bpmBand}, {chillBpm}, {focusBpm}, {energeticBpm}, {pressureLowMax}, {pressureCriticalMin}, {stressComfortableMax}, {stressHighMin}, {densitySparseMax}, {densityCrowdedMin}, {spaceCapacity}.',
                                style: GoogleFonts.inter(
                                  color: textMuted,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (generationModes.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<AiGenerationModeEnum?>(
                            initialValue: generationModes.contains(
                              _selectedGenerationMode,
                            )
                                ? _selectedGenerationMode
                                : generationModes.first,
                            isExpanded: true,
                            decoration: _editorDecoration(
                              label: 'Generation mode',
                              isDark: isDark,
                            ),
                            items: generationModes
                                .map(
                                  (mode) =>
                                      DropdownMenuItem<AiGenerationModeEnum?>(
                                    value: mode,
                                    child: _dropdownItemLabel(
                                      mode.displayName,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedGenerationMode = value);
                            },
                          ),
                        ],
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
                          initialValue: widget.playlists.any((playlist) =>
                                  playlist.id == _selectedPlaylistId)
                              ? _selectedPlaylistId
                              : null,
                          isExpanded: true,
                          decoration: _editorDecoration(
                            label: 'Default playlist',
                            isDark: isDark,
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: _dropdownItemLabel(
                                'No default playlist',
                              ),
                            ),
                            ...widget.playlists.map(
                              (playlist) => DropdownMenuItem<String?>(
                                value: playlist.id,
                                child: _dropdownItemLabel(playlist.title),
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
                                aiGenerationMode: _selectedGenerationMode,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<AiGenerationModeEnum> get _generationModeOptions {
    final modes = <AiGenerationModeEnum>[];
    final configured = widget.currentConfig?.aiGenerationMode;
    if (configured != null && configured != AiGenerationModeEnum.unknown) {
      modes.add(configured);
    }
    for (final mode in widget.currentConfig?.availableGenerationModes ??
        const <AiGenerationModeEnum>[]) {
      if (mode == AiGenerationModeEnum.unknown || modes.contains(mode)) {
        continue;
      }
      modes.add(mode);
    }
    if (modes.isEmpty) {
      modes.addAll(const [
        AiGenerationModeEnum.suno,
        AiGenerationModeEnum.brandModel,
      ]);
    }
    return modes;
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

Widget _dropdownItemLabel(String text) {
  return Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

String? _nullable(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

class _CreatePlaylistDraft {
  const _CreatePlaylistDraft({
    required this.name,
    this.description,
    this.moodId,
    required this.isDefault,
    required this.isBrandWide,
    required this.trackIds,
  });

  final String name;
  final String? description;
  final String? moodId;
  final bool isDefault;
  final bool isBrandWide;
  final List<String> trackIds;
}

class _CreatePlaylistBottomSheet extends StatefulWidget {
  const _CreatePlaylistBottomSheet({
    required this.moods,
    required this.tracks,
    this.storeName,
    this.canCreateBrandWide = false,
  });

  final List<Mood> moods;
  final List<ApiTrack> tracks;
  final String? storeName;
  final bool canCreateBrandWide;

  @override
  State<_CreatePlaylistBottomSheet> createState() =>
      _CreatePlaylistBottomSheetState();
}

class _CreatePlaylistBottomSheetState
    extends State<_CreatePlaylistBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _trackSearchController;
  final Set<String> _selectedTrackIds = <String>{};
  String? _selectedMoodId;
  bool _isDefault = false;
  bool _isBrandWide = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _trackSearchController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _trackSearchController.dispose();
    super.dispose();
  }

  List<Mood> get _sortedMoods {
    final moods = [...widget.moods];
    moods.sort(
      (left, right) => left.name.toLowerCase().compareTo(
            right.name.toLowerCase(),
          ),
    );
    return moods;
  }

  List<ApiTrack> get _filteredTracks {
    final tracks = [...widget.tracks];
    tracks.sort(
      (left, right) => left.title.toLowerCase().compareTo(
            right.title.toLowerCase(),
          ),
    );

    final query = _trackSearchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return tracks;
    }

    return tracks.where((track) {
      final artist = track.artist?.trim() ?? '';
      final mood = track.moodName?.trim() ?? '';
      final haystack = '${track.title} $artist $mood'.toLowerCase();
      return haystack.contains(query);
    }).toList(growable: false);
  }

  void _toggleTrackSelection(String trackId, bool shouldSelect) {
    setState(() {
      if (shouldSelect) {
        _selectedTrackIds.add(trackId);
      } else {
        _selectedTrackIds.remove(trackId);
      }
    });
  }

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    Navigator.of(context).pop(
      _CreatePlaylistDraft(
        name: _nameController.text.trim(),
        description: _nullable(_descriptionController.text),
        moodId: _selectedMoodId,
        isDefault: _isDefault,
        isBrandWide: _isBrandWide,
        trackIds: _selectedTrackIds.toList(growable: false),
      ),
    );
  }

  String _trackSubtitle(ApiTrack track) {
    final parts = <String>[
      if (track.artist?.trim().isNotEmpty ?? false) track.artist!.trim(),
      if (track.moodName?.trim().isNotEmpty ?? false) track.moodName!.trim(),
      track.formattedDuration,
    ];
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final palette = _Palette.fromBrightness(Theme.of(context).brightness);
    final isDark = palette.isDark;
    final filteredTracks = _filteredTracks;
    final selectedTrackCount = _selectedTrackIds.length;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: screenHeight * 0.88,
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: palette.shadow.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: palette.textMuted.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Playlist',
                              style: GoogleFonts.poppins(
                                color: palette.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.storeName?.trim().isNotEmpty == true
                                  ? 'Create this for ${widget.storeName}, or share it across the brand if available. Add mood, description, default status, or starter tracks now.'
                                  : 'Add mood, description, default status, or a few starter tracks now.',
                              style: GoogleFonts.inter(
                                color: palette.textMuted,
                                fontSize: 12.5,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: palette.border.withValues(alpha: 0.85),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: palette.overlay,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: palette.border.withValues(alpha: 0.8),
                              ),
                            ),
                            child: Text(
                              'Playlist name is required. Brand managers can leave store scope to create a brand-wide playlist shared across stores.',
                              style: GoogleFonts.inter(
                                color: palette.textMuted,
                                fontSize: 12,
                                height: 1.45,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            autofocus: true,
                            maxLength: 255,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.inter(
                              color: palette.textPrimary,
                            ),
                            decoration: _editorDecoration(
                              label: 'Playlist name *',
                              isDark: isDark,
                            ).copyWith(
                              hintText: 'Morning store opening mix',
                              hintStyle: GoogleFonts.inter(
                                color:
                                    palette.textMuted.withValues(alpha: 0.55),
                                fontSize: 13,
                              ),
                              counterStyle: GoogleFonts.inter(
                                color:
                                    palette.textMuted.withValues(alpha: 0.75),
                                fontSize: 11,
                              ),
                            ),
                            validator: (value) {
                              final trimmed = value?.trim() ?? '';
                              if (trimmed.isEmpty) {
                                return 'Playlist name is required.';
                              }
                              if (trimmed.length > 255) {
                                return 'Playlist name must be 255 characters or fewer.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _descriptionController,
                            maxLength: 2000,
                            minLines: 3,
                            maxLines: 5,
                            style: GoogleFonts.inter(
                              color: palette.textPrimary,
                            ),
                            decoration: _editorDecoration(
                              label: 'Description',
                              isDark: isDark,
                            ).copyWith(
                              hintText:
                                  'Short note for the team or the intended vibe.',
                              hintStyle: GoogleFonts.inter(
                                color:
                                    palette.textMuted.withValues(alpha: 0.55),
                                fontSize: 13,
                              ),
                              counterStyle: GoogleFonts.inter(
                                color:
                                    palette.textMuted.withValues(alpha: 0.75),
                                fontSize: 11,
                              ),
                              alignLabelWithHint: true,
                            ),
                            validator: (value) {
                              final trimmedLength = value?.trim().length ?? 0;
                              if (trimmedLength > 2000) {
                                return 'Description must be 2000 characters or fewer.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String?>(
                            initialValue: _selectedMoodId,
                            isExpanded: true,
                            decoration: _editorDecoration(
                              label: 'Mood',
                              isDark: isDark,
                            ),
                            style: GoogleFonts.inter(
                              color: palette.textPrimary,
                              fontSize: 14,
                            ),
                            dropdownColor: palette.card,
                            items: [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: _dropdownItemLabel(
                                  'No mood assigned',
                                ),
                              ),
                              ..._sortedMoods.map(
                                (mood) => DropdownMenuItem<String?>(
                                  value: mood.id,
                                  child: _dropdownItemLabel(mood.name),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedMoodId = value);
                            },
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile.adaptive(
                            value: _isDefault,
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: palette.accent,
                            activeTrackColor:
                                palette.accent.withValues(alpha: 0.32),
                            title: Text(
                              'Set as store default playlist',
                              style: GoogleFonts.inter(
                                color: palette.textPrimary,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Use this when the store should fall back to this playlist by default.',
                              style: GoogleFonts.inter(
                                color: palette.textMuted,
                                fontSize: 11.5,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() => _isDefault = value);
                            },
                          ),
                          if (widget.canCreateBrandWide) ...[
                            const SizedBox(height: 4),
                            SwitchListTile.adaptive(
                              value: _isBrandWide,
                              contentPadding: EdgeInsets.zero,
                              activeThumbColor: palette.accent,
                              activeTrackColor:
                                  palette.accent.withValues(alpha: 0.32),
                              title: Text(
                                'Create as brand-wide playlist',
                                style: GoogleFonts.inter(
                                  color: palette.textPrimary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                'Shared playlist with no storeId; Brand Managers can manage it across the brand.',
                                style: GoogleFonts.inter(
                                  color: palette.textMuted,
                                  fontSize: 11.5,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() => _isBrandWide = value);
                              },
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: palette.overlay,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: palette.border.withValues(alpha: 0.8),
                              ),
                            ),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: Colors.transparent,
                              ),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 2,
                                ),
                                childrenPadding:
                                    const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                collapsedShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Text(
                                  'Initial tracks',
                                  style: GoogleFonts.inter(
                                    color: palette.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  selectedTrackCount == 0
                                      ? 'Optional. Start empty and add tracks later.'
                                      : '$selectedTrackCount track${selectedTrackCount == 1 ? '' : 's'} selected for creation.',
                                  style: GoogleFonts.inter(
                                    color: palette.textMuted,
                                    fontSize: 11.5,
                                  ),
                                ),
                                children: [
                                  if (widget.tracks.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(
                                        'No tracks are loaded in the library yet. You can still create the playlist now.',
                                        style: GoogleFonts.inter(
                                          color: palette.textMuted,
                                          fontSize: 12,
                                          height: 1.45,
                                        ),
                                      ),
                                    )
                                  else ...[
                                    TextField(
                                      controller: _trackSearchController,
                                      onChanged: (_) => setState(() {}),
                                      style: GoogleFonts.inter(
                                        color: palette.textPrimary,
                                      ),
                                      decoration: _editorDecoration(
                                        label: 'Search tracks',
                                        isDark: isDark,
                                      ).copyWith(
                                        prefixIcon: Icon(
                                          Icons.search_rounded,
                                          color: palette.textMuted,
                                        ),
                                        suffixIcon:
                                            _trackSearchController.text.isEmpty
                                                ? null
                                                : IconButton(
                                                    tooltip: 'Clear',
                                                    onPressed: () {
                                                      _trackSearchController
                                                          .clear();
                                                      setState(() {});
                                                    },
                                                    icon: Icon(
                                                      Icons.close_rounded,
                                                      color: palette.textMuted,
                                                    ),
                                                  ),
                                      ),
                                    ),
                                    if (selectedTrackCount > 0) ...[
                                      const SizedBox(height: 8),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          onPressed: () {
                                            setState(
                                              () => _selectedTrackIds.clear(),
                                            );
                                          },
                                          child: const Text('Clear selection'),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      height: 240,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: palette.card,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: palette.border,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          child: filteredTracks.isEmpty
                                              ? Center(
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 20,
                                                    ),
                                                    child: Text(
                                                      'No tracks match your search.',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: GoogleFonts.inter(
                                                        color:
                                                            palette.textMuted,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : ListView.separated(
                                                  itemCount:
                                                      filteredTracks.length,
                                                  separatorBuilder: (_, __) =>
                                                      Divider(
                                                    height: 1,
                                                    color: palette.border
                                                        .withValues(
                                                      alpha: 0.7,
                                                    ),
                                                  ),
                                                  itemBuilder:
                                                      (context, index) {
                                                    final track =
                                                        filteredTracks[index];
                                                    final isSelected =
                                                        _selectedTrackIds
                                                            .contains(track.id);

                                                    return CheckboxListTile
                                                        .adaptive(
                                                      value: isSelected,
                                                      controlAffinity:
                                                          ListTileControlAffinity
                                                              .leading,
                                                      activeColor:
                                                          palette.accent,
                                                      checkboxShape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      title: Text(
                                                        track.title,
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style:
                                                            GoogleFonts.inter(
                                                          color: palette
                                                              .textPrimary,
                                                          fontSize: 13,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      subtitle: Text(
                                                        _trackSubtitle(track),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style:
                                                            GoogleFonts.inter(
                                                          color:
                                                              palette.textMuted,
                                                          fontSize: 11.5,
                                                        ),
                                                      ),
                                                      contentPadding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                        horizontal: 10,
                                                      ),
                                                      onChanged: (value) {
                                                        _toggleTrackSelection(
                                                          track.id,
                                                          value ?? false,
                                                        );
                                                      },
                                                    );
                                                  },
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  color: palette.border.withValues(alpha: 0.85),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: palette.textMuted,
                            side: BorderSide(color: palette.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: palette.accent,
                            foregroundColor: palette.textOnAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Create Playlist',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
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
