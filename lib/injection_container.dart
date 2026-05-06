import 'package:get_it/get_it.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'core/network/dio_client.dart';
import 'core/network/network_info.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/session_data_cache.dart';
import 'core/session/session_cubit.dart';

// Auth Feature
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/datasources/auth_mock_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login.dart';
import 'features/auth/domain/usecases/logout.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/change_password.dart';
import 'features/auth/domain/usecases/request_forgot_password_otp.dart';
import 'features/auth/domain/usecases/reset_forgot_password.dart';
import 'features/auth/domain/usecases/verify_forgot_password_otp.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'core/constants/api_constants.dart';

// Device Pairing Feature
import 'features/device_pairing/data/datasources/device_pairing_remote_datasource.dart';
import 'features/device_pairing/data/datasources/device_pairing_mock_datasource.dart';
import 'features/device_pairing/data/datasources/device_pairing_remote_datasource_impl.dart';
import 'features/device_pairing/data/repositories/device_pairing_repository_impl.dart';
import 'features/device_pairing/domain/repositories/device_pairing_repository.dart';
import 'features/device_pairing/domain/usecases/pair_device.dart';
import 'features/device_pairing/presentation/bloc/device_pairing_bloc.dart';

// Hub Management Feature
import 'features/hub_management/data/datasources/space_hub_remote_datasource.dart';
import 'features/hub_management/data/datasources/space_hub_stub_datasource.dart';
import 'features/hub_management/data/repositories/space_hub_repository_impl.dart';
import 'features/hub_management/data/services/ble_permission_service.dart';
import 'features/hub_management/data/services/ble_provisioning_service.dart';
import 'features/hub_management/data/services/location_capture_service.dart';
import 'features/hub_management/data/services/provisioning_identity_resolver.dart';
import 'features/hub_management/domain/repositories/space_hub_repository.dart';
import 'features/hub_management/domain/usecases/space_hub_usecases.dart';
import 'features/hub_management/presentation/bloc/hub_provisioning_bloc.dart';

// Location Feature
import 'features/locations/data/datasources/location_remote_datasource.dart';
import 'features/locations/data/datasources/location_mock_datasource.dart';
import 'features/locations/data/datasources/location_remote_datasource_impl.dart';
import 'features/locations/data/repositories/location_repository_impl.dart';
import 'features/locations/domain/repositories/location_repository.dart';
import 'features/locations/domain/usecases/location_usecases.dart';
import 'features/locations/presentation/bloc/location_bloc.dart';
import 'features/space_schedule/data/datasources/space_schedule_local_datasource.dart';
import 'features/space_schedule/data/datasources/space_schedule_mock_datasource.dart';
import 'features/space_schedule/data/datasources/space_schedule_remote_datasource.dart';
import 'features/space_schedule/data/repositories/space_schedule_repository_impl.dart';
import 'features/space_schedule/domain/repositories/space_schedule_repository.dart';
import 'features/space_schedule/domain/usecases/space_schedule_usecases.dart';
import 'features/space_schedule/presentation/bloc/space_schedule_bloc.dart';

import 'features/settings/data/datasources/settings_mock_data_source.dart';
import 'features/settings/data/datasources/settings_remote_data_source.dart';
import 'features/settings/data/repositories/settings_repository_impl.dart';
import 'features/settings/domain/repositories/settings_repository.dart';
import 'features/settings/domain/usecases/get_settings_snapshot.dart';
import 'features/settings/presentation/bloc/settings_cubit.dart';

