import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_typography.dart';

class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.spacingLg,
        AppDimensions.spacingXl + 24, // Account for status bar
        AppDimensions.spacingLg,
        AppDimensions.spacingLg,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryOrange,
            AppColors.primaryOrangeLight,
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
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            child: user?.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      user!.avatarUrl!,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 40,
                          color: AppColors.primaryOrange,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.person,
                    size: 40,
                    color: AppColors.primaryOrange,
                  ),
          ),
          const SizedBox(height: AppDimensions.spacingMd),

          // Name
          Text(
            user?.fullName ?? user?.username ?? 'User',
            style: AppTypography.titleLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),

          // Email
          Text(
            user?.email ?? '',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.9),
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
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Text(
              (user?.role ?? 'staff').toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingMd,
        vertical: AppDimensions.spacingSm,
      ),
      color: isDark ? AppColors.surfaceDark : AppColors.backgroundSecondary,
      child: Row(
        children: [
          Icon(
            Icons.store,
            size: 20,
            color:
                isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
          ),
          const SizedBox(width: AppDimensions.spacingSm),
          Expanded(
            child: Text(
              '${storeIds.length} Stores',
              style: AppTypography.labelSmall.copyWith(
                color: isDark
                    ? AppColors.textDarkSecondary
                    : AppColors.textSecondary,
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
                color: AppColors.primaryOrange,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? AppColors.primaryOrange
            : (isDark ? AppColors.textDarkSecondary : AppColors.textSecondary),
      ),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          color: isSelected
              ? AppColors.primaryOrange
              : (isDark ? AppColors.textDarkPrimary : AppColors.textPrimary),
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: isDark
          ? AppColors.primaryOrange.withOpacity(0.15)
          : AppColors.primaryOrangePale,
      onTap: () {
        Navigator.pop(context); // Close drawer
        if (!isSelected) {
          context.go(route);
        }
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.logout,
        color: AppColors.error,
      ),
      title: Text(
        'Logout',
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () => _handleLogout(context),
    );
  }

  void _handleLogout(BuildContext context) {
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
                backgroundColor: AppColors.error,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
