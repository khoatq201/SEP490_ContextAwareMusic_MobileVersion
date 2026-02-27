import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/auth/presentation/pages/login_page_v2.dart';
import 'features/auth/presentation/pages/welcome_page.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/device_pairing/presentation/pages/device_pairing_page.dart';
import 'features/device_pairing/presentation/bloc/device_pairing_bloc.dart';
import 'features/store_selection/presentation/pages/store_selection_page.dart';
import 'features/store_selection/presentation/bloc/store_selection_bloc.dart';
import 'features/store_dashboard/presentation/pages/store_dashboard_page.dart';
import 'features/store_dashboard/presentation/bloc/store_dashboard_bloc.dart';
import 'features/store_dashboard/presentation/bloc/store_dashboard_event.dart';
import 'features/space_control/presentation/pages/space_detail_page.dart';
import 'features/space_control/presentation/bloc/space_monitoring_bloc.dart';
import 'features/space_control/presentation/bloc/music_control_bloc.dart';
import 'features/space_control/presentation/bloc/offline_library_bloc.dart';
import 'features/settings/presentation/bloc/settings_cubit.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/settings/presentation/pages/settings_user_page.dart';
import 'features/settings/presentation/pages/settings_company_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/playlist_management/presentation/pages/playlist_management_page.dart';
import 'core/presentation/component_showcase_page.dart';
import 'core/presentation/theme_showcase_page.dart';
import 'core/presentation/theme_demo_page.dart';
import 'core/presentation/main_shell_page.dart';
import 'features/home/presentation/pages/home_tab_page.dart';
import 'features/home/presentation/pages/playlist_detail_page.dart';
import 'features/home/domain/entities/playlist_entity.dart';
import 'features/search/presentation/pages/search_tab_page.dart';
import 'features/now_playing/presentation/pages/now_playing_tab_page.dart';
import 'features/library/presentation/pages/library_tab_page.dart';
import 'features/locations/presentation/pages/locations_tab_page.dart';
import 'features/context_rules/presentation/pages/context_rules_page.dart';
import 'features/context_rules/presentation/pages/create_rule_page.dart';
import 'core/session/session_cubit.dart';
import 'injection_container.dart';

/// Converts a [Stream] into a [Listenable] so GoRouter re-evaluates
/// its redirect whenever the stream emits a new value.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners(); // initial evaluation
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

