import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/cams_theme_tokens.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../core/widgets/cams_skeleton.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../config_governance/domain/entities/config_governance_enums.dart';
import '../../../config_governance/domain/entities/config_value_upsert_request.dart';
import '../../../config_governance/domain/usecases/config_governance_usecases.dart';
import '../../../playlists/data/datasources/playlist_remote_datasource.dart';
import '../../../space_schedule/data/datasources/space_schedule_remote_datasource.dart';
import '../../../space_schedule/domain/entities/schedule_music_item.dart';
import '../../../space_schedule/domain/entities/schedule_source.dart';
import '../../../space_schedule/presentation/widgets/brand_schedule_editor_sheet.dart';
import '../bloc/store_selection_bloc.dart';
import '../bloc/store_selection_event.dart';
import '../bloc/store_selection_state.dart';
import '../../domain/entities/brand_detail.dart';
import '../../domain/entities/brand_update_request.dart';
import '../../domain/entities/store_summary.dart';
import '../../domain/usecases/update_brand_detail.dart';

class StoreSelectionPage extends StatefulWidget {
  const StoreSelectionPage({super.key});

  @override
  State<StoreSelectionPage> createState() => _StoreSelectionPageState();
}

class _StoreSelectionPageState extends State<StoreSelectionPage> {
  final _searchController = TextEditingController();
  final Set<String> _selectedStoreIds = <String>{};
  final Map<String, StoreGovernanceMode> _knownStoreGovernanceModes =
      <String, StoreGovernanceMode>{};
  bool _isBulkSelectionMode = false;
  bool _isApplyingBulkMode = false;

