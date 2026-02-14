import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDarkPrimary
          : AppColors.backgroundPrimary,
      drawer: const AppDrawer(currentRoute: '/profile'),
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Navigate to edit profile
            },
            tooltip: 'Edit Profile',
          ),
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState.user;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.spacingMd),
            child: Column(
              children: [
                // Profile Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppDimensions.spacingLg),
                    child: Column(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.primaryOrangePale,
                          child: user?.avatarUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    user!.avatarUrl!,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: AppColors.primaryOrange,
                                      );
                                    },
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: AppColors.primaryOrange,
                                ),
                        ),
                        const SizedBox(height: AppDimensions.spacingMd),

                        // Name
                        Text(
                          user?.fullName ?? user?.username ?? 'User',
                          style: AppTypography.headlineMedium.copyWith(
                            color: isDark
                                ? AppColors.textDarkPrimary
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingXs),

                        // Role Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.spacingMd,
                            vertical: AppDimensions.spacingXs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryOrangePale,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusSm),
                          ),
                          child: Text(
                            (user?.role ?? 'staff').toUpperCase(),
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primaryOrange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLg),

                // Personal Information
                _buildSectionHeader('Personal Information'),
                Card(
                  child: Column(
                    children: [
                      _buildInfoTile(
                        icon: Icons.person,
                        label: 'Username',
                        value: user?.username ?? '-',
                      ),
                      const Divider(height: 1),
                      _buildInfoTile(
                        icon: Icons.email,
                        label: 'Email',
                        value: user?.email ?? '-',
                      ),
                      const Divider(height: 1),
                      _buildInfoTile(
                        icon: Icons.badge,
                        label: 'Full Name',
                        value: user?.fullName ?? '-',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLg),

                // Store Access
                _buildSectionHeader('Store Access'),
                Card(
                  child: Column(
                    children: [
                      _buildInfoTile(
                        icon: Icons.store,
                        label: 'Stores',
                        value: '${user?.storeIds.length ?? 0} stores',
                      ),
                      if (user?.storeIds != null && user!.storeIds.isNotEmpty)
                        ...user.storeIds.asMap().entries.map((entry) {
                          return Column(
                            children: [
                              const Divider(height: 1),
                              ListTile(
                                leading: const Icon(
                                  Icons.location_on,
                                  size: 20,
                                  color: AppColors.textSecondary,
                                ),
                                title: Text(
                                  entry.value,
                                  style: AppTypography.bodySmall,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLg),

                // Account Actions
                _buildSectionHeader('Account'),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock,
                            color: AppColors.primaryOrange),
                        title: const Text('Change Password'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Navigate to change password
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Change password feature coming soon'),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.security,
                            color: AppColors.secondaryTeal),
                        title: const Text('Security Settings'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          // TODO: Navigate to security settings
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingLg),

                // Account Info
                if (user?.lastLogin != null)
                  Text(
                    'Last login: ${_formatDate(user!.lastLogin!)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.textDarkTertiary
                          : AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
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
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: AppTypography.titleMedium.copyWith(
                color: isDark
                    ? AppColors.textDarkPrimary
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return ListTile(
          leading: Icon(icon,
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textSecondary,
              size: 20),
          title: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? AppColors.textDarkSecondary
                  : AppColors.textSecondary,
            ),
          ),
          subtitle: Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
