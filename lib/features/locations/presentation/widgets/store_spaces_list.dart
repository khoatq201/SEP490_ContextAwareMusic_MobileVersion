import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/pagination_result.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/presentation/shell_layout_metrics.dart';
import '../../../../core/session/session_cubit.dart';
import '../../domain/entities/location_space.dart';
import 'space_management_tile.dart';

class StoreSpacesList extends StatelessWidget {
  final PaginationResult<LocationSpace> spaces;

  const StoreSpacesList({super.key, required this.spaces});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final hasMiniPlayer =
        context.select((PlayerBloc bloc) => bloc.state.hasTrack);
    final bottomPadding = ShellLayoutMetrics.reservedBottom(
      context,
      hasMiniPlayer: hasMiniPlayer,
      extra: 24,
    );

    if (spaces.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_outlined,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              'No spaces found in this store.',
              style: GoogleFonts.inter(
                  color: AppColors.textTertiary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
      itemCount: spaces.items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surfaceDark
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderLight.withAlpha(120)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.currentStore?.name ?? 'Current Store',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textDarkPrimary
                        : AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  session.currentSpace != null
                      ? 'Targeting ${session.currentSpace!.name}'
                      : 'Choose a space below to switch your active target.',
                  style: GoogleFonts.inter(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textDarkSecondary
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return SpaceManagementTile(space: spaces.items[index - 1]);
      },
    );
  }
}