  @override
  void initState() {
    super.initState();
    // Load stores — backend filters by JWT token (no storeIds needed)
    context.read<StoreSelectionBloc>().add(
          LoadUserStores(
            preferredBrandId: context.read<AuthBloc>().state.user?.brandId,
          ),
        );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final authUser = context.watch<AuthBloc>().state.user;
    final isStoreManager = authUser?.isStoreManager == true;
    final canUseBulkGovernance = authUser?.isBrandManager == true;
    final canManageBrandSchedule =
        authUser?.isBrandManager == true || authUser?.isSystemAdmin == true;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_isBulkSelectionMode) {
          _toggleBulkSelectionMode(enabled: false);
          return;
        }
        // Show logout confirmation instead of exiting
        _showLogoutDialog(context);
      },
      child: Scaffold(
        backgroundColor: tokens.bgBase,
        appBar: null,
        body: BlocConsumer<StoreSelectionBloc, StoreSelectionState>(
          listener: (context, state) {
            if (state is StoreSelected) {
              context.go('/store/${state.storeId}');
            }
            // Auto-navigate StoreManager to their store
            if (state is StoreSelectionLoaded && isStoreManager) {
              if (state.stores.isNotEmpty) {
                // StoreManager always manages exactly one store
                context.go('/store/${state.stores.first.id}');
              }
            }
          },
          builder: (context, state) {
            // ── StoreManager: always show a loading/redirecting screen ──
            if (isStoreManager) {
              if (state is StoreSelectionError) {
                return _buildStoreManagerError(state.failure);
              }
              return _buildStoreManagerLoading();
            }

            // ── BrandManager / SystemAdmin: full store selection UI ──
            if (state is StoreSelectionLoading) {
              return Column(
                children: [
                  _buildSelectionHeader(
                    state: null,
                    canEditBrand: false,
                    canManageBrandSchedule: canManageBrandSchedule,
                    canUseBulkGovernance: canUseBulkGovernance,
                  ),
                  const Expanded(
                    child: CamsSkeletonCardGrid(
                      itemCount: 6,
                      childAspectRatio: 0.95,
                      padding: EdgeInsets.all(16),
                    ),
                  ),
                ],
              );
            }

            if (state is StoreSelectionError) {
              return Column(
                children: [
                  _buildSelectionHeader(
                    state: null,
                    canEditBrand: false,
                    canManageBrandSchedule: canManageBrandSchedule,
                    canUseBulkGovernance: canUseBulkGovernance,
                  ),
                  Expanded(
                    child: AppErrorView(
                      failure: state.failure,
                      title: 'Stores unavailable',
                      onRetry: _reloadStores,
                    ),
                  ),
                ],
              );
            }

            if (state is StoreSelectionLoaded) {
              return Column(
                children: [
                  _buildSelectionHeader(
                    state: state,
                    canEditBrand: authUser?.isBrandManager == true ||
                        authUser?.isSystemAdmin == true,
                    canManageBrandSchedule: canManageBrandSchedule,
                    canUseBulkGovernance: canUseBulkGovernance,
                  ),
                  _buildSearchBar(),
                  if (canUseBulkGovernance && _isBulkSelectionMode)
                    _buildBulkGovernanceBar(state.filteredStores),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _refreshStores,
                      child: state.filteredStores.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.sizeOf(context).height * 0.55,
                                  child: _buildEmptyState(),
                                ),
                              ],
                            )
                          : _buildStoreGrid(state.filteredStores),
                    ),
                  ),
                ],
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSelectionHeader({
    required StoreSelectionLoaded? state,
    required bool canEditBrand,
    required bool canManageBrandSchedule,
    required bool canUseBulkGovernance,
  }) {
    final tokens = context.camsTokens;
    final colorScheme = Theme.of(context).colorScheme;
    final stores = state?.stores ?? const <StoreSummary>[];
    final title = _isBulkSelectionMode
        ? '${_selectedStoreIds.length} selected'
        : 'Select Store';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 20, 18),
        child: SizedBox(
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Positioned(
                right: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state != null)
                      _buildBrandAvatarAction(
                        state,
                        canEdit: canEditBrand,
                      ),
                    if (state == null)
                      _buildHeaderFallbackAvatar(colorScheme.primary),
                    const SizedBox(width: 6),
                    PopupMenuButton<_StoreSelectionAction>(
                      tooltip: 'Store actions',
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: tokens.textTertiary,
                      ),
                      onSelected: (action) =>
                          _handleStoreSelectionAction(action, stores),
                      itemBuilder: (context) => [
                        if (canManageBrandSchedule)
                          PopupMenuItem(
                            value: _StoreSelectionAction.brandSchedule,
                            enabled: !_isBulkSelectionMode && stores.isNotEmpty,
                            child: const ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.event_note_outlined),
                              title: Text('Brand schedule'),
                            ),
                          ),
                        if (canUseBulkGovernance)
                          PopupMenuItem(
                            value: _StoreSelectionAction.bulkGovernance,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                _isBulkSelectionMode
                                    ? Icons.close_fullscreen_rounded
                                    : Icons.verified_user_outlined,
                              ),
                              title: Text(
                                _isBulkSelectionMode
                                    ? 'Exit bulk governance'
                                    : 'Bulk governance',
                              ),
                            ),
                          ),
                        PopupMenuItem(
                          value: _StoreSelectionAction.logout,
                          enabled: !_isBulkSelectionMode,
                          child: const ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(Icons.logout),
                            title: Text('Logout'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderFallbackAvatar(Color color) {
    return Icon(
      Icons.account_circle_outlined,
      color: color,
      size: 38,
    );
  }

  void _handleStoreSelectionAction(
    _StoreSelectionAction action,
    List<StoreSummary> stores,
  ) {
    switch (action) {
      case _StoreSelectionAction.brandSchedule:
        if (_isBulkSelectionMode || stores.isEmpty) return;
        _openBrandScheduleFromSelection(context, stores);
      case _StoreSelectionAction.bulkGovernance:
        _toggleBulkSelectionMode();
      case _StoreSelectionAction.logout:
        if (_isBulkSelectionMode) return;
        _showLogoutDialog(context);
    }
  }

  /// Loading screen shown to StoreManager while fetching their store.
  Widget _buildStoreManagerLoading() {
    return const CamsSkeletonDashboard(
      padding: EdgeInsets.fromLTRB(20, 96, 20, 32),
    );
  }

  /// Error screen for StoreManager when store fetch fails.
  Widget _buildStoreManagerError(Failure failure) {
    return AppErrorView(
      failure: failure,
      title: 'Could not load your store',
      onRetry: _reloadStores,
      onSecondaryAction: () => _showLogoutDialog(context),
      secondaryLabel: 'Logout',
    );
  }

  void _reloadStores() {
    context.read<StoreSelectionBloc>().add(
          LoadUserStores(
            preferredBrandId: context.read<AuthBloc>().state.user?.brandId,
            forceRefresh: true,
          ),
        );
  }

  Future<void> _refreshStores() async {
    _reloadStores();
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }

  Widget _buildBrandAvatarAction(
    StoreSelectionLoaded state, {
    required bool canEdit,
  }) {
    final brand = state.brandDetail;
    final tokens = context.camsTokens;
    final colorScheme = Theme.of(context).colorScheme;

    Widget avatarChild;
    if (state.isBrandDetailLoading && brand == null) {
      avatarChild = SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colorScheme.primary,
        ),
      );
    } else if (brand == null) {
      avatarChild = Icon(
        Icons.business_rounded,
        color: state.brandDetailFailure == null
            ? colorScheme.primary
            : tokens.warning,
        size: 18,
      );
    } else {
      avatarChild = _buildCircularBrandImage(brand, size: 30);
    }

    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: Tooltip(
        message: brand == null ? 'Brand profile' : '${brand.name} profile',
        child: InkResponse(
          onTap: brand == null
              ? () {
                  final brandId =
                      context.read<AuthBloc>().state.user?.brandId ??
                          _firstBrandId(state.stores);
                  if (brandId != null) {
                    context
                        .read<StoreSelectionBloc>()
                        .add(LoadBrandDetail(brandId));
                  }
                }
              : () => _showBrandProfileSheet(
                    state,
                    canEdit: canEdit,
                  ),
          radius: 22,
          child: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tokens.bgBase,
              border: Border.all(
                color: tokens.textPrimary,
                width: 1.2,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarChild,
          ),
        ),
      ),
    );
  }

  Widget _buildCircularBrandImage(BrandDetail brand, {required double size}) {
    final colorScheme = Theme.of(context).colorScheme;
    final logoUrl = brand.logoUrl?.trim();
    final fallbackLetter = brand.name.trim().isEmpty
        ? 'B'
        : brand.name.trim().characters.first.toUpperCase();

    if (logoUrl != null && logoUrl.isNotEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.network(
          logoUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(
              fallbackLetter,
              style: AppTypography.titleLarge.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      );
    }

    return Center(
      child: Text(
        fallbackLetter,
        style: AppTypography.titleLarge.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Future<void> _showBrandProfileSheet(
    StoreSelectionLoaded state, {
    required bool canEdit,
  }) async {
    final brand = state.brandDetail;
    if (brand == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: context.camsTokens.bgElevated,
      builder: (sheetContext) => _BrandProfileSheet(
        brand: brand,
        activeStoreCount:
            state.stores.where((store) => store.status.isActive).length,
        totalStoreCount: state.stores.length,
        canEdit: canEdit && _canEditBrand(brand),
        onSave: (request) => _updateBrandProfile(brand.id, request),
      ),
    );
  }

  bool _canEditBrand(BrandDetail brand) {
    final user = context.read<AuthBloc>().state.user;
    if (user?.isSystemAdmin == true) return true;
    if (user?.isBrandManager != true) return false;
    final userBrandId = user?.brandId?.trim();
    return userBrandId != null &&
        userBrandId.isNotEmpty &&
        userBrandId == brand.id;
  }

  Future<bool> _updateBrandProfile(
    String brandId,
    BrandUpdateRequest request,
  ) async {
    final result = await sl<UpdateBrandDetail>()(
      brandId: brandId,
      request: request,
    );
    if (!mounted) return false;

    return result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failure.message.isNotEmpty
                  ? failure.message
                  : 'Failed to update brand profile.',
            ),
            backgroundColor: context.camsTokens.error,
          ),
        );
        return false;
      },
      (message) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.isNotEmpty ? message : 'Brand profile updated.',
            ),
          ),
        );
        context
            .read<StoreSelectionBloc>()
            .add(LoadBrandDetail(brandId, forceRefresh: true));
        return true;
      },
    );
  }

  String? _firstBrandId(List<StoreSummary> stores) {
    for (final store in stores) {
      final brandId = store.brandId.trim();
      if (brandId.isNotEmpty) return brandId;
    }
    return null;
  }

  Widget _buildSearchBar() {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(34, 0, 34, 28),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.bgBase.withValues(alpha: isDark ? 0.72 : 1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: tokens.border.withValues(alpha: isDark ? 0.86 : 1),
            width: 1.2,
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: tokens.shadow.withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: TextField(
          controller: _searchController,
          cursorColor: colorScheme.primary,
          style: AppTypography.titleMedium.copyWith(
            color: tokens.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Search stores...',
            hintStyle: AppTypography.titleMedium.copyWith(
              color: tokens.textTertiary,
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: null,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: tokens.textSecondary,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                      context.read<StoreSelectionBloc>().add(
                            const SearchStores(''),
                          );
                    },
                  )
                : Icon(
                    Icons.search_rounded,
                    color: tokens.textTertiary,
                    size: 28,
                  ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 22,
              vertical: 14,
            ),
            filled: false,
          ),
          onChanged: (value) {
            setState(() {});
            context.read<StoreSelectionBloc>().add(SearchStores(value));
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final tokens = context.camsTokens;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: tokens.textTertiary,
          ),
          const SizedBox(height: 16),
          Text(
            'No stores found',
            style: AppTypography.titleLarge.copyWith(
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search',
            style: AppTypography.bodyMedium.copyWith(
              color: tokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulkGovernanceBar(List<StoreSummary> filteredStores) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;
    final textPrimary = tokens.textPrimary;
    final textSecondary = tokens.textSecondary;
    final filteredIds = filteredStores.map((store) => store.id).toSet();
    final selectedVisibleCount =
        _selectedStoreIds.where(filteredIds.contains).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.bgContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.12),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_selectedStoreIds.length} selected',
                      style: AppTypography.bodyMedium.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (_isApplyingBulkMode)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$selectedVisibleCount in current filter',
                style: AppTypography.labelSmall.copyWith(
                  color: textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: filteredStores.isEmpty || _isApplyingBulkMode
                          ? null
                          : () => _selectFilteredStores(filteredStores),
                      icon: const Icon(Icons.done_all_rounded, size: 18),
                      label: const Text('Filtered'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _selectedStoreIds.isEmpty || _isApplyingBulkMode
                              ? null
                              : _clearSelectedStores,
                      icon: const Icon(Icons.layers_clear_outlined, size: 18),
                      label: const Text('Clear'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _selectedStoreIds.isEmpty || _isApplyingBulkMode
                      ? null
                      : _showBulkGovernanceModeDialog,
                  icon: const Icon(Icons.verified_user_outlined, size: 18),
                  label: const Text('Set mode'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreGrid(List<StoreSummary> stores) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useListLayout =
            _isBulkSelectionMode || constraints.maxWidth < 600;

        if (useListLayout) {
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(34, 0, 34, 32),
            itemCount: stores.length,
            separatorBuilder: (_, __) => const SizedBox(height: 28),
            itemBuilder: (context, index) => _buildStoreListCard(stores[index]),
          );
        }

        const gridPadding = 32.0;
        const gridSpacing = 16.0;
        const minTileWidth = 160.0;
        final availableGridWidth =
            (constraints.maxWidth - gridPadding).clamp(minTileWidth, 4000.0);
        final crossAxisCount =
            ((availableGridWidth + gridSpacing) / (minTileWidth + gridSpacing))
                .floor()
                .clamp(1, 4);
        final tileWidth =
            (availableGridWidth - (gridSpacing * (crossAxisCount - 1))) /
                crossAxisCount;
        final isCompactTile = tileWidth < 148;
        final mainAxisExtent = _isBulkSelectionMode
            ? (isCompactTile ? 248.0 : 232.0)
            : (isCompactTile ? 216.0 : 200.0);

        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: gridSpacing,
            mainAxisSpacing: gridSpacing,
            mainAxisExtent: mainAxisExtent,
          ),
          itemCount: stores.length,
          itemBuilder: (context, index) {
            final store = stores[index];
            return _buildStoreCard(store, isCompactTile: isCompactTile);
          },
        );
      },
    );
  }

  Widget _buildStoreCard(
    StoreSummary store, {
    required bool isCompactTile,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canUseBulkGovernance =
        context.read<AuthBloc>().state.user?.isBrandManager == true;
    final isSelected = _selectedStoreIds.contains(store.id);
    final topSectionHeight = isCompactTile ? 68.0 : 78.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.bgElevated.withValues(alpha: isDark ? 0.88 : 0.98),
            tokens.bgContainer.withValues(alpha: isDark ? 0.72 : 0.96),
          ],
        ),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : tokens.borderSecondary.withValues(alpha: isDark ? 0.82 : 1),
          width: isSelected ? 1.8 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: isDark ? 0.34 : 0.14)
                : tokens.shadow.withValues(alpha: isDark ? 0.3 : 0.09),
            blurRadius: isSelected ? 24 : 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (_isBulkSelectionMode) {
            _toggleStoreSelection(store.id);
            return;
          }
          context.read<StoreSelectionBloc>().add(SelectStore(store.id));
        },
        onLongPress: canUseBulkGovernance && !_isBulkSelectionMode
            ? () {
                _toggleBulkSelectionMode(enabled: true);
                _toggleStoreSelection(store.id);
              }
            : null,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: topSectionHeight,
                    decoration: BoxDecoration(
                      color: tokens.bgBase.withValues(alpha: isDark ? 0.72 : 1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: colorScheme.primary.withValues(
                          alpha: isDark ? 0.28 : 0.12,
                        ),
                      ),
                    ),
                    child: Center(
                      child: _NeonStoreIcon(
                        size: isCompactTile ? 48 : 56,
                        color: colorScheme.primary,
                        glowColor: colorScheme.primary,
                        glowStrength: isDark ? 0.48 : 0.14,
                      ),
                    ),
                  ),
                  if (_isBulkSelectionMode)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: _isApplyingBulkMode
                            ? null
                            : (_) => _toggleStoreSelection(store.id),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        activeColor: colorScheme.primary,
                      ),
                    ),
                ],
              ),
              SizedBox(height: isCompactTile ? 8 : 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, innerConstraints) {
                    final isTightHeight = innerConstraints.maxHeight < 88;
                    final titleMaxLines =
                        (isCompactTile || isTightHeight) ? 1 : 2;
                    final showAddress = !isCompactTile && !isTightHeight;
                    final showSelectionLabel = _isBulkSelectionMode &&
                        !isCompactTile &&
                        !isTightHeight;
                    final selectionLabel = isSelected
                        ? 'Selected for bulk action'
                        : 'Tap to select';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: AppTypography.titleLarge.copyWith(
                            fontSize: isCompactTile ? 14 : 16,
                            color: tokens.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: titleMaxLines,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (showAddress) ...[
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: tokens.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  store.fullAddress,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: tokens.textTertiary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const Spacer(),
                        _buildStatusBadge(store),
                        if (showSelectionLabel) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colorScheme.primary.withValues(alpha: 0.12)
                                  : tokens.bgElevated,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              selectionLabel,
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected
                                    ? colorScheme.primary
                                    : tokens.textTertiary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(StoreSummary store) {
    final tokens = context.camsTokens;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor =
        store.status.isActive ? colorScheme.primary : tokens.warning;
    final label = store.status.isActive ? 'Active' : store.status.displayName;

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            statusColor.withValues(alpha: store.status.isActive ? 0.92 : 0.12),
        borderRadius: BorderRadius.circular(999),
        boxShadow: isDark && store.status.isActive
            ? [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: store.status.isActive ? colorScheme.onPrimary : statusColor,
            fontWeight: FontWeight.w800,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AuthBloc>().add(const LogoutRequested());
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _toggleBulkSelectionMode({bool? enabled}) {
    final nextValue = enabled ?? !_isBulkSelectionMode;
    setState(() {
      _isBulkSelectionMode = nextValue;
      if (!nextValue) {
        _selectedStoreIds.clear();
      }
    });
  }

  void _toggleStoreSelection(String storeId) {
    if (_isApplyingBulkMode) return;
    setState(() {
      if (_selectedStoreIds.contains(storeId)) {
        _selectedStoreIds.remove(storeId);
      } else {
        _selectedStoreIds.add(storeId);
      }
    });
  }

  void _selectFilteredStores(List<StoreSummary> stores) {
    if (_isApplyingBulkMode) return;
    setState(() {
      _selectedStoreIds.addAll(stores.map((store) => store.id));
    });
  }

  void _clearSelectedStores() {
    setState(() => _selectedStoreIds.clear());
  }

  Future<List<ScheduleMusicItem>> _loadBrandScheduleMusicCatalog(
    String brandId,
  ) async {
    final response = await sl<PlaylistRemoteDataSource>().getPlaylists(
      page: 1,
      pageSize: 100,
      brandId: brandId,
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

  Future<void> _openBrandScheduleFromSelection(
    BuildContext context,
    List<StoreSummary> stores,
  ) async {
    final storesByBrand = _groupStoresByBrand(stores);
    if (storesByBrand.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No brand is available for schedule setup.'),
        ),
      );
      return;
    }

    final brandId = storesByBrand.length == 1
        ? storesByBrand.keys.single
        : await _showBrandScheduleBrandPicker(context, storesByBrand);
    if (!context.mounted || brandId == null) return;

    await _showBrandScheduleEditorSheetForBrand(context, brandId);
  }

  Map<String, List<StoreSummary>> _groupStoresByBrand(
    List<StoreSummary> stores,
  ) {
    final storesByBrand = <String, List<StoreSummary>>{};
    for (final store in stores) {
      final brandId = store.brandId.trim();
      if (brandId.isEmpty) continue;
      storesByBrand.putIfAbsent(brandId, () => <StoreSummary>[]).add(store);
    }
    return storesByBrand;
  }

  Future<String?> _showBrandScheduleBrandPicker(
    BuildContext context,
    Map<String, List<StoreSummary>> storesByBrand,
  ) {
    final entries = storesByBrand.entries.toList(growable: false)
      ..sort((a, b) => a.key.compareTo(b.key));

    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          itemCount: entries.length + 1,
          separatorBuilder: (_, index) =>
              index == 0 ? const SizedBox(height: 8) : const Divider(),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                child: Text(
                  'Choose brand schedule',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              );
            }

            final entry = entries[index - 1];
            final stores = entry.value;
            final firstStoreName =
                stores.isEmpty ? 'No stores' : stores.first.name;
            return ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.business_outlined),
              ),
              title: Text(_brandSchedulePickerTitle(entry.key)),
              subtitle: Text(
                '${stores.length} store(s), including $firstStoreName',
              ),
              onTap: () => Navigator.of(sheetContext).pop(entry.key),
            );
          },
        ),
      ),
    );
  }

  String _brandSchedulePickerTitle(String brandId) {
    final trimmed = brandId.trim();
    if (trimmed.length <= 8) return 'Brand $trimmed';
    return 'Brand ${trimmed.substring(0, 8)}';
  }

  Future<void> _showBrandScheduleEditorSheetForBrand(
    BuildContext context,
    String brandId,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BrandScheduleEditorSheetLoader(
        brandId: brandId,
        loadMusicCatalog: () => _loadBrandScheduleMusicCatalog(brandId),
        remoteDataSource: sl<SpaceScheduleRemoteDataSource>(),
      ),
    );

    if (!context.mounted) return;
    _reloadStores();
  }

  Future<void> _showBulkGovernanceModeDialog() async {
    if (_selectedStoreIds.isEmpty || _isApplyingBulkMode) return;
    final tokens = context.camsTokens;

    final selectedStoreIds = _selectedStoreIds.toList(growable: false);
    final currentState = context.read<StoreSelectionBloc>().state;
    final selectedStores = currentState is StoreSelectionLoaded
        ? currentState.stores
            .where((store) => _selectedStoreIds.contains(store.id))
            .toList(growable: false)
        : const <StoreSummary>[];
    final selectedBrandIds = selectedStores
        .map((store) => store.brandId.trim())
        .where((brandId) => brandId.isNotEmpty)
        .toSet();
    final fallbackBrandId = context.read<AuthBloc>().state.user?.brandId;
    final selectedBrandId = selectedBrandIds.length == 1
        ? selectedBrandIds.single
        : fallbackBrandId;
    final canLoadStrictSyncTemplates = selectedBrandIds.length <= 1 &&
        selectedBrandId?.trim().isNotEmpty == true;
    var templates = const <ScheduleSource>[];
    var isLoadingTemplates = false;
    String? templateError;
    Future<void> loadTemplates(StateSetter setDialogState) async {
      if (!canLoadStrictSyncTemplates || isLoadingTemplates) return;
      setDialogState(() {
        isLoadingTemplates = true;
        templateError = null;
      });
      try {
        final freshTemplates = await sl<SpaceScheduleRemoteDataSource>()
            .getBrandTemplates(selectedBrandId!.trim());
        if (!mounted) return;
        setDialogState(() {
          templates = freshTemplates;
          isLoadingTemplates = false;
          templateError = null;
        });
      } catch (error) {
        if (!mounted) return;
        setDialogState(() {
          isLoadingTemplates = false;
          templateError = error.toString();
        });
      }
    }

    final modeSnapshot = _resolveBulkGovernanceModeSelection(selectedStoreIds);
    StoreGovernanceMode? selectedMode = modeSnapshot.initialMode;
    String? selectedSourceId;
    var hasRequestedTemplates = false;
    final result = await showDialog<_BulkGovernanceApplySelection>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          if (selectedMode == StoreGovernanceMode.strictSync &&
              canLoadStrictSyncTemplates &&
              !hasRequestedTemplates) {
            hasRequestedTemplates = true;
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => loadTemplates(setState),
            );
          }

          return AlertDialog(
            title: const Text('Bulk governance mode'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_selectedStoreIds.length} selected store(s) will receive the same governance mode.',
                      style: AppTypography.bodyMedium.copyWith(height: 1.35),
                    ),
                    if (modeSnapshot.isMixed) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Selected stores currently use mixed governance modes.',
                        style: AppTypography.labelSmall.copyWith(
                          color: tokens.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    RadioGroup<StoreGovernanceMode>(
                      groupValue: selectedMode,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          selectedMode = value;
                          if (value != StoreGovernanceMode.strictSync) {
                            selectedSourceId = null;
                          } else if (canLoadStrictSyncTemplates &&
                              !hasRequestedTemplates) {
                            hasRequestedTemplates = true;
                            WidgetsBinding.instance.addPostFrameCallback(
                              (_) => loadTemplates(setState),
                            );
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
                      if (!canLoadStrictSyncTemplates)
                        Text(
                          'Templates are unavailable when selected stores belong to multiple brands.',
                          style: AppTypography.labelSmall.copyWith(
                            color: tokens.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        _StrictSyncTemplatePicker(
                          templates: templates,
                          selectedSourceId: selectedSourceId,
                          isLoading: isLoadingTemplates,
                          errorMessage: templateError,
                          onRefresh: () => loadTemplates(setState),
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
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: selectedMode == null
                    ? null
                    : () => Navigator.of(dialogContext).pop(
                          _BulkGovernanceApplySelection(
                            mode: selectedMode!,
                            sourceId:
                                selectedMode == StoreGovernanceMode.strictSync
                                    ? selectedSourceId
                                    : null,
                          ),
                        ),
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );

    if (result == null || !mounted) return;

    setState(() => _isApplyingBulkMode = true);
    final response = await sl<SetStoreGovernanceMode>()(
      request: SetStoreGovernanceModeRequest(
        storeIds: selectedStoreIds,
        mode: result.mode,
        sourceId: result.sourceId,
      ),
    );
    if (!mounted) return;

    response.fold(
      (failure) {
        setState(() => _isApplyingBulkMode = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failure.message.isNotEmpty
                  ? failure.message
                  : 'Failed to update governance mode.',
            ),
            backgroundColor: tokens.error,
          ),
        );
      },
      (message) {
        setState(() {
          for (final storeId in selectedStoreIds) {
            _knownStoreGovernanceModes[storeId] = result.mode;
          }
          _isApplyingBulkMode = false;
          _isBulkSelectionMode = false;
          _selectedStoreIds.clear();
        });
        _reloadStores();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.isNotEmpty
                  ? message
                  : 'Governance mode updated for selected stores.',
            ),
          ),
        );
      },
    );
  }

  _BulkGovernanceModeSelection _resolveBulkGovernanceModeSelection(
    List<String> selectedStoreIds,
  ) {
    final currentState = context.read<StoreSelectionBloc>().state;
    final storesById = currentState is StoreSelectionLoaded
        ? {
            for (final store in currentState.stores) store.id: store,
          }
        : const <String, StoreSummary>{};

    final modes = <StoreGovernanceMode>{};
    var unknownCount = 0;
    for (final storeId in selectedStoreIds) {
      final mode = _knownStoreGovernanceModes[storeId] ??
          storesById[storeId]?.governanceMode;
      if (mode == null) {
        unknownCount++;
      } else {
        modes.add(mode);
      }
    }

    if (modes.length == 1 && unknownCount == 0) {
      return _BulkGovernanceModeSelection(initialMode: modes.single);
    }
    if (modes.length > 1) {
      return const _BulkGovernanceModeSelection(isMixed: true);
    }

    return const _BulkGovernanceModeSelection(
      initialMode: StoreGovernanceMode.freedom,
    );
  }

  Widget _buildStoreListCard(StoreSummary store) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.camsTokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canUseBulkGovernance =
        context.read<AuthBloc>().state.user?.isBrandManager == true;
    final isSelected = _selectedStoreIds.contains(store.id);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: tokens.bgElevated.withValues(alpha: isDark ? 0.78 : 0.98),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : tokens.border.withValues(alpha: isDark ? 0.78 : 0.9),
          width: isSelected ? 1.5 : 1.1,
        ),
        boxShadow: [
          if (!isDark || isSelected)
            BoxShadow(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: isDark ? 0.18 : 0.1)
                  : tokens.shadow.withValues(alpha: 0.08),
              blurRadius: isSelected ? 18 : 14,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (_isBulkSelectionMode) {
            _toggleStoreSelection(store.id);
            return;
          }
          context.read<StoreSelectionBloc>().add(SelectStore(store.id));
        },
        onLongPress: canUseBulkGovernance && !_isBulkSelectionMode
            ? () {
                _toggleBulkSelectionMode(enabled: true);
                _toggleStoreSelection(store.id);
              }
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                children: [
                  _MinimalStoreIcon(
                    size: 56,
                    color: colorScheme.primary,
                  ),
                  if (_isBulkSelectionMode)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Checkbox(
                        value: isSelected,
                        onChanged: _isApplyingBulkMode
                            ? null
                            : (_) => _toggleStoreSelection(store.id),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                        activeColor: colorScheme.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      store.name,
                      style: AppTypography.titleLarge.copyWith(
                        fontSize: 19,
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      store.fullAddress,
                      style: AppTypography.bodyMedium.copyWith(
                        color: tokens.textSecondary,
                        height: 1.22,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_isBulkSelectionMode) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.12)
                              : tokens.bgBase,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isSelected
                              ? 'Selected for bulk action'
                              : 'Tap to select',
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? colorScheme.primary
                                : tokens.textTertiary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Align(
                alignment: Alignment.topCenter,
                child: _buildStatusBadge(store),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MinimalStoreIcon extends StatelessWidget {
  const _MinimalStoreIcon({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _MinimalStoreIconPainter(color: color),
      ),
    );
  }
}

class _MinimalStoreIconPainter extends CustomPainter {
  const _MinimalStoreIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final roof = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.08,
        size.width * 0.48,
        size.height * 0.1,
      ),
      Radius.circular(size.width * 0.03),
    );
    canvas.drawRRect(roof, paint);

    final awning = Path()
      ..moveTo(size.width * 0.14, size.height * 0.26)
      ..lineTo(size.width * 0.68, size.height * 0.26)
      ..quadraticBezierTo(
        size.width * 0.7,
        size.height * 0.44,
        size.width * 0.58,
        size.height * 0.44,
      )
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.44,
        size.width * 0.46,
        size.height * 0.36,
      )
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.44,
        size.width * 0.34,
        size.height * 0.44,
      )
      ..quadraticBezierTo(
        size.width * 0.26,
        size.height * 0.44,
        size.width * 0.22,
        size.height * 0.36,
      )
      ..quadraticBezierTo(
        size.width * 0.18,
        size.height * 0.44,
        size.width * 0.1,
        size.height * 0.44,
      )
      ..quadraticBezierTo(
        size.width * 0.04,
        size.height * 0.43,
        size.width * 0.08,
        size.height * 0.26,
      )
      ..close();
    canvas.drawPath(awning, paint);

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.42,
        size.width * 0.43,
        size.height * 0.42,
      ),
      Radius.circular(size.width * 0.04),
    );
    canvas.drawRRect(body, stroke);

    final door = Rect.fromLTWH(
      size.width * 0.28,
      size.height * 0.56,
      size.width * 0.16,
      size.height * 0.28,
    );
    canvas.drawRect(door, paint);

    final brickWidth = size.width * 0.13;
    final brickHeight = size.height * 0.06;
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 2; col++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * (0.7 + col * 0.16),
              size.height * (0.46 + row * 0.1),
              brickWidth,
              brickHeight,
            ),
            Radius.circular(size.width * 0.015),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MinimalStoreIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _NeonStoreIcon extends StatelessWidget {
  const _NeonStoreIcon({
    required this.size,
    required this.color,
    required this.glowColor,
    required this.glowStrength,
  });

  final double size;
  final Color color;
  final Color glowColor;
  final double glowStrength;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _NeonStoreIconPainter(
              color: glowColor.withValues(alpha: glowStrength),
              strokeWidth: size * 0.07,
              blurRadius: size * 0.1,
            ),
          ),
          CustomPaint(
            size: Size.square(size),
            painter: _NeonStoreIconPainter(
              color: color,
              strokeWidth: size * 0.035,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeonStoreIconPainter extends CustomPainter {
  const _NeonStoreIconPainter({
    required this.color,
    required this.strokeWidth,
    this.blurRadius = 0,
  });

  final Color color;
  final double strokeWidth;
  final double blurRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (blurRadius > 0) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blurRadius);
    }

    Path scalePath(List<Offset> points, {bool close = false}) {
      final path = Path()
        ..moveTo(points.first.dx * size.width, points.first.dy * size.height);
      for (final point in points.skip(1)) {
        path.lineTo(point.dx * size.width, point.dy * size.height);
      }
      if (close) path.close();
      return path;
    }

    final base = scalePath(
      const [
        Offset(0.16, 0.82),
        Offset(0.5, 0.96),
        Offset(0.84, 0.82),
        Offset(0.84, 0.74),
        Offset(0.5, 0.88),
        Offset(0.16, 0.74),
      ],
    );
    canvas.drawPath(base, paint);

    final roofTop = scalePath(
      const [
        Offset(0.2, 0.3),
        Offset(0.5, 0.18),
        Offset(0.8, 0.3),
        Offset(0.5, 0.42),
        Offset(0.2, 0.3),
      ],
    );
    canvas.drawPath(roofTop, paint);

    final roofLip = scalePath(
      const [
        Offset(0.22, 0.36),
        Offset(0.5, 0.48),
        Offset(0.78, 0.36),
      ],
    );
    canvas.drawPath(roofLip, paint);

    final body = scalePath(
      const [
        Offset(0.24, 0.42),
        Offset(0.24, 0.72),
        Offset(0.5, 0.84),
        Offset(0.76, 0.72),
        Offset(0.76, 0.42),
      ],
    );
    canvas.drawPath(body, paint);

    final awning = scalePath(
      const [
        Offset(0.25, 0.48),
        Offset(0.35, 0.52),
        Offset(0.45, 0.48),
        Offset(0.55, 0.52),
        Offset(0.65, 0.48),
        Offset(0.75, 0.52),
      ],
    );
    canvas.drawPath(awning, paint);

    final door = Rect.fromLTWH(
      size.width * 0.34,
      size.height * 0.58,
      size.width * 0.12,
      size.height * 0.2,
    );
    canvas.drawRect(door, paint);

    final window = Rect.fromLTWH(
      size.width * 0.56,
      size.height * 0.58,
      size.width * 0.14,
      size.height * 0.12,
    );
    canvas.drawRect(window, paint);
  }

  @override
  bool shouldRepaint(covariant _NeonStoreIconPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.blurRadius != blurRadius;
  }
}