// Space Control Feature
import 'features/space_control/data/datasources/space_remote_datasource.dart';
import 'features/space_control/data/datasources/offline_playlist_datasource.dart';
import 'features/space_control/data/datasources/offline_playlist_mock_datasource.dart';
import 'features/space_control/data/datasources/offline_playlist_remote_datasource_impl.dart';
import 'features/space_control/data/repositories/space_repository_impl.dart';
import 'features/space_control/data/repositories/offline_playlist_repository_impl.dart';
import 'features/space_control/domain/repositories/space_repository.dart';
import 'features/space_control/domain/repositories/offline_playlist_repository.dart';
import 'features/space_control/domain/usecases/get_space_by_id.dart';
import 'features/space_control/domain/usecases/subscribe_to_sensor_data.dart';
import 'features/space_control/domain/usecases/subscribe_to_space_status.dart';
import 'features/space_control/presentation/bloc/space_monitoring_bloc.dart';
import 'features/space_control/presentation/bloc/offline_library_bloc.dart';

// Store Dashboard Feature
import 'features/store_dashboard/data/datasources/store_remote_datasource.dart';
import 'features/store_dashboard/data/repositories/store_repository_impl.dart';
import 'features/store_dashboard/domain/repositories/store_repository.dart';
import 'features/store_dashboard/domain/usecases/get_store_details.dart';
import 'features/store_dashboard/domain/usecases/get_space_summaries.dart';
import 'features/store_dashboard/domain/usecases/store_mutation_usecases.dart';
import 'features/store_dashboard/presentation/bloc/store_dashboard_bloc.dart';

// Store Selection Feature
import 'features/store_selection/data/datasources/store_selection_remote_datasource.dart';
import 'features/store_selection/data/repositories/store_selection_repository_impl.dart';
import 'features/store_selection/domain/repositories/store_selection_repository.dart';
import 'features/store_selection/domain/usecases/get_brand_detail.dart';
import 'features/store_selection/domain/usecases/get_user_stores.dart';
import 'features/store_selection/domain/usecases/update_brand_detail.dart';
import 'features/store_selection/presentation/bloc/store_selection_bloc.dart';

// Zone Management Feature
import 'features/zone_management/data/datasources/zone_remote_datasource.dart';
import 'features/zone_management/data/datasources/zone_remote_datasource_impl.dart';
import 'features/zone_management/data/datasources/zone_mock_datasource.dart';
import 'features/zone_management/data/repositories/zone_repository_impl.dart';
import 'features/zone_management/data/repositories/music_profile_repository_impl.dart';
import 'features/zone_management/domain/repositories/zone_repository.dart';
import 'features/zone_management/domain/repositories/music_profile_repository.dart';
import 'features/zone_management/domain/usecases/get_zones_by_space.dart';
import 'features/zone_management/domain/usecases/get_music_profile_for_zone.dart';
import 'features/zone_management/domain/usecases/update_zone_music_settings.dart';
import 'features/zone_management/domain/usecases/sync_zones_music.dart';
import 'features/zone_management/domain/usecases/assign_playlist_to_zone.dart';
import 'features/zone_management/domain/usecases/get_all_playlists.dart';

// Search Feature
import 'features/search/data/repositories/search_repository_impl.dart';
import 'features/search/domain/repositories/search_repository.dart';
import 'features/search/domain/usecases/get_categories_usecase.dart';
import 'features/search/domain/usecases/search_music_usecase.dart';
import 'features/search/domain/usecases/search_by_type_usecase.dart';
import 'features/search/domain/usecases/get_artist_detail_usecase.dart';
import 'features/search/domain/usecases/get_album_detail_usecase.dart';
import 'features/search/domain/usecases/get_playlist_detail_usecase.dart';
import 'features/search/domain/usecases/get_category_playlists_usecase.dart';
import 'features/search/domain/usecases/get_featured_playlists_usecase.dart';
import 'features/search/presentation/bloc/search_bloc.dart';
import 'features/search/presentation/bloc/artist_detail_cubit.dart';
import 'features/search/presentation/bloc/album_detail_cubit.dart';
import 'features/search/presentation/bloc/category_detail_cubit.dart';

// Moods Feature
import 'features/moods/data/datasources/mood_remote_datasource.dart';
import 'features/moods/data/repositories/mood_repository_impl.dart';

