import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/enums/entity_status_enum.dart';
import 'package:cams_store_manager/core/error/failures.dart';
import 'package:cams_store_manager/core/services/local_storage_service.dart';
import 'package:cams_store_manager/core/session/session_cubit.dart';
import 'package:cams_store_manager/features/moods/domain/entities/mood.dart';
import 'package:cams_store_manager/features/now_playing/presentation/widgets/queue_management_sheets.dart';
import 'package:cams_store_manager/features/playlists/data/datasources/playlist_remote_datasource.dart';
import 'package:cams_store_manager/features/playlists/data/models/api_playlist_model.dart';
import 'package:cams_store_manager/features/playlists/data/repositories/playlist_repository_impl.dart';
import 'package:cams_store_manager/features/playlists/domain/entities/api_playlist.dart';
import 'package:cams_store_manager/features/store_dashboard/domain/entities/store.dart';
import 'package:cams_store_manager/features/tracks/data/datasources/track_remote_datasource.dart';
import 'package:cams_store_manager/features/tracks/data/models/api_track_model.dart';
import 'package:cams_store_manager/features/tracks/data/repositories/track_repository_impl.dart';
import 'package:cams_store_manager/features/tracks/domain/entities/api_track.dart';
import 'package:cams_store_manager/features/tracks/domain/entities/track_filter.dart';
import 'package:cams_store_manager/features/tracks/domain/usecases/track_usecases.dart';
import 'package:cams_store_manager/injection_container.dart';

