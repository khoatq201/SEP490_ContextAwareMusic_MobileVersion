import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/enums/space_type_enum.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../data/datasources/location_remote_datasource.dart';
import '../../domain/usecases/location_usecases.dart';
import '../bloc/location_bloc.dart';
import '../bloc/location_event.dart';
import '../bloc/location_state.dart';
import '../widgets/space_management_tile.dart';
import '../widgets/store_spaces_list.dart';
import '../widgets/brand_locations_view.dart';

class LocationsTabPage extends StatelessWidget {
  const LocationsTabPage({super.key});

  Future<void> _showCreateSpaceDialog(BuildContext context) async {
    final session = context.read<SessionCubit>().state;
    final canManageSpaces = !session.isPlaybackDevice &&
        (session.currentRole == UserRole.brandManager ||
            session.currentRole == UserRole.storeManager);
    if (!canManageSpaces) {
      _showSnackBar(context, 'Your role cannot create spaces.', isError: true);
      return;
    }

    final locationState = context.read<LocationBloc>().state;
    final storeId = locationState.selectedStoreId ?? session.currentStore?.id;
    if (storeId == null || storeId.isEmpty) {
      _showSnackBar(
        context,
        'Select a store before creating a space.',
        isError: true,
      );
      return;
    }

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    var selectedType = SpaceTypeEnum.hall;

    final request = await showDialog<SpaceMutationRequest>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Create Space'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Space name',
                        hintText: 'Eg. Counter Area A',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<SpaceTypeEnum>(
                      initialValue: selectedType,
                      items: SpaceTypeEnum.values
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setDialogState(() => selectedType = value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Space type',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description (optional)',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      _showSnackBar(
                        context,
                        'Space name is required.',
                        isError: true,
                      );
                      return;
                    }
                    Navigator.pop(
                      dialogContext,
                      SpaceMutationRequest(
                        storeId: storeId,
                        name: name,
                        type: selectedType.value,
                        description: descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    if (request == null) return;

    final result = await sl<CreateSpace>()(request);
    if (!context.mounted) return;

    result.fold(
      (failure) => _showSnackBar(context, failure.message, isError: true),
      (success) {
        context.read<LocationBloc>().add(const LoadLocationsRequested());
        _showSnackBar(
          context,
          success.message ?? 'Space created successfully.',
        );
      },
    );
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionCubit>().state;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? AppColors.backgroundDarkPrimary : AppColors.backgroundPrimary;
    final textColor =
        isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;

    final authUser = sl<AuthBloc>().state.user;
    final isBrand =
        authUser?.isBrandManager == true || authUser?.isSystemAdmin == true;
    // Determine header title and optional subtitle
    final storeName = session.currentStore?.name;
    final isPlayback = session.isPlaybackDevice;
    final canManageSpaces = !isPlayback &&
        (session.currentRole == UserRole.brandManager ||
            session.currentRole == UserRole.storeManager);
    final String title;
    final String? subtitle;

    if (isPlayback) {
      title = 'Paired Space';
      subtitle = session.currentSpace?.name;
    } else if (isBrand) {
      title = 'Brand Spaces';
      subtitle = session.currentSpace != null
          ? 'Targeting ${session.currentSpace!.name}'
          : 'Track spaces across your stores';
    } else {
      title = 'Store Spaces';
      subtitle = session.currentSpace != null
          ? '${storeName ?? 'Current store'} · Targeting ${session.currentSpace!.name}'
          : storeName;
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
          actions: [
            if (canManageSpaces)
              Builder(
                builder: (scopedContext) => IconButton(
                  tooltip: 'Create space',
                  icon: const Icon(Icons.add_business_rounded),
                  onPressed: () => _showCreateSpaceDialog(scopedContext),
                ),
              ),
          ],
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
              return BrandLocationsView(
                brandSpaces: state.brandSpaces!,
                storeNamesById: state.storeNamesById ?? const {},
              );
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
