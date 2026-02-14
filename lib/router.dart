import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/presentation/pages/login_page_v2.dart';
import 'features/auth/presentation/pages/forgot_password_page.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
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
import 'features/store_selection/presentation/pages/store_selection_page.dart';
import 'features/store_selection/presentation/bloc/store_selection_bloc.dart';
import 'core/presentation/component_showcase_page.dart';
import 'core/presentation/theme_showcase_page.dart';
import 'core/presentation/theme_demo_page.dart';
import 'injection_container.dart';

class AppRouter {
  static GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) {
      final authBloc = sl<AuthBloc>();
      final isAuthenticated = authBloc.state.status == AuthStatus.authenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isForgotPassword = state.matchedLocation == '/forgot-password';

      // If not authenticated and trying to access protected routes, redirect to login
      if (!isAuthenticated && !isLoggingIn && !isForgotPassword) {
        return '/login';
      }

      // If authenticated and on login page, redirect based on store count
      if (isAuthenticated && isLoggingIn) {
        final user = authBloc.state.user;
        if (user != null && user.storeIds.isNotEmpty) {
          // If user has multiple stores, redirect to store selection
          if (user.storeIds.length > 1) {
            return '/store-selection';
          }
          // If user has only one store, go directly to dashboard
          return '/store/${user.storeIds.first}';
        }
      }

      return null; // No redirect
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) {
          return BlocProvider.value(
            value: sl<AuthBloc>(),
            child: const LoginPageV2(),
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) {
          return BlocProvider.value(
            value: sl<AuthBloc>(),
            child: const ForgotPasswordPage(),
          );
        },
      ),
      GoRoute(
        path: '/store-selection',
        name: 'store-selection',
        builder: (context, state) {
          return MultiBlocProvider(
            providers: [
              BlocProvider.value(
                value: sl<AuthBloc>(),
              ),
              BlocProvider(
                create: (_) => sl<StoreSelectionBloc>(),
              ),
            ],
            child: const StoreSelectionPage(),
          );
        },
      ),
      GoRoute(
        path: '/store/:storeId',
        name: 'store-dashboard',
        builder: (context, state) {
          final storeId = state.pathParameters['storeId']!;

          return MultiBlocProvider(
            providers: [
              BlocProvider.value(
                value: sl<AuthBloc>(),
              ),
              BlocProvider(
                create: (_) => sl<StoreDashboardBloc>()
                  ..add(LoadStoreDashboard(storeId: storeId)),
              ),
            ],
            child: StoreDashboardPage(storeId: storeId),
          );
        },
      ),
      GoRoute(
        path: '/space',
        name: 'space-detail',
        builder: (context, state) {
          // Extract parameters from query or state extra
          final storeId = state.uri.queryParameters['storeId'] ?? 'store-1';
          final spaceId = state.uri.queryParameters['spaceId'] ?? 'space-1';

          return MultiBlocProvider(
            providers: [
              BlocProvider.value(
                value: sl<AuthBloc>(),
              ),
              BlocProvider(
                create: (_) => sl<SpaceMonitoringBloc>(),
              ),
              BlocProvider(
                create: (_) => sl<MusicControlBloc>(),
              ),
              BlocProvider(
                create: (_) => sl<OfflineLibraryBloc>(),
              ),
            ],
            child: SpaceDetailPage(
              storeId: storeId,
              spaceId: spaceId,
            ),
          );
        },
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) {
          return BlocProvider.value(
            value: sl<AuthBloc>(),
            child: const SettingsPage(),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) {
          return BlocProvider.value(
            value: sl<AuthBloc>(),
            child: const ProfilePage(),
          );
        },
      ),
      GoRoute(
        path: '/playlists',
        name: 'playlists',
        builder: (context, state) {
          return BlocProvider.value(
            value: sl<AuthBloc>(),
            child: const PlaylistManagementPage(),
          );
        },
      ),
      GoRoute(
        path: '/showcase',
        name: 'component-showcase',
        builder: (context, state) {
          return const ComponentShowcasePage();
        },
      ),
      GoRoute(
        path: '/theme',
        name: 'theme-showcase',
        builder: (context, state) {
          return const CAMSThemeShowcase();
        },
      ),
      GoRoute(
        path: '/theme-demo',
        name: 'theme-demo',
        builder: (context, state) {
          return const ThemeDemoPage();
        },
      ),
    ],
    errorBuilder: (context, state) {
      return const Scaffold(
        body: Center(
          child: Text('Page not found'),
        ),
      );
    },
  );
}
