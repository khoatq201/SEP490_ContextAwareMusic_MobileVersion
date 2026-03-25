import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'injection_container.dart';
import 'router.dart';
import 'core/constants/api_constants.dart';
import 'core/network/dio_client.dart';
import 'core/services/local_storage_service.dart';
import 'core/services/mqtt_service.dart';
import 'core/presentation/splash_screen.dart';
import 'core/presentation/app_playback_coordinator.dart';
import 'core/session/session_cubit.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/enums/entity_status_enum.dart';
import 'core/enums/space_type_enum.dart';
import 'core/player/player_bloc.dart';
import 'core/audio/audio_player_service.dart';
import 'core/audio/playback_notification_service.dart';
import 'features/cams/data/datasources/cams_remote_datasource.dart';
import 'features/cams/presentation/bloc/cams_playback_bloc.dart';
import 'features/space_control/presentation/bloc/music_control_bloc.dart';
import 'features/space_control/presentation/bloc/space_monitoring_bloc.dart';
import 'features/space_control/data/datasources/space_remote_datasource.dart';
import 'features/space_control/domain/entities/space.dart';
import 'features/store_dashboard/domain/entities/store.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final audioPlayerService = AudioPlayerService();
  await audioPlayerService.configureForBackgroundPlayback();
  final playbackNotificationService = await PlaybackNotificationService.init(
    audioPlayerService: audioPlayerService,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<PlaybackNotificationService>.value(
          value: playbackNotificationService,
        ),
        // SessionCubit — global session state (role, store, space, permissions)
        BlocProvider(create: (_) => sl<SessionCubit>()),
        // PlayerBloc lives above the router so MiniPlayer persists across tabs
        BlocProvider(
          create: (_) => PlayerBloc(audioPlayerService: audioPlayerService),
        ),
        BlocProvider(create: (_) => sl<CamsPlaybackBloc>()),
        // MusicControlBloc & SpaceMonitoringBloc are global so NowPlayingTab
        // can always read live space/sensor/music state from any tab.
        BlocProvider(create: (_) => sl<MusicControlBloc>()),
        BlocProvider(create: (_) => sl<SpaceMonitoringBloc>()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isInitialized = false;

  Future<Map<String, dynamic>?> _hydratePlaybackDeviceSession({
    required LocalStorageService localStorage,
  }) async {
    final currentSession = localStorage.getDeviceSession();
    if (currentSession == null || localStorage.isDeviceTokenExpired()) {
      return null;
    }

    final hydrated = Map<String, dynamic>.from(currentSession);

    try {
      final pairInfo =
          await sl<CamsRemoteDataSource>().getPairDeviceInfoForPlaybackDevice();
      hydrated['storeId'] = pairInfo.storeId;
      hydrated['spaceId'] = pairInfo.spaceId;
      hydrated['brandId'] = pairInfo.brandId;
      if ((pairInfo.deviceId ?? '').isNotEmpty) {
        hydrated['deviceId'] = pairInfo.deviceId;
      }
    } catch (_) {
      // Best effort only. Existing local scope can still be restored.
    }

    final spaceId = hydrated['spaceId']?.toString();
    if (spaceId != null &&
        spaceId.isNotEmpty &&
        (hydrated['spaceName']?.toString().trim().isEmpty ?? true)) {
      try {
        final space = await sl<SpaceRemoteDataSource>().getSpaceById(spaceId);
        hydrated['spaceName'] = space.name;
      } catch (_) {
        hydrated['spaceName'] = 'Paired Space';
      }
    }

    final storeName = hydrated['storeName']?.toString();
    if (storeName == null || storeName.trim().isEmpty) {
      hydrated['storeName'] = 'Paired Store';
    }

    final spaceName = hydrated['spaceName']?.toString();
    if (spaceName == null || spaceName.trim().isEmpty) {
      hydrated['spaceName'] = 'Paired Space';
    }

    return hydrated;
  }

  Future<void> _resetAuthSessionIfBaseUrlChanged({
    required LocalStorageService localStorage,
    required DioClient dioClient,
  }) async {
    final storedBaseUrl =
        localStorage.getSetting(ApiConstants.lastApiBaseUrlKey);
    final previousBaseUrl = storedBaseUrl is String ? storedBaseUrl : null;
    const currentBaseUrl = ApiConstants.baseUrl;

    if (previousBaseUrl != null && previousBaseUrl != currentBaseUrl) {
      debugPrint(
        'API base URL changed: $previousBaseUrl -> $currentBaseUrl. '
        'Clearing auth token, cached user and cookies.',
      );
      await localStorage.clearAllAuthSessions();
      await dioClient.clearCookies();
    }

    await localStorage.saveSetting(
      ApiConstants.lastApiBaseUrlKey,
      currentBaseUrl,
    );
  }

  Future<void> _initializeApp() async {
    WidgetsFlutterBinding.ensureInitialized();

    debugPrint('API base URL: ${ApiConstants.baseUrl}');
    debugPrint('useMockData: ${ApiConstants.useMockData}');

    // Initialize dependency injection
    await initializeDependencies();

    // Initialize local storage
    final localStorage = sl<LocalStorageService>();
    await localStorage.init();

    // Initialize cookie jar for HttpOnly refresh token cookies
    final dioClient = sl<DioClient>();
    await dioClient.initCookieJar();
    await _resetAuthSessionIfBaseUrlChanged(
      localStorage: localStorage,
      dioClient: dioClient,
    );

    final sessionCubit = sl<SessionCubit>();
    final deviceSession = await _hydratePlaybackDeviceSession(
      localStorage: localStorage,
    );
    final hasRestorablePlaybackSession = deviceSession != null &&
        deviceSession['storeId'] != null &&
        deviceSession['spaceId'] != null;

    if (hasRestorablePlaybackSession) {
      await localStorage.saveDeviceSession(deviceSession);
      await localStorage.saveActiveSessionMode(
        LocalStorageService.sessionModePlaybackDevice,
      );
      sessionCubit.setPlaybackMode(
        store: Store(
          id: deviceSession['storeId'].toString(),
          name: deviceSession['storeName']?.toString() ?? 'Paired Store',
          brandId: deviceSession['brandId']?.toString() ?? '',
        ),
        space: Space(
          id: deviceSession['spaceId'].toString(),
          name: deviceSession['spaceName']?.toString() ?? 'Paired Space',
          storeId: deviceSession['storeId'].toString(),
          type: SpaceTypeEnum.hall,
          status: EntityStatusEnum.active,
        ),
        deviceId: deviceSession['deviceId']?.toString() ??
            deviceSession['spaceId'].toString(),
      );
    } else {
      await localStorage.clearDeviceSession();

      // ── Restore manager auth session from persisted token ──
      final authBloc = sl<AuthBloc>();
      authBloc.add(const CheckAuthStatus());
      final resolvedAuthState = await authBloc.stream
          .firstWhere((s) =>
              s.status == AuthStatus.authenticated ||
              s.status == AuthStatus.unauthenticated)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () =>
                const AuthState(status: AuthStatus.unauthenticated),
          );

      if (resolvedAuthState.status == AuthStatus.authenticated) {
        await localStorage.saveActiveSessionMode(
          LocalStorageService.sessionModeManager,
        );
        await sessionCubit.restoreSelectionFromStorage();
      } else {
        await localStorage.clearManagerSession();
        sessionCubit.reset();
      }
    }

    // Skip MQTT in demo mode — no backend required
    if (!ApiConstants.useMockData) {
      final mqttService = sl<MqttService>();
      try {
        await mqttService.connect(
          clientId: 'cams_manager_${DateTime.now().millisecondsSinceEpoch}',
        );
      } catch (e) {
        debugPrint('MQTT connection failed: $e');
      }
    } else {
      debugPrint('🎨 Demo mode enabled — MQTT connection skipped');
    }

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (!_isInitialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: themeProvider.themeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: SplashScreen(
          onInitializationComplete: _initializeApp,
        ),
      );
    }

    return AppPlaybackCoordinator(
      child: MaterialApp.router(
        title: 'CAMS Store Manager',
        debugShowCheckedModeBanner: false,
        themeMode: themeProvider.themeMode,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
