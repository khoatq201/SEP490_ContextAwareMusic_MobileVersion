import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'features/auth/presentation/pages/login_page_v2.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/store_selection/presentation/pages/store_selection_page.dart';
import 'features/store_selection/presentation/bloc/store_selection_bloc.dart';
import 'features/store_dashboard/presentation/pages/store_dashboard_page.dart';
import 'features/store_dashboard/presentation/bloc/store_dashboard_bloc.dart';
import 'features/store_dashboard/presentation/bloc/store_dashboard_event.dart';
import 'features/space_control/presentation/pages/space_detail_page.dart';
import 'features/space_control/presentation/bloc/space_monitoring_bloc.dart';
import 'features/space_control/presentation/bloc/music_control_bloc.dart';
import 'features/space_control/presentation/bloc/offline_library_bloc.dart';
import 'features/settings/presentation/pages/settings_page.dart';
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
import 'injection_container.dart';

class AppRouter {
  static GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) {
      final authBloc = sl<AuthBloc>();
      final isAuthenticated = authBloc.state.status == AuthStatus.authenticated;
      final location = state.matchedLocation;
      final isPublic = location == '/login' || location == '/forgot-password';

      // If not authenticated, gate everything except public routes.
      if (!isAuthenticated && !isPublic) return '/login';

      // If authenticated and on login, redirect based on store count.
      if (isAuthenticated && location == '/login') {
        final user = authBloc.state.user;
        if (user != null && user.storeIds.isNotEmpty) {
          if (user.storeIds.length > 1) return '/store-selection';
          return '/store/${user.storeIds.first}';
        }
      }

      return null;
    },
    routes: [
      // ---------------------------------------------------------------
      // Public / pre-auth routes
      // ---------------------------------------------------------------
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
            path: '/search',
            name: 'search',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchTabPage(),
            ),
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
        path: '/settings',
        name: 'settings',
        builder: (context, state) => BlocProvider.value(
          value: sl<AuthBloc>(),
          child: const SettingsPage(),
        ),
      ),
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
