import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';
import '../widgets/space_management_tile.dart';
import '../widgets/store_spaces_list.dart';
import '../widgets/brand_locations_view.dart';

class LocationsTabPage extends StatelessWidget {
  const LocationsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDarkPrimary : AppColors.backgroundPrimary;
    final textColor =
        isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;

    // Derive role from AuthBloc (source of truth) instead of SessionCubit
    final userRole = sl<AuthBloc>().state.user?.role.toLowerCase() ?? '';
    final isBrand = userRole == 'brand_manager' || userRole == 'admin';
    // Determine header title and optional subtitle
    final storeName = session.currentStore?.name;
    final isPlayback = session.isPlaybackDevice;
    final String title;
    final String? subtitle;

    if (isPlayback) {
      title = 'Paired Space';
      subtitle = null;
    } else if (isBrand) {
      title = 'All Locations';
      subtitle = null;
    } else {
      title = 'Locations';
      subtitle = storeName;
    }

    return BlocProvider(
      create: (context) =>
          sl<LocationBloc>()..add(const LoadLocationsRequested()),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Column(
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: isDark
                        ? AppColors.textDarkSecondary
                        : AppColors.textTertiary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<LocationBloc, LocationState>(
          builder: (context, state) {
            if (state.status == LocationStatus.loading ||
                state.status == LocationStatus.initial) {
              return Center(
                child: CircularProgressIndicator(
                  color:
                      isDark ? AppColors.primaryCyan : AppColors.primaryOrange,
                ),
              );
            }

            if (state.status == LocationStatus.failure) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 40, color: AppColors.error),
                    const SizedBox(height: 12),
                    Text(
                      state.errorMessage ?? 'Cannot load locations.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: isDark
                              ? AppColors.textDarkSecondary
                              : AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<LocationBloc>()
                          .add(const LoadLocationsRequested()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // 1. Playback Device — same rich card as store/brand manager
            if (isPlayback) {
              return state.pairedSpace != null
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: SpaceManagementTile(space: state.pairedSpace!),
                    )
                  : const Center(child: Text('Device not paired correctly.'));
            }

            // 2. Brand Manager — accordion with all stores
            if (isBrand && state.brandSpaces != null) {
              return BrandLocationsView(brandSpaces: state.brandSpaces!);
            }

            // 3. Store Manager — flat list of spaces
            if (state.storeSpaces != null) {
              return StoreSpacesList(spaces: state.storeSpaces!);
            }

            return const Center(child: Text('No locations available.'));
          },
        ),
      ),
    );
  }
}
