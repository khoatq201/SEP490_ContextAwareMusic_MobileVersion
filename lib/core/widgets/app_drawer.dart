import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';
import '../theme/cams_theme_tokens.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    return Drawer(
      backgroundColor: tokens.bgContainer,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState.user;

          return Column(
            children: [
              // User Header
              _buildUserHeader(context, user),

              // Store Switcher (if user has multiple stores)
              if (user != null && user.storeIds.length > 1)
                _buildStoreSwitcher(context, user.storeIds),

              const Divider(height: 1),

              // Navigation Items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildNavItem(
                      context: context,
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      route: '/store/${user?.storeIds.first ?? ''}',
                      isSelected: currentRoute.startsWith('/store/'),
                    ),
                    _buildNavItem(
                      context: context,
                      icon: Icons.queue_music,
                      title: 'Playlists',
                      route: '/playlists',
                      isSelected: currentRoute == '/playlists',
                    ),
                    _buildNavItem(
                      context: context,
                      icon: Icons.settings,
                      title: 'Settings',
                      route: '/settings',
                      isSelected: currentRoute == '/settings',
                    ),
                    _buildNavItem(
                      context: context,
                      icon: Icons.person,
                      title: 'Profile',
                      route: '/profile',
                      isSelected: currentRoute == '/profile',
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Logout
              _buildLogoutButton(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context, user) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        AppDimensions.spacingXl + 24, // Account for status bar
        AppDimensions.spacingLg,
        AppDimensions.spacingLg,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            tokens.brandPrimary,
            tokens.brandPrimaryHover,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 36,
            backgroundColor: tokens.bgContainer,
            child: user?.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      user!.avatarUrl!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: 40,
                          color: colorScheme.primary,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.person,
                    size: 40,
                    color: colorScheme.primary,
                  ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),

          // Name
          Text(
            user?.fullName ?? user?.username ?? 'User',
            style: AppTypography.titleLarge.copyWith(
              color: tokens.textOnAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),

          // Email
          Text(
            user?.email ?? '',
            style: AppTypography.bodySmall.copyWith(
              color: tokens.textOnAccent.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),

          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingSm,
              vertical: AppDimensions.spacingXs,
            ),
            decoration: BoxDecoration(
              color: tokens.textOnAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Text(
              (user?.role ?? 'staff').toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: tokens.textOnAccent,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreSwitcher(BuildContext context, List<String> storeIds) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm,
      ),
      color: tokens.bgElevated,
      child: Row(
        children: [
          Icon(
            Icons.store,
            size: 20,
            color: tokens.textSecondary,
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Text(
              '${storeIds.length} Stores',
              style: AppTypography.labelSmall.copyWith(
                color: tokens.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/store-selection');
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingSm,
              ),
            ),
            child: Text(
              'Switch',
              style: AppTypography.labelSmall.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String route,
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? colorScheme.primary : tokens.textSecondary,
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          color: isSelected ? colorScheme.primary : tokens.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: colorScheme.primary.withValues(alpha: 0.12),
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (!isSelected) {
          context.go(route);
        }
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    final tokens = context.camsTokens;
    return ListTile(
      leading: Icon(
        Icons.logout,
        color: tokens.error,
      ),
      title: Text(
        'Logout',
        style: AppTypography.bodyMedium.copyWith(
          color: tokens.error,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () => _handleLogout(context),
    );
  }

  void _handleLogout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop(); // Close drawer
                context.read<AuthBloc>().add(const LogoutRequested());
                context.go('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
