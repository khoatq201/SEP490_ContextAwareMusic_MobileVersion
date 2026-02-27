import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/location_space.dart';
import 'space_management_tile.dart';

class StoreSpacesList extends StatelessWidget {
  final List<LocationSpace> spaces;

  const StoreSpacesList({super.key, required this.spaces});

  @override
  Widget build(BuildContext context) {
    if (spaces.isEmpty) {
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: spaces.length,
      itemBuilder: (context, index) =>
          SpaceManagementTile(space: spaces[index]),
    );
  }
}
