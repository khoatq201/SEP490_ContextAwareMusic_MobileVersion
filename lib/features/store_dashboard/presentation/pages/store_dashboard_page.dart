import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/enums/space_type_enum.dart';
import '../../../../core/enums/user_role.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/player/player_bloc.dart';
import '../../../../core/player/player_event.dart';
import '../../../../core/player/space_info.dart';
import '../../../../core/presentation/app_feedback.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/app_feedback_presenter.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/session/session_cubit.dart';
import '../../../config_governance/domain/entities/config_governance_enums.dart';
import '../../../config_governance/domain/entities/config_value_upsert_request.dart';
import '../../../config_governance/domain/usecases/config_governance_usecases.dart';
import '../../../config_governance/presentation/widgets/config_governance_sheet.dart';
import '../../../cams/presentation/bloc/cams_playback_bloc.dart';
import '../../../cams/presentation/bloc/cams_playback_event.dart';
import '../../../space_control/domain/entities/space.dart';
import '../../../space_control/presentation/bloc/space_monitoring_bloc.dart';
import '../../../space_control/presentation/bloc/space_monitoring_event.dart';
import '../../../space_schedule/data/datasources/space_schedule_remote_datasource.dart';
import '../../../space_schedule/domain/entities/schedule_music_item.dart';
import '../../../space_schedule/domain/entities/schedule_source.dart';
import '../../../space_schedule/presentation/widgets/brand_schedule_editor_sheet.dart';
import '../../../store_selection/domain/entities/store_summary.dart';
import '../../../store_selection/domain/usecases/get_user_stores.dart';
import '../../../music_policy/data/models/fuzzy_override_profile_request.dart';
import '../../../music_policy/presentation/widgets/fuzzy_override_editor_sheet.dart';
import '../../../playlists/data/datasources/playlist_remote_datasource.dart';
import '../../data/datasources/store_remote_datasource.dart';
import '../../domain/entities/store.dart';
import '../../domain/usecases/store_mutation_usecases.dart';
import '../bloc/store_dashboard_bloc.dart';
import '../bloc/store_dashboard_event.dart';
import '../bloc/store_dashboard_state.dart';
import '../widgets/store_info_card.dart';
import '../widgets/space_grid_card.dart';

