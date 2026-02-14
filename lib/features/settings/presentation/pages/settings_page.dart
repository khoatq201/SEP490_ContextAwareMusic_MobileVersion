import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDarkPrimary
          : AppColors.backgroundPrimary,
      drawer: const AppDrawer(currentRoute: '/settings'),
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          return ListView(
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            children: [
              // Appearance Section
              _buildSectionHeader('Appearance'),
              Card(
                child: Column(
                  children: [
                    _buildThemeToggle(context),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),

              // Notifications Section
              _buildSectionHeader('Notifications'),
              Card(
                child: Column(
                  children: [
                    _buildSwitchTile(
                      title: 'Push Notifications',
                      subtitle: 'Receive alerts and updates',
                      value: true,
                      onChanged: (value) {
                        // TODO: Implement notification toggle
                      },
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      title: 'Space Alerts',
                      subtitle: 'Get notified about space events',
                      value: true,
                      onChanged: (value) {
                        // TODO: Implement space alerts toggle
                      },
                    ),
                    const Divider(height: 1),
                    _buildSwitchTile(
                      title: 'Music Updates',
                      subtitle: 'Notifications for playlist changes',
                      value: false,
                      onChanged: (value) {
                        // TODO: Implement music updates toggle
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),

              // Storage Section
              _buildSectionHeader('Storage'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.folder,
                          color: AppColors.primaryOrange),
                      title: const Text('Cache Size'),
                      subtitle: const Text('0 MB'),
                      trailing: TextButton(
                        onPressed: () {
                          // TODO: Clear cache
                        },
                        child: const Text('Clear'),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.music_note,
                          color: AppColors.secondaryTeal),
                      title: const Text('Downloaded Playlists'),
                      subtitle: const Text('0 playlists'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navigate to playlist management
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),

              // Account Section
              _buildSectionHeader('Account'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person,
                          color: AppColors.primaryOrange),
                      title: Text(authState.user?.username ?? 'User'),
                      subtitle: Text(authState.user?.email ?? ''),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Navigate to profile
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.store,
                          color: AppColors.secondaryTeal),
                      title: const Text('Stores'),
                      subtitle: Text(
                          '${authState.user?.storeIds.length ?? 0} stores'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Navigate to store selection
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDimensions.spacingLg),

              // About Section
              _buildSectionHeader('About'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.info,
                          color: AppColors.textSecondary),
                      title: const Text('Version'),
                      subtitle: const Text('1.0.0'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description,
                          color: AppColors.textSecondary),
                      title: const Text('Terms & Privacy'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Show terms
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingSm,
            vertical: AppDimensions.spacingSm,
          ),
          child: Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color:
                  isDark ? AppColors.textDarkPrimary : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeToggle(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: AppColors.primaryOrange,
      ),
      title: const Text('Dark Mode'),
      subtitle: Text(
        'Toggle dark/light theme',
        style: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
        ),
      ),
      trailing: Switch(
        value: themeProvider.isDarkMode,
        onChanged: (value) {
          themeProvider.toggleTheme();
        },
        activeColor: AppColors.primaryOrange,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ListTile(
          title: Text(title),
          subtitle: Text(
            subtitle,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textSecondary,
            ),
          ),
          trailing: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryOrange,
          ),
        );
      },
    );
  }
}
