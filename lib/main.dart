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
import 'core/player/player_bloc.dart';
import 'core/audio/audio_player_service.dart';
import 'core/audio/playback_notification_service.dart';
import 'features/cams/presentation/bloc/cams_playback_bloc.dart';
import 'features/space_control/presentation/bloc/music_control_bloc.dart';
import 'features/space_control/presentation/bloc/space_monitoring_bloc.dart';
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
      await localStorage.clearAuthToken();
      await localStorage.clearUser();
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

    // ── Restore auth session from persisted token ──
    // Reads the saved JWT from Hive and, if valid, restores
    // AuthState.authenticated so the user is NOT forced to re-login.
    // We MUST await this before marking _isInitialized = true,
    // otherwise GoRouter evaluates its redirect while AuthBloc is
    // still in initial/loading state and sends the user to /login.
    final authBloc = sl<AuthBloc>();
    authBloc.add(const CheckAuthStatus());
    // Wait until the auth check resolves (authenticated or unauthenticated)
    final resolvedAuthState = await authBloc.stream
        .firstWhere((s) =>
            s.status == AuthStatus.authenticated ||
            s.status == AuthStatus.unauthenticated)
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () => const AuthState(status: AuthStatus.unauthenticated),
        );

    final sessionCubit = sl<SessionCubit>();
    if (resolvedAuthState.status == AuthStatus.authenticated) {
      await sessionCubit.restoreSelectionFromStorage();
    } else {
      sessionCubit.reset();
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