enum _StoreDashboardToolAction {
  refresh,
  storeGovernance,
  governanceMode,
  strictSyncStores,
  brandSchedule,
  musicPolicy,
}

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
                                color: AppColors.primaryOrange.withValues(
                                  alpha: 0.15,
                                ),
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

              // Switch Store — only for BrandManager / SystemAdmin
              if (user != null && (user.isBrandManager || user.isSystemAdmin))
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
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
                    color: AppColors.error.withValues(alpha: 0.12),
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
        backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.2),
      );
    }
    final initials = _getInitials(username);
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.primaryOrange.withValues(alpha: 0.85),
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

  void _showStoreSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    AppFeedbackPresenter.show(
      context,
      isError
          ? AppFeedback.error(message, title: 'Request failed')
          : AppFeedback.success(message),
    );
  }

  void _showStoreFailure(
    BuildContext context,
    Failure failure, {
    String title = 'Request failed',
  }) {
    AppFeedbackPresenter.show(
      context,
      AppFeedback.fromFailure(
        failure,
        title: title,
      ),
    );
  }

  void _unfocusAndPop<T>(BuildContext context, [T? result]) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop<T>(result);
  }

  Future<void> _waitForRouteTeardown() async {
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _showEditStoreDialog(
    BuildContext context,
    Store store,
  ) async {
    final nameController = TextEditingController(text: store.name);
    final contactController = TextEditingController(text: store.contactNumber);
    final addressController = TextEditingController(text: store.address);
    final cityController = TextEditingController(text: store.city);
    final districtController = TextEditingController(text: store.district);

    final request = await showDialog<StoreMutationRequest>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Store'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Store name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(labelText: 'Contact number'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cityController,
                decoration: const InputDecoration(labelText: 'City'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: districtController,
                decoration: const InputDecoration(labelText: 'District'),
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
                _showStoreSnackBar(
                  context,
                  'Store name is required.',
                  isError: true,
                );
                return;
              }
              Navigator.pop(
                dialogContext,
                StoreMutationRequest(
                  name: name,
                  contactNumber: contactController.text.trim().isEmpty
                      ? null
                      : contactController.text.trim(),
                  address: addressController.text.trim().isEmpty
                      ? null
                      : addressController.text.trim(),
                  city: cityController.text.trim().isEmpty
                      ? null
                      : cityController.text.trim(),
                  district: districtController.text.trim().isEmpty
                      ? null
                      : districtController.text.trim(),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (request == null) return;

    final result = await sl<UpdateStore>()(store.id, request);
    if (!context.mounted) return;

    result.fold(
      (failure) => _showStoreFailure(context, failure, title: 'Update failed'),
      (success) {
        context
            .read<StoreDashboardBloc>()
            .add(LoadStoreDashboard(storeId: storeId));
        _showStoreSnackBar(
          context,
          success.message ?? 'Store updated successfully.',
        );
      },
    );
  }

  Future<void> _toggleStoreStatus(BuildContext context, Store store) async {
    final result = await sl<ToggleStoreStatus>()(store.id);
    if (!context.mounted) return;

    result.fold(
      (failure) =>
          _showStoreFailure(context, failure, title: 'Status update failed'),
      (success) {
        context
            .read<StoreDashboardBloc>()
            .add(LoadStoreDashboard(storeId: storeId));
        _showStoreSnackBar(
          context,
          success.message ?? 'Store status updated successfully.',
        );
      },
    );
  }

  Future<void> _deleteStore(BuildContext context, Store store) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete store?'),
        content: Text(
          'This will remove "${store.name}" if backend business rules allow it.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final result = await sl<DeleteStore>()(store.id);
    if (!context.mounted) return;

    result.fold(
      (failure) => _showStoreFailure(context, failure, title: 'Delete failed'),
      (success) {
        _showStoreSnackBar(
          context,
          success.message ?? 'Store deleted successfully.',
        );
        context.go('/store-selection');
      },
    );
  }

  Future<List<FuzzyOverridePlaylistOption>> _loadStorePlaylistOptions(
    Store store,
  ) async {
    final response = await sl<PlaylistRemoteDataSource>().getPlaylists(
      page: 1,
      pageSize: 100,
      storeId: store.id,
    );
    return response.items
        .map(
          (playlist) => FuzzyOverridePlaylistOption(
            id: playlist.id,
            label: playlist.name,
          ),
        )
        .toList(growable: false);
  }

  Future<List<ScheduleMusicItem>> _loadBrandScheduleMusicCatalog(
    Store store,
  ) async {
    final response = await sl<PlaylistRemoteDataSource>().getPlaylists(
      page: 1,
      pageSize: 100,
      brandId: store.brandId,
    );
    return response.items
        .map(
          (playlist) => ScheduleMusicItem(
            id: playlist.id,
            title: playlist.name,
            artist: playlist.storeName ?? 'Brand playlist',
            collection: playlist.moodName,
            artworkLabel: playlist.name,
            primaryHex: '#335C67',
            secondaryHex: '#2A9D8F',
          ),
        )
        .toList(growable: false);
  }

  Future<void> _showBrandScheduleEditorSheet(
    BuildContext context,
    Store store,
  ) async {
    List<ScheduleMusicItem> musicCatalog;
    try {
      musicCatalog = await _loadBrandScheduleMusicCatalog(store);
    } catch (error) {
      if (!context.mounted) return;
      _showStoreSnackBar(
        context,
        'Failed to load playlists for brand schedule: $error',
        isError: true,
      );
      return;
    }
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BrandScheduleEditorSheet(
        brandId: store.brandId,
        musicCatalog: musicCatalog,
        remoteDataSource: sl<SpaceScheduleRemoteDataSource>(),
      ),
    );

    if (!context.mounted) return;
    context.read<StoreDashboardBloc>().add(
          RefreshStoreDashboard(storeId: store.id),
        );
  }

  Future<void> _showStrictSyncStoresSheet(
    BuildContext context,
    Store store,
  ) async {
    final storesResult = await sl<GetUserStores>()();
    if (!context.mounted) return;

    final stores = storesResult.fold<List<StoreSummary>?>(
      (failure) {
        _showStoreFailure(
          context,
          failure,
          title: 'Strict Sync stores unavailable',
        );
        return null;
      },
      (stores) => stores,
    );
    if (stores == null || stores.isEmpty) return;

    final selection = await showModalBottomSheet<_StrictSyncSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _StrictSyncStoresSheet(
        brandId: store.brandId,
        stores: stores,
        currentStoreId: store.id,
      ),
    );
    if (selection == null || !context.mounted) return;

    final currentlyStrict = stores
        .where((item) => item.governanceMode == StoreGovernanceMode.strictSync)
        .map((item) => item.id)
        .toSet();
    final selectedIds = selection.storeIds.toList(growable: false);
    final releasedIds = currentlyStrict
        .where((storeId) => !selection.storeIds.contains(storeId))
        .toList(growable: false);

    final setMode = sl<SetStoreGovernanceMode>();
    if (selectedIds.isNotEmpty) {
      final result = await setMode(
        request: SetStoreGovernanceModeRequest(
          storeIds: selectedIds,
          mode: StoreGovernanceMode.strictSync,
          sourceId: selection.sourceId,
        ),
      );
      if (!context.mounted) return;
      final failed = result.fold((failure) => failure, (_) => null);
      if (failed != null) {
        _showStoreFailure(
          context,
          failed,
          title: 'Strict Sync update failed',
        );
        return;
      }
    }

    if (releasedIds.isNotEmpty) {
      final result = await setMode(
        request: SetStoreGovernanceModeRequest(
          storeIds: releasedIds,
          mode: StoreGovernanceMode.freedom,
        ),
      );
      if (!context.mounted) return;
      final failed = result.fold((failure) => failure, (_) => null);
      if (failed != null) {
        _showStoreFailure(
          context,
          failed,
          title: 'Strict Sync release failed',
        );
        return;
      }
    }

    context.read<StoreDashboardBloc>().add(
          RefreshStoreDashboard(storeId: store.id),
        );
    _showStoreSnackBar(
      context,
      'Strict Sync store selection updated.',
    );
  }

  Future<void> _showStoreFuzzyOverrideSheet(
    BuildContext context,
    Store store,
  ) async {
    List<FuzzyOverridePlaylistOption> playlists;
    try {
      playlists = await _loadStorePlaylistOptions(store);
    } catch (error) {
      if (!context.mounted) return;
      _showStoreSnackBar(
        context,
        'Failed to load playlists for music policy: $error',
        isError: true,
      );
      return;
    }
    if (!context.mounted) return;

    final request = await showModalBottomSheet<FuzzyOverrideProfileRequest>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FuzzyOverrideEditorSheet(
        title: 'Store Music Policy',
        playlists: playlists,
        summary: store.fuzzyOverrideSummary,
        overrideLevel: store.fuzzyOverrideLevel,
      ),
    );

    if (request == null || !context.mounted) return;

    final result = await sl<CreateStoreFuzzyOverrideProfile>()(
      store.id,
      request,
    );
    if (!context.mounted) return;

    result.fold(
      (failure) =>
          _showStoreFailure(context, failure, title: 'Music policy failed'),
      (success) {
        context.read<StoreDashboardBloc>().add(
              RefreshStoreDashboard(storeId: store.id),
            );
        _showStoreSnackBar(
          context,
          success.message ?? 'Store music policy updated.',
        );
      },
    );
  }

  Future<void> _showStoreConfigGovernanceSheet(
    BuildContext context,
    Store store,
  ) {
    final sessionRole = context.read<SessionCubit>().state.currentRole;
    final scopedStoreId =
        sessionRole == UserRole.storeManager ? null : store.id;

    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ConfigGovernanceSheet.store(
        storeId: scopedStoreId,
        targetName: store.name,
      ),
    );
  }

  Future<StoreGovernanceMode?> _loadCurrentGovernanceMode(
    BuildContext context,
    Store store,
  ) async {
    final result =
        await context.read<StoreDashboardBloc>().getStoreDetails(store.id);
    if (!context.mounted) return null;

    return result.fold(
      (failure) {
        if (store.governanceMode != null) {
          return store.governanceMode;
        }

        _showStoreFailure(
          context,
          failure,
          title: 'Governance mode unavailable',
        );
        return null;
      },
      (freshStore) => freshStore.governanceMode ?? StoreGovernanceMode.freedom,
    );
  }

  Future<void> _showGovernanceModeDialog(
    BuildContext context,
    Store store,
  ) async {
    final currentMode = await _loadCurrentGovernanceMode(context, store);
    if (currentMode == null || !context.mounted) return;

    List<ScheduleSource> templates = const <ScheduleSource>[];
    String? templateError;
    try {
      templates = await sl<SpaceScheduleRemoteDataSource>().getBrandTemplates(
        store.brandId,
      );
    } catch (error) {
      templateError = error.toString();
    }
    if (!context.mounted) return;

    var selectedMode = currentMode;
    String? selectedSourceId;
    final selectedResult = await showDialog<_GovernanceModeSelection>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Store governance mode'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioGroup<StoreGovernanceMode>(
                    groupValue: selectedMode,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedMode = value;
                        if (selectedMode != StoreGovernanceMode.strictSync) {
                          selectedSourceId = null;
                        }
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: StoreGovernanceMode.values
                          .map(
                            (mode) => RadioListTile<StoreGovernanceMode>(
                              value: mode,
                              title: Text(mode.label),
                              subtitle: Text(mode.description),
                              contentPadding: EdgeInsets.zero,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  if (selectedMode == StoreGovernanceMode.strictSync) ...[
                    const SizedBox(height: 12),
                    _StrictSyncTemplatePicker(
                      templates: templates,
                      selectedSourceId: selectedSourceId,
                      isLoading: false,
                      errorMessage: templateError,
                      onRefresh: () async {
                        setState(() => templateError = null);
                        try {
                          final freshTemplates =
                              await sl<SpaceScheduleRemoteDataSource>()
                                  .getBrandTemplates(store.brandId);
                          if (!context.mounted) return;
                          setState(() {
                            templates = freshTemplates;
                            selectedSourceId = null;
                            templateError = null;
                          });
                        } catch (error) {
                          if (!context.mounted) return;
                          setState(() => templateError = error.toString());
                        }
                      },
                      onChanged: (value) =>
                          setState(() => selectedSourceId = value),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _unfocusAndPop<_GovernanceModeSelection>(
                dialogContext,
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _unfocusAndPop<_GovernanceModeSelection>(
                dialogContext,
                _GovernanceModeSelection(
                  mode: selectedMode,
                  sourceId: selectedMode == StoreGovernanceMode.strictSync
                      ? selectedSourceId
                      : null,
                ),
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    await _waitForRouteTeardown();
    if (selectedResult == null || !context.mounted) return;

    final result = await sl<SetStoreGovernanceMode>()(
      request: SetStoreGovernanceModeRequest(
        storeIds: [store.id],
        mode: selectedResult.mode,
        sourceId: selectedResult.sourceId,
      ),
    );
    if (!context.mounted) return;

    result.fold(
      (failure) => _showStoreFailure(
        context,
        failure,
        title: 'Governance mode failed',
      ),
      (message) {
        context.read<StoreDashboardBloc>().add(
              RefreshStoreDashboard(storeId: store.id),
            );
        _showStoreSnackBar(
          context,
          message.isNotEmpty ? message : 'Store governance mode updated.',
        );
      },
    );
  }

  String _musicPolicySummary(Store store) {
    if (store.fuzzyOverrideSummary?.hasAnyData == true) {
      return store.fuzzyOverrideLevel?.displayName ?? 'Store override active';
    }
    return 'Using brand defaults';
  }

  Future<void> _showStoreToolsSheet(
    BuildContext context, {
    required Store store,
    required bool canManageStore,
    required bool canManageMusicPolicy,
    required bool canViewGovernanceConfig,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;

    final selectedAction =
        await showModalBottomSheet<_StoreDashboardToolAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.82,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Store tools',
                        style: AppTypography.titleMedium.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        store.name,
                        style: AppTypography.bodySmall.copyWith(
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 12),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.refresh_rounded),
                        title: const Text('Refresh dashboard'),
                        subtitle: const Text('Reload store and space status'),
                        onTap: () => Navigator.of(sheetContext).pop(
                          _StoreDashboardToolAction.refresh,
                        ),
                      ),
                      if (canViewGovernanceConfig)
                        ListTile(
                          leading: const Icon(Icons.tune_rounded),
                          title: const Text('Store configuration'),
                          subtitle: const Text(
                            'Review effective config and overrides',
                          ),
                          onTap: () => Navigator.of(sheetContext).pop(
                            _StoreDashboardToolAction.storeGovernance,
                          ),
                        ),
                      if (canManageStore)
                        ListTile(
                          leading: const Icon(
                            Icons.admin_panel_settings_outlined,
                          ),
                          title: const Text('Governance mode'),
                          subtitle: const Text(
                            'Set Strict Sync, AI Mode, or Freedom',
                          ),
                          onTap: () => Navigator.of(sheetContext).pop(
                            _StoreDashboardToolAction.governanceMode,
                          ),
                        ),
                      if (canManageStore)
                        ListTile(
                          leading: const Icon(Icons.sync_alt_rounded),
                          title: const Text('Strict Sync stores'),
                          subtitle: const Text(
                            'Choose stores that must follow brand schedule',
                          ),
                          onTap: () => Navigator.of(sheetContext).pop(
                            _StoreDashboardToolAction.strictSyncStores,
                          ),
                        ),
                      if (canManageStore)
                        ListTile(
                          leading: const Icon(Icons.event_note_outlined),
                          title: const Text('Brand schedule'),
                          subtitle: const Text(
                            'Edit brand schedule sources and slots',
                          ),
                          onTap: () => Navigator.of(sheetContext).pop(
                            _StoreDashboardToolAction.brandSchedule,
                          ),
                        ),
                      if (canManageMusicPolicy)
                        ListTile(
                          leading: const Icon(Icons.library_music_outlined),
                          title: const Text('Music policy'),
                          subtitle: Text(_musicPolicySummary(store)),
                          onTap: () => Navigator.of(sheetContext).pop(
                            _StoreDashboardToolAction.musicPolicy,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedAction == null || !context.mounted) return;
    await _waitForRouteTeardown();
    if (!context.mounted) return;

    switch (selectedAction) {
      case _StoreDashboardToolAction.refresh:
        context.read<StoreDashboardBloc>().add(
              RefreshStoreDashboard(storeId: store.id),
            );
        return;
      case _StoreDashboardToolAction.storeGovernance:
        await _showStoreConfigGovernanceSheet(context, store);
        return;
      case _StoreDashboardToolAction.governanceMode:
        await _showGovernanceModeDialog(context, store);
        return;
      case _StoreDashboardToolAction.strictSyncStores:
        await _showStrictSyncStoresSheet(context, store);
        return;
      case _StoreDashboardToolAction.brandSchedule:
        await _showBrandScheduleEditorSheet(context, store);
        return;
      case _StoreDashboardToolAction.musicPolicy:
        await _showStoreFuzzyOverrideSheet(context, store);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = context.read<AuthBloc>().state;
    final user = authState.user;
    final session = context.watch<SessionCubit>().state;
    // BrandManager / SystemAdmin can switch stores; StoreManager cannot.
    final canSwitchStore =
        user != null && (user.isBrandManager || user.isSystemAdmin);
    final canManageStore = user?.isBrandManager == true;
    final canManageMusicPolicy = !session.isPlaybackDevice &&
        (session.currentRole == UserRole.brandManager ||
            session.currentRole == UserRole.storeManager);
    final canViewGovernanceConfig = canManageMusicPolicy;
    final showStoreTools =
        canManageStore || canManageMusicPolicy || canViewGovernanceConfig;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (canSwitchStore) {
          // Go back to store selection
          context.go('/store-selection');
        } else {
          // StoreManager — show exit dialog
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Exit Application'),
              content: const Text('Do you want to exit the application?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Exit'),
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
          centerTitle: true,
          leadingWidth: showStoreTools ? 108 : 60,
          leading: SizedBox(width: showStoreTools ? 108 : 60),
          title: const Text('Store Dashboard'),
          actions: [
            if (showStoreTools)
              IconButton(
                icon: const Icon(Icons.tune_rounded),
                onPressed: () {
                  final dashboardState =
                      context.read<StoreDashboardBloc>().state;
                  final store = dashboardState.store;
                  if (store == null) return;
                  _showStoreToolsSheet(
                    context,
                    store: store,
                    canManageStore: canManageStore,
                    canManageMusicPolicy: canManageMusicPolicy,
                    canViewGovernanceConfig: canViewGovernanceConfig,
                  );
                },
                tooltip: 'Store tools',
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
            if (state.status == StoreDashboardStatus.loaded &&
                state.store != null) {
              final sessionCubit = context.read<SessionCubit>();
              if (sessionCubit.state.currentStore?.id != state.store!.id) {
                sessionCubit.changeStore(state.store!);
              }
            }
            if (state.feedback != null) {
              AppFeedbackPresenter.show(context, state.feedback!);
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
              return AppErrorView(
                failure: state.failure,
                title: 'Store unavailable',
                onRetry: () => context.read<StoreDashboardBloc>().add(
                      LoadStoreDashboard(storeId: storeId),
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
                    StoreInfoCard(
                      store: state.store!,
                      onEdit: canManageStore
                          ? () => _showEditStoreDialog(context, state.store!)
                          : null,
                      onToggleStatus: canManageStore
                          ? () => _toggleStoreStatus(context, state.store!)
                          : null,
                      onDelete: canManageStore
                          ? () => _deleteStore(context, state.store!)
                          : null,
                    ),

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
                          padding:
                              const EdgeInsets.all(AppDimensions.spacingXl),
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
                          childAspectRatio: 0.78,
                        ),
                        itemCount: state.spaces.length,
                        itemBuilder: (context, index) {
                          final space = state.spaces[index];
                          return SpaceGridCard(
                            space: space,
                            onTap: () {
                              context.read<SessionCubit>().changeSpace(
                                    Space(
                                      id: space.id,
                                      name: space.name,
                                      storeId: space.storeId,
                                      type: SpaceTypeEnum.hall,
                                      status: space.isOnline
                                          ? EntityStatusEnum.active
                                          : EntityStatusEnum.inactive,
                                      currentMood: space.currentMood,
                                    ),
                                  );
                              // 1. Start global space monitoring
                              context.read<SpaceMonitoringBloc>().add(
                                    StartMonitoring(
                                      storeId: storeId,
                                      spaceId: space.id,
                                    ),
                                  );
                              // 2. Bootstrap CAMS playback for the selected space
                              context.read<CamsPlaybackBloc>().add(
                                    CamsInitPlayback(spaceId: space.id),
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

class _StrictSyncSelection {
  const _StrictSyncSelection({
    required this.storeIds,
    this.sourceId,
  });

  final Set<String> storeIds;
  final String? sourceId;
}

class _GovernanceModeSelection {
  const _GovernanceModeSelection({
    required this.mode,
    this.sourceId,
  });

  final StoreGovernanceMode mode;
  final String? sourceId;
}

class _StrictSyncStoresSheet extends StatefulWidget {
  const _StrictSyncStoresSheet({
    required this.brandId,
    required this.stores,
    required this.currentStoreId,
  });

  final String brandId;
  final List<StoreSummary> stores;
  final String currentStoreId;

  @override
  State<_StrictSyncStoresSheet> createState() => _StrictSyncStoresSheetState();
}

class _StrictSyncStoresSheetState extends State<_StrictSyncStoresSheet> {
  late final Set<String> _selectedStoreIds;
  List<ScheduleSource> _templates = const <ScheduleSource>[];
  bool _isLoadingTemplates = true;
  String? _templateError;
  String? _selectedSourceId;

  @override
  void initState() {
    super.initState();
    _selectedStoreIds = widget.stores
        .where(
            (store) => store.governanceMode == StoreGovernanceMode.strictSync)
        .map((store) => store.id)
        .toSet();
    if (_selectedStoreIds.isEmpty) {
      _selectedStoreIds.add(widget.currentStoreId);
    }
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() {
      _isLoadingTemplates = true;
      _templateError = null;
    });

    try {
      final templates =
          await sl<SpaceScheduleRemoteDataSource>().getBrandTemplates(
        widget.brandId,
      );
      if (!mounted) return;
      setState(() {
        _templates = templates;
        _selectedSourceId = null;
        _isLoadingTemplates = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _templates = const <ScheduleSource>[];
        _selectedSourceId = null;
        _isLoadingTemplates = false;
        _templateError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.86,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Strict Sync stores',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Selected stores must follow brand scheduling. Stores removed from this list are moved to Freedom mode.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: _StrictSyncTemplatePicker(
                templates: _templates,
                selectedSourceId: _selectedSourceId,
                isLoading: _isLoadingTemplates,
                errorMessage: _templateError,
                onRefresh: _loadTemplates,
                onChanged: (value) => setState(() => _selectedSourceId = value),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
                itemCount: widget.stores.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final store = widget.stores[index];
                  final selected = _selectedStoreIds.contains(store.id);
                  return CheckboxListTile(
                    value: selected,
                    title: Text(store.name),
                    subtitle: Text(
                      store.governanceMode?.label ?? 'No governance mode',
                    ),
                    secondary: store.id == widget.currentStoreId
                        ? const Icon(Icons.storefront_rounded)
                        : null,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedStoreIds.add(store.id);
                        } else {
                          _selectedStoreIds.remove(store.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        _StrictSyncSelection(
                          storeIds: Set<String>.from(_selectedStoreIds),
                          sourceId: _selectedSourceId,
                        ),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StrictSyncTemplatePicker extends StatelessWidget {
  const _StrictSyncTemplatePicker({
    required this.templates,
    required this.selectedSourceId,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
    required this.onChanged,
  });

  final List<ScheduleSource> templates;
  final String? selectedSourceId;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRefresh;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(110),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('Loading Strict Sync templates...')),
          ],
        ),
      );
    }

    if (errorMessage != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withAlpha(80),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.error.withAlpha(90)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 10),
            const Expanded(
              child:
                  Text('Cannot load templates. Strict Sync can still be set.'),
            ),
            TextButton(
              onPressed: onRefresh,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String?>(
      initialValue: selectedSourceId,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Strict Sync source template',
        helperText: 'Optional. Selected template is linked to chosen stores.',
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('Link template later'),
        ),
        ...templates.map(
          (template) => DropdownMenuItem<String?>(
            value: template.id,
            child: Text(
              template.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
