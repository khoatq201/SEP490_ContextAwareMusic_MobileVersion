import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/player/player_event.dart';
import '../../../../core/player/space_info.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../space_control/presentation/bloc/music_control_bloc.dart';
import '../../../space_control/presentation/bloc/music_control_event.dart';
import '../../../space_control/presentation/bloc/space_monitoring_bloc.dart';
import '../../../space_control/presentation/bloc/space_monitoring_event.dart';
import '../bloc/store_dashboard_bloc.dart';
import '../bloc/store_dashboard_event.dart';
import '../bloc/store_dashboard_state.dart';
import '../widgets/store_info_card.dart';
import '../widgets/space_grid_card.dart';

class StoreDashboardPage extends StatelessWidget {
  final String storeId;

  const StoreDashboardPage({
    super.key,
    required this.storeId,
  });

  void _showAccountSheet(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? AppColors.backgroundDarkSecondary : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Profile header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingLg,
                  vertical: AppDimensions.spacingMd,
                ),
                child: Row(
                  children: [
                    _buildAvatar(user?.avatarUrl, user?.username, size: 52),
                    const SizedBox(width: AppDimensions.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? user?.username ?? 'User',
                            style: AppTypography.titleMedium.copyWith(
                              color: isDark
                                  ? AppColors.textDarkPrimary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? '',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark
                                  ? AppColors.textDarkSecondary
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (user?.role != null)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primaryOrange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                user!.role.toUpperCase(),
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primaryOrange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Switch Store
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.store_outlined,
                      color: Colors.blue, size: 22),
                ),
                title: Text(
                  'Switch Store',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark
                        ? AppColors.textDarkPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Select a different store',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  context.go('/store-selection');
                },
              ),

              // Logout
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.logout_outlined,
                      color: AppColors.error, size: 22),
                ),
                title: Text(
                  'Logout',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Sign out of your account',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textSecondary,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  context.read<AuthBloc>().add(const LogoutRequested());
                },
              ),

              const SizedBox(height: AppDimensions.spacingMd),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String? avatarUrl, String? username, {double size = 36}) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: AppColors.primaryOrange.withOpacity(0.2),
      );
    }
    final initials = _getInitials(username);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primaryOrange.withOpacity(0.85),
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = context.read<AuthBloc>().state;
    final hasMultipleStores = (authState.user?.storeIds.length ?? 0) > 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (hasMultipleStores) {
          // Go back to store selection
          context.go('/store-selection');
        } else {
          // Only one store — show exit dialog
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Thoát ứng dụng'),
              content: const Text('Bạn có muốn thoát ứng dụng không?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Không'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Thoát'),
                ),
              ],
            ),
          );
          if (shouldExit == true && context.mounted) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDarkPrimary
          : AppColors.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Store Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<StoreDashboardBloc>().add(
                    RefreshStoreDashboard(storeId: storeId),
                  );
            },
            tooltip: 'Refresh',
          ),
          // User avatar → account sheet
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _showAccountSheet(context),
                  child: _buildAvatar(
                    authState.user?.avatarUrl,
                    authState.user?.username,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<StoreDashboardBloc, StoreDashboardState>(
        listener: (context, state) {
          if (state.status == StoreDashboardStatus.loaded && state.store != null) {
            final sessionCubit = context.read<SessionCubit>();
            if (sessionCubit.state.currentStore?.id != state.store!.id) {
               sessionCubit.changeStore(state.store!);
            }
          }
          if (state.status == StoreDashboardStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.status == StoreDashboardStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.status == StoreDashboardStatus.error &&
              state.store == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  Text(
                    state.errorMessage ?? 'An error occurred',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark
                          ? AppColors.textDarkSecondary
                          : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<StoreDashboardBloc>().add(
                            LoadStoreDashboard(storeId: storeId),
                          );
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state.store == null) {
            return const Center(
              child: Text('No store data available'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<StoreDashboardBloc>().add(
                    RefreshStoreDashboard(storeId: storeId),
                  );
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppDimensions.spacingMd),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store Info Card
                  StoreInfoCard(store: state.store!),

                  const SizedBox(height: AppDimensions.spacingLg),

                  // Spaces Section
                  Text(
                    'Spaces',
                    style: AppTypography.titleLarge.copyWith(
                      color: isDark
                          ? AppColors.textDarkPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingMd),

                  if (state.spaces.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.spacingXl),
                        child: Column(
                          children: [
                            Icon(
                              Icons.space_dashboard_outlined,
                              size: 64,
                              color: isDark
                                  ? AppColors.textDarkTertiary
                                  : AppColors.textTertiary,
                            ),
                            const SizedBox(height: AppDimensions.spacingMd),
                            Text(
                              'No spaces available',
                              style: AppTypography.bodyMedium.copyWith(
                                color: isDark
                                    ? AppColors.textDarkSecondary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: AppDimensions.spacingMd,
                        mainAxisSpacing: AppDimensions.spacingMd,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: state.spaces.length,
                      itemBuilder: (context, index) {
                        final space = state.spaces[index];
                        return SpaceGridCard(
                          space: space,
                          onTap: () {
                            // 1. Start global space monitoring
                            context.read<SpaceMonitoringBloc>().add(
                                  StartMonitoring(
                                    storeId: storeId,
                                    spaceId: space.id,
                                  ),
                                );
                            // 2. Start global music monitoring
                            context.read<MusicControlBloc>().add(
                                  StartMusicMonitoring(
                                    storeId: storeId,
                                    spaceId: space.id,
                                  ),
                                );
                            // 3. Update global player context (name + space list)
                            context.read<PlayerBloc>().add(
                                  PlayerContextUpdated(
                                    storeId: storeId,
                                    spaceId: space.id,
                                    spaceName: space.name,
                                    availableSpaces: state.spaces
                                        .map((s) => SpaceInfo(
                                              id: s.id,
                                              storeId: s.storeId,
                                              name: s.name,
                                              isOnline: s.isOnline,
                                              currentMood: s.currentMood,
                                            ))
                                        .toList(),
                                  ),
                                );
                            // 4. Go directly to the Now Playing tab
                            context.go('/now-playing');
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    ),
    );
  }
}