class _BulkGovernanceModeSelection {
  final StoreGovernanceMode? initialMode;
  final bool isMixed;

  const _BulkGovernanceModeSelection({
    this.initialMode,
    this.isMixed = false,
  });
}

class _BulkGovernanceApplySelection {
  const _BulkGovernanceApplySelection({
    required this.mode,
    this.sourceId,
  });

  final StoreGovernanceMode mode;
  final String? sourceId;
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
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CamsSkeletonLine(width: 190, height: 14),
            SizedBox(height: 10),
            CamsSkeletonBox(height: 48, radius: 12),
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

class _BrandProfileSheet extends StatefulWidget {
  const _BrandProfileSheet({
    required this.brand,
    required this.activeStoreCount,
    required this.totalStoreCount,
    required this.canEdit,
    required this.onSave,
  });

  final BrandDetail brand;
  final int activeStoreCount;
  final int totalStoreCount;
  final bool canEdit;
  final Future<bool> Function(BrandUpdateRequest request) onSave;

  @override
  State<_BrandProfileSheet> createState() => _BrandProfileSheetState();
}

class _BrandProfileSheetState extends State<_BrandProfileSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _websiteController;
  late final TextEditingController _industryController;
  late final TextEditingController _primaryContactNameController;
  late final TextEditingController _contactEmailController;
  late final TextEditingController _contactPhoneController;
  late final TextEditingController _legalNameController;
  late final TextEditingController _taxCodeController;
  late final TextEditingController _billingAddressController;
  late final TextEditingController _technicalContactEmailController;
  late final TextEditingController _defaultTimeZoneController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final brand = widget.brand;
    _nameController = TextEditingController(text: brand.name);
    _descriptionController = TextEditingController(text: brand.description);
    _websiteController = TextEditingController(text: brand.website);
    _industryController = TextEditingController(text: brand.industry);
    _primaryContactNameController =
        TextEditingController(text: brand.primaryContactName);
    _contactEmailController = TextEditingController(text: brand.contactEmail);
    _contactPhoneController = TextEditingController(text: brand.contactPhone);
    _legalNameController = TextEditingController(text: brand.legalName);
    _taxCodeController = TextEditingController(text: brand.taxCode);
    _billingAddressController =
        TextEditingController(text: brand.billingAddress);
    _technicalContactEmailController =
        TextEditingController(text: brand.technicalContactEmail);
    _defaultTimeZoneController =
        TextEditingController(text: brand.defaultTimeZone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _industryController.dispose();
    _primaryContactNameController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _legalNameController.dispose();
    _taxCodeController.dispose();
    _billingAddressController.dispose();
    _technicalContactEmailController.dispose();
    _defaultTimeZoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.camsTokens;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(tokens),
                const SizedBox(height: 18),
                if (_isEditing) _buildEditFields() else _buildReadOnlyProfile(),
                const SizedBox(height: 18),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(CamsThemeTokens tokens) {
    final colorScheme = Theme.of(context).colorScheme;
    final brand = widget.brand;
    final logoUrl = brand.logoUrl?.trim();
    final fallbackLetter = brand.name.trim().isEmpty
        ? 'B'
        : brand.name.trim().characters.first.toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 72,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primary.withValues(alpha: 0.1),
            border: Border.all(color: tokens.borderSecondary),
          ),
          child: logoUrl == null || logoUrl.isEmpty
              ? Center(
                  child: Text(
                    fallbackLetter,
                    style: AppTypography.headlineMedium.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              : Image.network(
                  logoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Text(
                      fallbackLetter,
                      style: AppTypography.headlineMedium.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                brand.name,
                style: AppTypography.headlineSmall.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                _fallback(brand.description),
                style: AppTypography.bodyMedium.copyWith(
                  color: tokens.textSecondary,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statusChip(brand.status),
                  _metricChip(
                    Icons.storefront_outlined,
                    '${widget.activeStoreCount}/${widget.totalStoreCount} stores',
                    colorScheme.primary,
                  ),
                  if (_hasText(brand.industry))
                    _metricChip(
                      Icons.business_center_outlined,
                      brand.industry!.trim(),
                      tokens.techAccent,
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyProfile() {
    final tokens = context.camsTokens;
    final brand = widget.brand;
    return Column(
      children: [
        Divider(color: tokens.divider),
        _detailTile(
            Icons.person_outline_rounded, 'Owner', brand.primaryContactName),
        _detailTile(Icons.email_outlined, 'Contact email', brand.contactEmail),
        _detailTile(Icons.phone_outlined, 'Contact phone', brand.contactPhone),
        _detailTile(Icons.language_rounded, 'Website', brand.website),
        _detailTile(Icons.receipt_long_outlined, 'Legal name', brand.legalName),
        _detailTile(Icons.badge_outlined, 'Tax code', brand.taxCode),
        _detailTile(Icons.location_on_outlined, 'Billing address',
            brand.billingAddress),
        _detailTile(Icons.memory_outlined, 'Technical contact',
            brand.technicalContactEmail),
        _detailTile(
          Icons.schedule_outlined,
          'Default timezone',
          brand.defaultTimeZone,
        ),
      ],
    );
  }

  Widget _buildEditFields() {
    return Column(
      children: [
        _textField(_nameController, 'Brand name', required: true),
        _textField(_descriptionController, 'Description', maxLines: 3),
        _textField(_industryController, 'Industry'),
        _textField(_websiteController, 'Website', validator: _validateWebsite),
        _textField(_primaryContactNameController, 'Primary contact'),
        _textField(_contactEmailController, 'Contact email',
            validator: _validateEmail),
        _textField(_contactPhoneController, 'Contact phone'),
        _textField(_legalNameController, 'Legal name'),
        _textField(_taxCodeController, 'Tax code'),
        _textField(_billingAddressController, 'Billing address', maxLines: 2),
        _textField(
          _technicalContactEmailController,
          'Technical contact email',
          validator: _validateEmail,
        ),
        _textField(_defaultTimeZoneController, 'Default timezone'),
      ],
    );
  }

  Widget _buildActions() {
    if (!widget.canEdit) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded, size: 18),
          label: const Text('Close'),
        ),
      );
    }

    if (!_isEditing) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Close'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Edit'),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed:
                _isSaving ? null : () => setState(() => _isEditing = false),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_rounded, size: 18),
            label: const Text('Save'),
          ),
        ),
      ],
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: (value) {
          if (required && !_hasText(value)) return '$label is required';
          return validator?.call(value);
        },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _detailTile(IconData icon, String label, String? value) {
    final tokens = context.camsTokens;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: tokens.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: tokens.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _fallback(value),
                  style: AppTypography.bodyMedium.copyWith(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(EntityStatusEnum status) {
    final tokens = context.camsTokens;
    final color = status.isActive ? tokens.success : tokens.warning;
    return _metricChip(null, status.displayName, color);
  }

  Widget _metricChip(IconData? icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState?.validate() != true) return;
    final request = _buildRequest();
    if (request.toFormFields().isEmpty) {
      setState(() => _isEditing = false);
      return;
    }

    setState(() => _isSaving = true);
    final success = await widget.onSave(request);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (success) Navigator.of(context).pop();
  }

  BrandUpdateRequest _buildRequest() {
    final brand = widget.brand;
    return BrandUpdateRequest(
      name: _changed(_nameController.text, brand.name),
      description: _changed(_descriptionController.text, brand.description),
      website: _changed(_websiteController.text, brand.website),
      industry: _changed(_industryController.text, brand.industry),
      primaryContactName: _changed(
        _primaryContactNameController.text,
        brand.primaryContactName,
      ),
      contactEmail: _changed(_contactEmailController.text, brand.contactEmail),
      contactPhone: _changed(_contactPhoneController.text, brand.contactPhone),
      legalName: _changed(_legalNameController.text, brand.legalName),
      taxCode: _changed(_taxCodeController.text, brand.taxCode),
      billingAddress:
          _changed(_billingAddressController.text, brand.billingAddress),
      technicalContactEmail: _changed(
        _technicalContactEmailController.text,
        brand.technicalContactEmail,
      ),
      defaultTimeZone:
          _changed(_defaultTimeZoneController.text, brand.defaultTimeZone),
    );
  }

  String? _changed(String nextValue, String? oldValue) {
    final next = nextValue.trim();
    final old = oldValue?.trim() ?? '';
    return next == old ? null : next;
  }

  String? _validateWebsite(String? value) {
    if (!_hasText(value)) return null;
    final uri = Uri.tryParse(value!.trim());
    final isValid = uri != null &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    return isValid ? null : 'Use a full http or https URL';
  }

  String? _validateEmail(String? value) {
    if (!_hasText(value)) return null;
    final isValid =
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value!.trim());
    return isValid ? null : 'Use a valid email address';
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  String _fallback(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? 'Not set' : trimmed;
  }
}

enum _StoreSelectionAction {
  brandSchedule,
  bulkGovernance,
  logout,
}
