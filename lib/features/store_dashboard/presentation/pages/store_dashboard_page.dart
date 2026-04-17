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
import '../../../space_control/domain/entities/space.dart';
import '../../../space_control/presentation/bloc/music_control_bloc.dart';
import '../../../space_control/presentation/bloc/music_control_event.dart';
import '../../../space_control/presentation/bloc/space_monitoring_bloc.dart';
import '../../../space_control/presentation/bloc/space_monitoring_event.dart';
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
  publishConfigVersion,
  rollbackConfigVersion,
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

  bool _isValidGuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
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

    var selectedMode = currentMode;
    final selectedResult = await showDialog<StoreGovernanceMode>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Store governance mode'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: RadioGroup<StoreGovernanceMode>(
              groupValue: selectedMode,
              onChanged: (value) {
                if (value == null) return;
                setState(() => selectedMode = value);
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
          ),
          actions: [
            TextButton(
              onPressed: () => _unfocusAndPop<StoreGovernanceMode>(
                dialogContext,
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => _unfocusAndPop<StoreGovernanceMode>(
                dialogContext,
                selectedMode,
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
        mode: selectedResult,
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

  Future<void> _showPublishConfigVersionDialog(
    BuildContext context,
    Store store,
  ) async {
    final noteController = TextEditingController();
    final request = await showDialog<PublishConfigVersionRequest>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Publish store config snapshot'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: TextField(
            controller: noteController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'Why this store config snapshot is being published',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _unfocusAndPop<PublishConfigVersionRequest>(
              dialogContext,
            ),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final note = noteController.text.trim();
              _unfocusAndPop<PublishConfigVersionRequest>(
                dialogContext,
                PublishConfigVersionRequest(
                  scopeType: ConfigScopeType.store,
                  scopeId: store.id,
                  note: note.isEmpty ? null : note,
                ),
              );
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );
    await _waitForRouteTeardown();
    noteController.dispose();
    if (request == null || !context.mounted) return;

    final result = await sl<PublishConfigVersion>()(
      request: request,
    );
    if (!context.mounted) return;

    result.fold(
      (failure) => _showStoreFailure(
        context,
        failure,
        title: 'Publish config failed',
      ),
      (message) => _showStoreSnackBar(
        context,
        message.isNotEmpty ? message : 'Store config version published.',
      ),
    );
  }

  Future<void> _showRollbackConfigVersionDialog(
    BuildContext context,
    Store store,
  ) async {
    final versionController = TextEditingController();
    final noteController = TextEditingController();
    String? versionError;
    final request = await showDialog<RollbackConfigVersionRequest>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rollback store config'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: versionController,
                  autofocus: true,
                  onChanged: (_) {
                    if (versionError != null) {
                      setState(() => versionError = null);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Version ID',
                    hintText: '00000000-0000-0000-0000-000000000000',
                    helperText: 'Paste the UUID returned by publish snapshot.',
                    errorText: versionError,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    hintText: 'Why this rollback is needed',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => _unfocusAndPop<RollbackConfigVersionRequest>(
                dialogContext,
              ),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final versionId = versionController.text.trim();
                if (versionId.isEmpty) {
                  setState(() => versionError = 'Version ID is required.');
                  return;
                }
                if (!_isValidGuid(versionId)) {
                  setState(
                    () => versionError = 'Use only the published version UUID.',
                  );
                  return;
                }

                final note = noteController.text.trim();
                _unfocusAndPop<RollbackConfigVersionRequest>(
                  dialogContext,
                  RollbackConfigVersionRequest(
                    versionId: versionId,
                    note: note.isEmpty ? null : note,
                  ),
                );
              },
              child: const Text('Rollback'),
            ),
          ],
        ),
      ),
    );
    await _waitForRouteTeardown();
    versionController.dispose();
    noteController.dispose();
    if (request == null || !context.mounted) return;

    final result = await sl<RollbackConfigVersion>()(request: request);
    if (!context.mounted) return;

    result.fold(
      (failure) => _showStoreFailure(
        context,
        failure,
        title: 'Rollback config failed',
      ),
      (message) {
        context.read<StoreDashboardBloc>().add(
              RefreshStoreDashboard(storeId: store.id),
            );
        _showStoreSnackBar(
          context,
          message.isNotEmpty ? message : 'Store config version rolled back.',
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
                          leading: const Icon(Icons.publish_outlined),
                          title: const Text('Publish config snapshot'),
                          subtitle: const Text(
                            'Create a store-scope config version',
                          ),
                          onTap: () => Navigator.of(sheetContext).pop(
                            _StoreDashboardToolAction.publishConfigVersion,
                          ),
                        ),
                      if (canManageStore)
                        ListTile(
                          leading: const Icon(Icons.restore_outlined),
                          title: const Text('Rollback config version'),
                          subtitle: const Text(
                            'Restore from a published version ID',
                          ),
                          onTap: () => Navigator.of(sheetContext).pop(
                            _StoreDashboardToolAction.rollbackConfigVersion,
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
      case _StoreDashboardToolAction.publishConfigVersion:
        await _showPublishConfigVersionDialog(context, store);
        return;
      case _StoreDashboardToolAction.rollbackConfigVersion:
        await _showRollbackConfigVersionDialog(context, store);
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
                          childAspectRatio: 0.85,
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