void main() {
  setUp(() async {
    await sl.reset();
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets(
    'add-to-queue sheet keeps clear-current disabled for add-to-queue and enables it for play-now',
    (tester) async {
      sl.registerSingleton<GetTracks>(
        GetTracks(_FakeTrackRepository(_sampleTracks)),
      );
      sl.registerSingleton<PlaylistRepository>(
        _FakePlaylistRepository(_samplePlaylists),
      );

      final sessionCubit = SessionCubit(
        localStorage: _InMemoryLocalStorageService(),
      );
      sessionCubit.changeStore(
        const Store(
          id: 'store-1',
          name: 'Store 1',
          brandId: 'brand-1',
        ),
      );
      addTearDown(sessionCubit.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<SessionCubit>.value(
            value: sessionCubit,
            child: const Scaffold(
              body: NowPlayingAddToQueueSheet(
                initialTrackId: 'track-1',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Disabled for Add to queue.'), findsOneWidget);
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Track Alpha'),
            )
            .value,
        isTrue,
      );

      await tester.tap(find.text('Track Beta'));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Track Alpha'),
            )
            .value,
        isTrue,
      );
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, 'Track Beta'),
            )
            .value,
        isTrue,
      );

      await tester.tap(find.text('Play now'));
      await tester.pumpAndSettle();

      expect(
        find.text('Use this for play-now or play-next replacement flows.'),
        findsOneWidget,
      );

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Play now'),
      );
      expect(button.onPressed, isNotNull);
    },
  );

  testWidgets(
    'override sheet allows optional source selection and hides inactive moods',
    (tester) async {
      sl.registerSingleton<GetTracks>(
        GetTracks(_FakeTrackRepository(_sampleTracks)),
      );
      sl.registerSingleton<PlaylistRepository>(
        _FakePlaylistRepository(_samplePlaylists),
      );

      final sessionCubit = SessionCubit(
        localStorage: _InMemoryLocalStorageService(),
      );
      sessionCubit.changeStore(
        const Store(
          id: 'store-1',
          name: 'Store 1',
          brandId: 'brand-1',
        ),
      );
      addTearDown(sessionCubit.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<SessionCubit>.value(
            value: sessionCubit,
            child: Scaffold(
              body: NowPlayingOverrideMusicSheet(
                moods: [
                  Mood(
                    id: 'mood-active',
                    name: 'Energetic',
                    createdAt: DateTime.utc(2025, 1, 1),
                  ),
                  Mood(
                    id: 'mood-inactive',
                    name: 'Archived',
                    status: EntityStatusEnum.inactive,
                    createdAt: DateTime.utc(2025, 1, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      ElevatedButton button() => tester.widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Apply override'),
          );

      expect(button().onPressed, isNotNull);

      await tester.tap(find.text('Track Alpha'));
      await tester.pumpAndSettle();
      expect(button().onPressed, isNotNull);

      await tester.tap(find.text('Playlist'));
      await tester.pumpAndSettle();
      expect(button().onPressed, isNotNull);

      await tester.tap(find.text('Mood'));
      await tester.pumpAndSettle();

      expect(find.text('ARCHIVED'), findsNothing);
      expect(find.text('ENERGETIC'), findsOneWidget);
      expect(button().onPressed, isNotNull);

      await tester.tap(find.text('ENERGETIC'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Override TTL seconds *'),
        '1800',
      );
      await tester.pumpAndSettle();
      expect(button().onPressed, isNotNull);
    },
  );

  testWidgets(
    'add-to-queue modal closes from the Close action',
    (tester) async {
      sl.registerSingleton<GetTracks>(
        GetTracks(_FakeTrackRepository(_sampleTracks)),
      );
      sl.registerSingleton<PlaylistRepository>(
        _FakePlaylistRepository(_samplePlaylists),
      );

      final sessionCubit = SessionCubit(
        localStorage: _InMemoryLocalStorageService(),
      );
      sessionCubit.changeStore(
        const Store(
          id: 'store-1',
          name: 'Store 1',
          brandId: 'brand-1',
        ),
      );
      addTearDown(sessionCubit.close);

      await tester.pumpWidget(
        BlocProvider<SessionCubit>.value(
          value: sessionCubit,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet<void>(
                          context: context,
                          useRootNavigator: true,
                          isScrollControlled: true,
                          builder: (_) => const FractionallySizedBox(
                            heightFactor: 0.88,
                            child: NowPlayingAddToQueueSheet(
                              initialTrackId: 'track-1',
                            ),
                          ),
                        );
                      },
                      child: const Text('Open'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(NowPlayingAddToQueueSheet), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.byType(NowPlayingAddToQueueSheet), findsNothing);
    },
  );

  testWidgets(
    'add-to-queue sheet loads tracks in pages of 10 while scrolling',
    (tester) async {
      final trackRepository = _FakeTrackRepository(_manyTracks(12));
      sl.registerSingleton<GetTracks>(GetTracks(trackRepository));
      sl.registerSingleton<PlaylistRepository>(
        _FakePlaylistRepository(_samplePlaylists),
      );

      final sessionCubit = SessionCubit(
        localStorage: _InMemoryLocalStorageService(),
      );
      sessionCubit.changeStore(
        const Store(
          id: 'store-1',
          name: 'Store 1',
          brandId: 'brand-1',
        ),
      );
      addTearDown(sessionCubit.close);

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<SessionCubit>.value(
            value: sessionCubit,
            child: const Scaffold(
              body: NowPlayingAddToQueueSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(trackRepository.requestedFilters.single.page, 1);
      expect(trackRepository.requestedFilters.single.pageSize, 10);

      await tester.drag(find.byType(ListView).first, const Offset(0, -700));
      await tester.pumpAndSettle();

      expect(trackRepository.requestedFilters.length, 2);
      expect(trackRepository.requestedFilters.last.page, 2);
      expect(trackRepository.requestedFilters.last.pageSize, 10);
    },
  );
}

class _InMemoryLocalStorageService extends LocalStorageService {
  final Map<String, dynamic> _settings = <String, dynamic>{};

  @override
  dynamic getSetting(String key) => _settings[key];

  @override
  Future<void> saveSetting(String key, dynamic value) async {
    _settings[key] = value;
  }

  @override
  Future<void> removeSetting(String key) async {
    _settings.remove(key);
  }
}

class _FakeTrackRepository implements TrackRepository {
  _FakeTrackRepository(this.tracks);

  final List<ApiTrackModel> tracks;
  final List<TrackFilter> requestedFilters = <TrackFilter>[];

  @override
  Future<Either<Failure, TrackListResponse>> getTracks({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? moodId,
    String? genre,
    TrackFilter? filter,
  }) async {
    final resolvedPage = filter?.page ?? page;
    final resolvedPageSize = filter?.pageSize ?? pageSize;
    if (filter != null) {
      requestedFilters.add(filter);
    }
    final start = (resolvedPage - 1) * resolvedPageSize;
    final end = (start + resolvedPageSize).clamp(0, tracks.length).toInt();
    final pageItems = start >= tracks.length
        ? const <ApiTrackModel>[]
        : tracks.sublist(start, end);

    return Right(
      TrackListResponse(
        items: pageItems,
        currentPage: resolvedPage,
        totalPages: (tracks.length / resolvedPageSize).ceil().clamp(1, 999),
        totalItems: tracks.length,
        hasNext: end < tracks.length,
        hasPrevious: resolvedPage > 1,
      ),
    );
  }

  @override
  Future<Either<Failure, ApiTrack>> getTrackById(String trackId) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, TrackMutationResult>> createTrack(
    CreateTrackRequest request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, TrackMutationResult>> updateTrack(
    String trackId,
    UpdateTrackRequest request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, TrackMutationResult>> deleteTrack(String trackId) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, TrackMutationResult>> toggleTrackStatus(
    String trackId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, TrackMutationResult>> retranscodeTrack(
    String trackId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, TrackMutationResult>> setTrackCopyrightClearance(
    String trackId, {
    required bool approve,
  }) {
    throw UnimplementedError();
  }
}

class _FakePlaylistRepository implements PlaylistRepository {
  _FakePlaylistRepository(this.playlists);

  final List<ApiPlaylistModel> playlists;

  @override
  Future<Either<Failure, PlaylistListResponse>> getPlaylists({
    int page = 1,
    int pageSize = 10,
    String? search,
    String? sortBy,
    bool? isAscending,
    int? status,
    String? brandId,
    String? storeId,
    String? moodId,
    bool? isDefault,
    DateTime? createdFrom,
    DateTime? createdTo,
  }) async {
    return Right(
      PlaylistListResponse(
        items: playlists,
        currentPage: page,
        totalPages: 1,
        totalItems: playlists.length,
        hasNext: false,
        hasPrevious: false,
      ),
    );
  }

  @override
  Future<Either<Failure, ApiPlaylist>> getPlaylistById(String playlistId) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, PlaylistMutationResult>> createPlaylist(
    PlaylistMutationRequest request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, PlaylistMutationResult>> updatePlaylist(
    String playlistId,
    PlaylistMutationRequest request,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, PlaylistMutationResult>> deletePlaylist(
    String playlistId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, PlaylistMutationResult>> togglePlaylistStatus(
    String playlistId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, PlaylistMutationResult>> addTracksToPlaylist({
    required String playlistId,
    required List<String> trackIds,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, PlaylistMutationResult>> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) {
    throw UnimplementedError();
  }
}

final List<ApiTrackModel> _sampleTracks = [
  ApiTrackModel(
    id: 'track-1',
    title: 'Track Alpha',
    artist: 'Artist One',
    createdAt: DateTime.utc(2025, 1, 1),
  ),
  ApiTrackModel(
    id: 'track-2',
    title: 'Track Beta',
    artist: 'Artist Two',
    createdAt: DateTime.utc(2025, 1, 2),
  ),
];

List<ApiTrackModel> _manyTracks(int count) {
  return List<ApiTrackModel>.generate(
    count,
    (index) {
      final number = index + 1;
      return ApiTrackModel(
        id: 'track-$number',
        title: 'Track ${number.toString().padLeft(2, '0')}',
        artist: 'Artist $number',
        createdAt: DateTime.utc(2025, 1, number),
      );
    },
  );
}

final List<ApiPlaylistModel> _samplePlaylists = [
  ApiPlaylistModel(
    id: 'playlist-1',
    name: 'Morning Flow',
    trackCount: 8,
    createdAt: DateTime.utc(2025, 1, 1),
  ),
];