// Tracks Feature
import 'features/tracks/data/datasources/track_remote_datasource.dart';
import 'features/tracks/data/repositories/track_repository_impl.dart';
import 'features/tracks/domain/usecases/track_usecases.dart';

// Playlists Feature
import 'features/playlists/data/datasources/playlist_remote_datasource.dart';
import 'features/playlists/data/repositories/playlist_repository_impl.dart';

// Suno Feature
import 'features/suno/data/datasources/suno_remote_datasource.dart';
import 'features/suno/data/repositories/suno_repository_impl.dart';
import 'features/suno/domain/services/suno_playback_orchestrator.dart';
import 'features/suno/domain/usecases/suno_usecases.dart';
import 'features/music_policy/data/datasources/fuzzy_music_profile_remote_datasource.dart';

// Config Governance Feature
import 'features/config_governance/data/datasources/config_governance_remote_datasource.dart';
import 'features/config_governance/data/repositories/config_governance_repository_impl.dart';
import 'features/config_governance/domain/repositories/config_governance_repository.dart';
import 'features/config_governance/domain/usecases/config_governance_usecases.dart';
import 'features/config_governance/presentation/bloc/config_governance_cubit.dart';

// CAMS Feature
import 'features/cams/data/datasources/cams_remote_datasource.dart';
import 'features/cams/data/repositories/cams_repository_impl.dart';
import 'features/cams/data/services/queue_first_playback_runtime.dart';
import 'features/cams/data/services/store_hub_service.dart';
import 'features/cams/domain/usecases/get_space_state.dart';
import 'features/cams/domain/usecases/override_space.dart';
import 'features/cams/domain/usecases/cancel_override.dart';
import 'features/cams/domain/usecases/pairing_usecases.dart';
import 'features/cams/domain/services/cams_playback_capability_provider.dart';
import 'features/cams/domain/usecases/queue_usecases.dart';
import 'features/cams/domain/usecases/send_playback_command.dart';
import 'features/cams/domain/usecases/update_audio_state.dart';
import 'features/cams/domain/usecases/update_scheduling_state.dart';
import 'features/cams/presentation/bloc/cams_playback_bloc.dart';

// Moods Use Cases
import 'features/moods/domain/usecases/get_moods.dart';

// Home Feature
import 'features/home/data/datasources/home_remote_datasource.dart';
import 'features/home/data/repositories/home_repository_impl.dart';
import 'features/home/data/repositories/mock_home_repository_impl.dart';
import 'features/home/domain/repositories/home_repository.dart';
import 'features/home/presentation/bloc/home_cubit.dart';

// Mock Data Sources
import 'features/space_control/data/datasources/space_mock_datasource.dart';
import 'features/store_dashboard/data/datasources/store_mock_datasource.dart';

final sl = GetIt.instance;

