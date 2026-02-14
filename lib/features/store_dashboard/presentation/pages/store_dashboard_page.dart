import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/app_drawer.dart';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDarkPrimary
          : AppColors.backgroundPrimary,
      drawer: AppDrawer(currentRoute: '/store/$storeId'),
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
        ],
      ),
      body: BlocConsumer<StoreDashboardBloc, StoreDashboardState>(
        listener: (context, state) {
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
                            context.go(
                                '/space?storeId=$storeId&spaceId=${space.id}');
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
    );
  }
}