class AppRouter {
  static GoRouter router = GoRouter(
    initialLocation: '/welcome',
    refreshListenable: GoRouterRefreshStream(sl<AuthBloc>().stream),
    redirect: (BuildContext context, GoRouterState state) {
      final authBloc = sl<AuthBloc>();
      final sessionCubit = sl<SessionCubit>();

      final isAuthenticated = authBloc.state.status == AuthStatus.authenticated;
      final isPaired = sessionCubit.state.isPlaybackDevice;
      final location = state.matchedLocation;
      final isPublic = location == '/welcome' ||
          location == '/login' ||
          location == '/forgot-password' ||
          location == '/pair-device';

      // 1. If operating as a paired playback device, force them into the shell (home)
      // unless they are already on a valid tab. Do not let them go to login.
      if (isPaired) {
        if (location == '/welcome' ||
            location == '/login' ||
            location == '/pair-device' ||
            location == '/store-selection') {
          return '/home';
        }
        return null;
      }

      // 2. If not authenticated and not public, force login.
      if (!isAuthenticated && !isPublic) return '/login';

      // 3. Whenever authenticated, ensure role is in sync with user data.
      if (isAuthenticated) {
        final user = authBloc.state.user;
        if (user != null) {
          // Always keep the session role in sync with the user's role.
          // This guards against any code path that might reset the role.
          sessionCubit.setRoleFromString(user.role);
        }

        // If on welcome/login/pair page, redirect based on role.
        if (location == '/welcome' ||
            location == '/login' ||
            location == '/pair-device') {
          return '/store-selection';
        }

        // Prevent StoreManager from staying on /store-selection.
        // They should be redirected automatically via the page's BLoC listener,
        // but if they somehow navigate here after already selecting a store,
        // send them to their store dashboard.
        if (location == '/store-selection' &&
            user != null &&
            user.isStoreManager &&
            sessionCubit.state.currentStore != null) {
          return '/store/${sessionCubit.state.currentStore!.id}';
        }
      }

      return null;
    },
    routes: [
      // ---------------------------------------------------------------
      // Public / pre-auth routes
      // ---------------------------------------------------------------
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => BlocProvider.value(
          value: sl<AuthBloc>(),
          child: const LoginPageV2(),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => BlocProvider.value(
          value: sl<AuthBloc>(),
          child: const ForgotPasswordPage(),
        ),
      ),
      GoRoute(
        path: '/pair-device',
        name: 'pair-device',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<DevicePairingBloc>(),
          child: const DevicePairingPage(),
        ),
      ),

      // ---------------------------------------------------------------
      // Store / Space selection (post-login, pre-home)
      // ---------------------------------------------------------------
      GoRoute(
        path: '/store-selection',
        name: 'store-selection',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: sl<AuthBloc>()),
            BlocProvider(create: (_) => sl<StoreSelectionBloc>()),
          ],
          child: const StoreSelectionPage(),
        ),
      ),
      GoRoute(
        path: '/store/:storeId',
        name: 'store-dashboard',
        builder: (context, state) {
          final storeId = state.pathParameters['storeId']!;
          return MultiBlocProvider(
            providers: [
              BlocProvider.value(value: sl<AuthBloc>()),
              BlocProvider(
                create: (_) => sl<StoreDashboardBloc>()
                  ..add(LoadStoreDashboard(storeId: storeId)),
              ),
            ],
            child: StoreDashboardPage(storeId: storeId),
          );
        },
      ),
      // ---------------------------------------------------------------
      // Main Shell – 5-tab BottomNavigationBar
      // /space lives here so BottomBar stays visible after space selection
      // ---------------------------------------------------------------
      ShellRoute(
        builder: (context, state, child) => MainShellPage(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeTabPage(),
            ),
            routes: [
              // Sub-route: Space detail pushed on top of Home tab
              GoRoute(
                path: 'space',
                name: 'space-detail',
                builder: (context, state) {
                  final storeId =
                      state.uri.queryParameters['storeId'] ?? 'store-1';
                  final spaceId =
                      state.uri.queryParameters['spaceId'] ?? 'space-1';
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: sl<AuthBloc>()),
                      // Reuse global singletons so NowPlayingTab stays in sync
                      BlocProvider.value(
                          value: context.read<SpaceMonitoringBloc>()),
                      BlocProvider.value(
                          value: context.read<MusicControlBloc>()),
                      BlocProvider(create: (_) => sl<OfflineLibraryBloc>()),
                    ],
                    child: SpaceDetailPage(storeId: storeId, spaceId: spaceId),
                  );
                },
              ),
              // Sub-route: Playlist detail — stays inside the shell so
              // BottomNav stays visible and tab switching works.
              GoRoute(
                path: 'playlist-detail',
                name: 'playlist-detail',
                builder: (context, state) {
                  final playlist = state.extra as PlaylistEntity;
                  return PlaylistDetailPage(playlist: playlist);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: sl<AuthBloc>()),
                BlocProvider(create: (_) => sl<SettingsCubit>()..load()),
              ],
              child: const SettingsPage(),
            ),
          ),
          GoRoute(
            path: '/settings/user',
            name: 'settings-user',
            builder: (context, state) => BlocProvider.value(
              value: sl<AuthBloc>(),
              child: const SettingsUserPage(),
            ),
          ),
          GoRoute(
            path: '/settings/company',
            name: 'settings-company',
            builder: (context, state) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: sl<AuthBloc>()),
                BlocProvider(create: (_) => sl<SettingsCubit>()..load()),
              ],
              child: const SettingsCompanyPage(),
            ),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchTabPage(),
            ),
          ),
          GoRoute(
            path: '/create',
            name: 'create',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ContextRulesPage(
                showBackButton: false,
                createRulePath: '/create/new',
              ),
            ),
            routes: [
              GoRoute(
                path: 'new',
                name: 'create-rule-tab',
                builder: (context, state) => const CreateRulePage(),
              ),
            ],
          ),
          GoRoute(
            path: '/now-playing',
            name: 'now-playing',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NowPlayingTabPage(),
            ),
          ),
          GoRoute(
            path: '/library',
            name: 'library',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LibraryTabPage(),
            ),
          ),
          GoRoute(
            path: '/locations',
            name: 'locations',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LocationsTabPage(),
            ),
          ),
        ],
      ),

      // ---------------------------------------------------------------
      // Standalone pages (outside the shell)
      // ---------------------------------------------------------------
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => BlocProvider.value(
          value: sl<AuthBloc>(),
          child: const ProfilePage(),
        ),
      ),
      GoRoute(
        path: '/playlists',
        name: 'playlists',
        builder: (context, state) => BlocProvider.value(
          value: sl<AuthBloc>(),
          child: const PlaylistManagementPage(),
        ),
      ),
      GoRoute(
        path: '/showcase',
        name: 'component-showcase',
        builder: (context, state) => const ComponentShowcasePage(),
      ),
      GoRoute(
        path: '/theme',
        name: 'theme-showcase',
        builder: (context, state) => const CAMSThemeShowcase(),
      ),
      GoRoute(
        path: '/theme-demo',
        name: 'theme-demo',
        builder: (context, state) => const ThemeDemoPage(),
      ),
      GoRoute(
        path: '/context-rules',
        name: 'context-rules',
        builder: (context, state) => const ContextRulesPage(),
        routes: [
          GoRoute(
            path: 'create',
            name: 'create-rule',
            builder: (context, state) => const CreateRulePage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('Page not found')),
    ),
  );
}