Future<void> initializeDependencies() async {
  // =============================================
  // Core
  // =============================================

  // External
  sl.registerLazySingleton(() => Connectivity());

  // Services
  sl.registerLazySingleton(() => LocalStorageService());
  sl.registerLazySingleton(() => SessionDataCache());
  sl.registerLazySingleton(() => DioClient(localStorage: sl()));

  // Network
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );

  // Session
  sl.registerLazySingleton(() => SessionCubit(localStorage: sl()));
  sl.registerLazySingleton<CamsPlaybackCapabilityProvider>(
    () => const StaticCamsPlaybackCapabilityProvider(
      CamsPlaybackCapabilities(
        supportsImmediateManualQueueTakeover: false,
      ),
    ),
  );

  // =============================================
  // Auth Feature
  // =============================================

  // Data sources — toggle between real API and mock via ApiConstants.useMockData
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => ApiConstants.useMockData
        ? AuthMockDataSource()
        : AuthRemoteDataSourceImpl(dioClient: sl(), localStorage: sl()),
  );

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localStorage: sl(),
      networkInfo: sl(),
      dioClient: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => Login(sl()));
  sl.registerLazySingleton(() => Logout(sl()));
  sl.registerLazySingleton(() => GetCurrentUser(sl()));
  sl.registerLazySingleton(() => ChangePassword(sl()));
  sl.registerLazySingleton(() => RequestForgotPasswordOtp(sl()));
  sl.registerLazySingleton(() => VerifyForgotPasswordOtp(sl()));
  sl.registerLazySingleton(() => ResetForgotPassword(sl()));

  // BLoCs
  sl.registerLazySingleton(
    () => AuthBloc(
      login: sl(),
      logout: sl(),
      getCurrentUser: sl(),
      changePassword: sl(),
      requestForgotPasswordOtp: sl(),
      verifyForgotPasswordOtp: sl(),
      resetForgotPassword: sl(),
      sessionCubit: sl(),
      sessionDataCache: sl(),
    ),
  );

  // =============================================
  // Device Pairing Feature
  // =============================================

  // Data sources — toggle via ApiConstants.useMockData
  sl.registerLazySingleton<DevicePairingRemoteDataSource>(
    () => ApiConstants.useMockData
        ? DevicePairingMockDataSource()
        : DevicePairingRemoteDataSourceImpl(dioClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<DevicePairingRepository>(
    () => DevicePairingRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
      localStorage: sl(),
      dioClient: sl(),
      camsRemoteDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => PairDevice(sl()));

  // BLoCs
  sl.registerFactory(
    () => DevicePairingBloc(
      pairDeviceUseCase: sl(),
    ),
  );

  // =============================================
  // Hub Management Feature
  // =============================================

  // Data sources
  sl.registerLazySingleton<SpaceHubRemoteDataSource>(
    () => SpaceHubRemoteDataSourceImpl(dioClient: sl()),
  );
  sl.registerLazySingleton(
    () => SpaceHubStubDataSource(localStorage: sl()),
  );

  // Services
  sl.registerLazySingleton<BleProvisioningService>(
    () => FlutterBleProvisioningService(),
  );
  sl.registerLazySingleton<BlePermissionService>(
    () => PermissionHandlerBlePermissionService(),
  );
  sl.registerLazySingleton<LocationCaptureService>(
    () => GeolocatorLocationCaptureService(),
  );
  sl.registerLazySingleton<ProvisioningIdentityResolver>(
    () => const PrefixProvisioningIdentityResolver(
      blePrefix: 'CAM_',
    ),
  );

  // Repositories
  sl.registerLazySingleton<SpaceHubRepository>(
    () => SpaceHubRepositoryImpl(
      remoteDataSource: sl(),
      stubDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetSpaceHubBinding(sl()));
  sl.registerLazySingleton(() => UpsertSpaceHubBinding(sl()));
  sl.registerLazySingleton(() => DeleteSpaceHubBinding(sl()));
  sl.registerLazySingleton(() => RestartSpaceHub(sl()));

  // BLoCs
  sl.registerFactory(
    () => HubProvisioningBloc(
      getSpaceHubBinding: sl(),
      upsertSpaceHubBinding: sl(),
      deleteSpaceHubBinding: sl(),
      restartSpaceHub: sl(),
      getPairedSpace: sl(),
      updateSpace: sl(),
      bleProvisioningService: sl(),
      blePermissionService: sl(),
      locationCaptureService: sl(),
      identityResolver: sl(),
    ),
  );

  // =============================================
  // Location Feature
  // =============================================

  // Data sources — toggle via ApiConstants.useMockData
  sl.registerLazySingleton<LocationRemoteDataSource>(
    () => ApiConstants.useMockData
        ? LocationMockDataSource()
        : LocationRemoteDataSourceImpl(dioClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetPairedSpace(sl()));
  sl.registerLazySingleton(() => GetSpacesForStore(sl()));
  sl.registerLazySingleton(() => GetSpacesForBrand(sl()));
  sl.registerLazySingleton(() => CreateSpace(sl()));
  sl.registerLazySingleton(() => UpdateSpace(sl()));
  sl.registerLazySingleton(() => DeleteSpace(sl()));
  sl.registerLazySingleton(() => ToggleSpaceStatus(sl()));
  sl.registerLazySingleton(() => CreateSpaceFuzzyOverrideProfile(sl()));

  // BLoCs
  sl.registerFactory(
    () => LocationBloc(
      sessionCubit: sl(),
      authBloc: sl(),
      getPairedSpace: sl(),
      getSpacesForStore: sl(),
      getSpacesForBrand: sl(),
      getSpaceState: sl(),
      getSpaceHubBinding: sl(),
      getPairDeviceInfoForManager: sl(),
      getPairDeviceInfoForPlaybackDevice: sl(),
      generatePairCode: sl(),
      revokePairCode: sl(),
      unpairPlaybackDevice: sl(),
      playlistDataSource: sl(),
      getUserStores: sl(),
      storeHubService: sl(),
      sessionDataCache: sl(),
    ),
  );

  // =============================================
  // Space Schedule Feature
  // =============================================

  sl.registerLazySingleton(
    () => SpaceScheduleMockDataSource(),
  );

  sl.registerLazySingleton(
    () => SpaceScheduleLocalDataSource(localStorage: sl()),
  );

  sl.registerLazySingleton<SpaceScheduleRemoteDataSource>(
    () => SpaceScheduleRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<SpaceScheduleRepository>(
    () => SpaceScheduleRepositoryImpl(
      mockDataSource: sl(),
      localDataSource: sl(),
      remoteDataSource: ApiConstants.useMockData ? null : sl(),
    ),
  );

  sl.registerLazySingleton(() => GetSpaceScheduleBootstrap(sl()));
  sl.registerLazySingleton(() => ApplyScheduleSource(sl()));
  sl.registerLazySingleton(() => SaveSpaceSchedule(sl()));
  sl.registerLazySingleton(() => ToggleSpaceSchedule(sl()));
  sl.registerLazySingleton(() => SaveScheduleToLibrary(sl()));
  sl.registerLazySingleton(() => DeleteScheduleSlot(sl()));

  sl.registerFactory(
    () => SpaceScheduleBloc(
      getSpaceScheduleBootstrap: sl(),
      applyScheduleSource: sl(),
      saveSpaceSchedule: sl(),
      toggleSpaceSchedule: sl(),
      saveScheduleToLibrary: sl(),
      deleteScheduleSlot: sl(),
      getStoreDetails: sl(),
    ),
  );

  // =============================================
  // Settings Feature
  // =============================================

  // Data sources — toggle via ApiConstants.useMockData
  sl.registerLazySingleton<SettingsDataSource>(
    () => ApiConstants.useMockData
        ? SettingsMockDataSource()
        : SettingsRemoteDataSource(dioClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(
      dataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetSettingsSnapshot(sl()));

  // Cubits
  sl.registerFactory(
    () => SettingsCubit(sl()),
  );

  // =============================================
  // Space Control Feature
  // =============================================

  // Data sources — toggle via ApiConstants.useMockData
  sl.registerLazySingleton<SpaceRemoteDataSource>(
    () => ApiConstants.useMockData
        ? SpaceMockDataSource()
        : SpaceRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<OfflinePlaylistDataSource>(
    () => ApiConstants.useMockData
        ? OfflinePlaylistMockDatasource()
        : OfflinePlaylistRemoteDataSourceImpl(dioClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<SpaceRepository>(
    () => SpaceRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<OfflinePlaylistRepository>(
    () => OfflinePlaylistRepositoryImpl(
      dataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetSpaceById(sl()));
  sl.registerLazySingleton(() => SubscribeToSensorData(sl()));
  sl.registerLazySingleton(() => SubscribeToSpaceStatus(sl()));

  // BLoCs
  sl.registerFactory(
    () => SpaceMonitoringBloc(
      getSpaceById: sl(),
      subscribeToSpaceStatus: sl(),
      subscribeToSensorData: sl(),
    ),
  );

  sl.registerFactory(
    () => OfflineLibraryBloc(
      repository: sl(),
    ),
  );

  // =============================================
  // Store Dashboard Feature
  // =============================================

  // Data sources — toggle via ApiConstants.useMockData
  sl.registerLazySingleton<StoreRemoteDataSource>(
    () => ApiConstants.useMockData
        ? StoreMockDataSource()
        : StoreRemoteDataSourceImpl(dioClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<StoreRepository>(
    () => StoreRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetStoreDetails(sl()));
  sl.registerLazySingleton(() => GetSpaceSummaries(sl()));
  sl.registerLazySingleton(() => CreateStore(sl()));
  sl.registerLazySingleton(() => UpdateStore(sl()));
  sl.registerLazySingleton(() => DeleteStore(sl()));
  sl.registerLazySingleton(() => ToggleStoreStatus(sl()));
  sl.registerLazySingleton(() => CreateStoreFuzzyOverrideProfile(sl()));

  // BLoCs
  sl.registerFactory(
    () => StoreDashboardBloc(
      getStoreDetails: sl(),
      getSpaceSummaries: sl(),
      sessionDataCache: sl(),
    ),
  );

  // =============================================
  // Store Selection Feature
  // =============================================

  // Data sources
  sl.registerLazySingleton<StoreSelectionRemoteDataSource>(
    () => StoreSelectionRemoteDataSourceImpl(dioClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<StoreSelectionRepository>(
    () => StoreSelectionRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetUserStores(sl()));
  sl.registerLazySingleton(() => GetBrandDetail(sl()));
  sl.registerLazySingleton(() => UpdateBrandDetail(sl()));

  // BLoCs
  sl.registerFactory(
    () => StoreSelectionBloc(
      getUserStores: sl(),
      getBrandDetail: sl(),
      sessionDataCache: sl(),
    ),
  );

  // =============================================
  // Zone Management Feature
  // =============================================

  // Data sources — toggle via ApiConstants.useMockData
  sl.registerLazySingleton<ZoneRemoteDataSource>(
    () => ApiConstants.useMockData
        ? ZoneMockDataSource()
        : ZoneRemoteDataSourceImpl(dioClient: sl()),
  );

  // Repositories
  sl.registerLazySingleton<ZoneRepository>(
    () => ZoneRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  sl.registerLazySingleton<MusicProfileRepository>(
    () => MusicProfileRepositoryImpl(
      remoteDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetZonesBySpace(sl()));
  sl.registerLazySingleton(() => GetMusicProfileForZone(sl()));
  sl.registerLazySingleton(() => UpdateZoneMusicSettings(sl()));
  sl.registerLazySingleton(() => SyncZonesMusic(sl()));
  sl.registerLazySingleton(() => AssignPlaylistToZone(sl()));
  sl.registerLazySingleton(() => GetAllPlaylists(sl()));

  // Note: BLoC will be added when UI is implemented

  // =============================================
  // Moods Feature
  // =============================================

  sl.registerLazySingleton<MoodRemoteDataSource>(
    () => MoodRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<MoodRepository>(
    () => MoodRepositoryImpl(remoteDataSource: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetMoods(sl()));

  // =============================================
  // Tracks Feature
  // =============================================

  sl.registerLazySingleton<TrackRemoteDataSource>(
    () => TrackRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<TrackRepository>(
    () => TrackRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetTracks(sl()));
  sl.registerLazySingleton(() => GetTrackById(sl()));
  sl.registerLazySingleton(() => CreateTrack(sl()));
  sl.registerLazySingleton(() => UpdateTrack(sl()));
  sl.registerLazySingleton(() => DeleteTrack(sl()));
  sl.registerLazySingleton(() => ToggleTrackStatus(sl()));
  sl.registerLazySingleton(() => RetranscodeTrack(sl()));
  sl.registerLazySingleton(() => SetTrackCopyrightClearance(sl()));

  // =============================================
  // Playlists Feature
  // =============================================

  sl.registerLazySingleton<PlaylistRemoteDataSource>(
    () => PlaylistRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<PlaylistRepository>(
    () => PlaylistRepositoryImpl(remoteDataSource: sl()),
  );

  // =============================================
  // Suno Feature
  // =============================================

  sl.registerLazySingleton<SunoRemoteDataSource>(
    () => SunoRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<SunoRepository>(
    () => SunoRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => CreateSunoGeneration(sl()));
  sl.registerLazySingleton(() => GetSunoGenerations(sl()));
  sl.registerLazySingleton(() => GetSunoGeneration(sl()));
  sl.registerLazySingleton(() => CancelSunoGeneration(sl()));
  sl.registerLazySingleton(() => GetSunoConfig(sl()));
  sl.registerLazySingleton(() => UpdateSunoConfig(sl()));
  sl.registerLazySingleton(
    () => SunoPlaybackOrchestrator(
      createSunoGeneration: sl(),
      getSunoGeneration: sl(),
      getTrackById: sl(),
      getSpaceState: sl(),
      queueTracks: sl(),
    ),
  );

  // =============================================
  // Config Governance Feature
  // =============================================

  sl.registerLazySingleton<ConfigGovernanceRemoteDataSource>(
    () => ConfigGovernanceRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<ConfigGovernanceRepository>(
    () => ConfigGovernanceRepositoryImpl(remoteDataSource: sl()),
  );

  sl.registerLazySingleton(() => GetBrandConfig(sl()));
  sl.registerLazySingleton(() => GetStoreConfig(sl()));
  sl.registerLazySingleton(() => GetSpaceConfig(sl()));
  sl.registerLazySingleton(() => UpsertBrandConfigValue(sl()));
  sl.registerLazySingleton(() => UpsertStoreConfigValue(sl()));
  sl.registerLazySingleton(() => UpsertSpaceConfigValue(sl()));
  sl.registerLazySingleton(() => SetStoreGovernanceMode(sl()));

  sl.registerLazySingleton<FuzzyMusicProfileRemoteDataSource>(
    () => FuzzyMusicProfileRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerFactory(
    () => ConfigGovernanceCubit(
      getBrandConfig: sl(),
      getStoreConfig: sl(),
      getSpaceConfig: sl(),
      upsertBrandConfigValue: sl(),
      upsertStoreConfigValue: sl(),
      upsertSpaceConfigValue: sl(),
      setStoreGovernanceMode: sl(),
    ),
  );

  // =============================================
  // CAMS Feature (Context-Aware Music System)
  // =============================================

  sl.registerLazySingleton<CamsRemoteDataSource>(
    () => CamsRemoteDataSourceImpl(dioClient: sl()),
  );

  sl.registerLazySingleton<CamsRepository>(
    () => CamsRepositoryImpl(remoteDataSource: sl()),
  );

  // SignalR StoreHub — requires access token factory
  sl.registerLazySingleton<StoreHubService>(
    () => StoreHubService(
      accessTokenFactory: () {
        final localStorage = sl<LocalStorageService>();
        return localStorage.getToken() ?? '';
      },
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetSpaceState(sl()));
  sl.registerLazySingleton(() => GetCurrentDeviceSpaceState(sl()));
  sl.registerLazySingleton(() => OverrideSpace(sl()));
  sl.registerLazySingleton(() => CancelOverride(sl()));
  sl.registerLazySingleton(() => SendPlaybackCommand(sl()));
  sl.registerLazySingleton(() => UpdateAudioState(sl()));
  sl.registerLazySingleton(() => UpdateSchedulingState(sl()));
  sl.registerLazySingleton(() => QueueTracks(sl()));
  sl.registerLazySingleton(() => QueuePlaylist(sl()));
  sl.registerLazySingleton(() => ReorderQueue(sl()));
  sl.registerLazySingleton(() => RemoveQueueItems(sl()));
  sl.registerLazySingleton(() => ClearQueue(sl()));
  sl.registerLazySingleton(() => GetSpaceQueue(sl()));
  sl.registerLazySingleton(() => GetPairDeviceInfoForManager(sl()));
  sl.registerLazySingleton(() => GetPairDeviceInfoForPlaybackDevice(sl()));
  sl.registerLazySingleton(() => GeneratePairCode(sl()));
  sl.registerLazySingleton(() => RevokePairCode(sl()));
  sl.registerLazySingleton(() => UnpairPlaybackDevice(sl()));
  sl.registerLazySingleton(
    () => QueueFirstPlaybackRuntime(
      getSpaceState: sl(),
      queueTracks: sl(),
      queuePlaylist: sl(),
      reorderQueue: sl(),
      removeQueueItems: sl(),
      clearQueue: sl(),
      getSpaceQueue: sl(),
      sendPlaybackCommand: sl(),
      updateAudioState: sl(),
      updateSchedulingState: sl(),
      storeHubService: sl(),
    ),
  );

  // BLoCs
  sl.registerFactory(
    () => CamsPlaybackBloc(
      overrideSpace: sl(),
      cancelOverride: sl(),
      getMoods: sl(),
      storeHubService: sl(),
      sessionCubit: sl(),
      runtime: sl(),
      capabilityProvider: sl(),
    ),
  );

  // =============================================
  // Home Feature
  // =============================================

  // Data sources
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(
      moodDataSource: sl(),
      playlistDataSource: sl(),
      dioClient: sl(),
    ),
  );

  // Repositories
  sl.registerLazySingleton<HomeRepository>(
    () => ApiConstants.useMockData
        ? MockHomeRepositoryImpl()
        : HomeRepositoryImpl(dataSource: sl(), sessionDataCache: sl()),
  );

  // Cubits
  sl.registerFactory(
    () => HomeCubit(
      sl(),
      getSpaceState: sl(),
      getMoods: sl(),
      overrideSpace: sl(),
      cancelOverride: sl(),
      sessionDataCache: sl(),
    ),
  );

  // =============================================
  // Search Feature
  // =============================================

  // Repository
  sl.registerLazySingleton<SearchRepository>(
    () => SearchRepositoryImpl(
      playlistDataSource: sl(),
      trackDataSource: sl(),
      moodDataSource: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => SearchMusicUseCase(sl()));
  sl.registerLazySingleton(() => SearchByTypeUseCase(sl()));
  sl.registerLazySingleton(() => GetArtistDetailUseCase(sl()));
  sl.registerLazySingleton(() => GetAlbumDetailUseCase(sl()));
  sl.registerLazySingleton(() => GetPlaylistDetailUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoryPlaylistsUseCase(sl()));
  sl.registerLazySingleton(() => GetCategoryTracksUseCase(sl()));
  sl.registerLazySingleton(() => GetGenreTracksUseCase(sl()));
  sl.registerLazySingleton(() => GetFeaturedPlaylistsUseCase(sl()));

  // BLoCs / Cubits
  sl.registerFactory(
    () => SearchBloc(
      getCategories: sl(),
      searchMusic: sl(),
      searchByType: sl(),
      getFeaturedPlaylists: sl(),
      sessionDataCache: sl(),
      sessionCubit: sl(),
    ),
  );

  sl.registerFactory(
    () => ArtistDetailCubit(getArtistDetail: sl()),
  );

  sl.registerFactory(
    () => AlbumDetailCubit(getAlbumDetail: sl()),
  );

  sl.registerFactory(
    () => CategoryDetailCubit(
      getCategoryPlaylists: sl(),
      getCategoryTracks: sl(),
      getGenreTracks: sl(),
      sessionCubit: sl(),
    ),
  );
}
