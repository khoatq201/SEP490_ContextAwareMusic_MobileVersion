import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/widgets/app_error_view.dart';
import '../../../../injection_container.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../config_governance/domain/entities/config_governance_enums.dart';
import '../../../config_governance/domain/entities/config_value_upsert_request.dart';
import '../../../config_governance/domain/usecases/config_governance_usecases.dart';
import '../../../playlists/data/datasources/playlist_remote_datasource.dart';
import '../../../space_schedule/data/datasources/space_schedule_remote_datasource.dart';
import '../../../space_schedule/domain/entities/schedule_music_item.dart';
import '../../../space_schedule/presentation/widgets/brand_schedule_editor_sheet.dart';
import '../bloc/store_selection_bloc.dart';
import '../bloc/store_selection_event.dart';
import '../bloc/store_selection_state.dart';
import '../../domain/entities/store_summary.dart';

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
    context.read<StoreSelectionBloc>().add(const LoadUserStores());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        backgroundColor: isDark
            ? AppColors.backgroundDarkPrimary
            : AppColors.backgroundPrimary,
        appBar: isStoreManager
            ? null // StoreManager sees a loading screen, no app bar
            : AppBar(
                title: Text(
                  _isBulkSelectionMode
                      ? '${_selectedStoreIds.length} selected'
                      : 'Select Store',
                ),
                automaticallyImplyLeading: false,
                actions: [
                  if (canManageBrandSchedule)
                    BlocBuilder<StoreSelectionBloc, StoreSelectionState>(
                      builder: (context, state) {
                        final stores = state is StoreSelectionLoaded
                            ? state.stores
                            : const <StoreSummary>[];
                        return IconButton(
                          icon: const Icon(Icons.event_note_outlined),
                          onPressed: _isBulkSelectionMode || stores.isEmpty
                              ? null
                              : () => _openBrandScheduleFromSelection(
                                    context,
                                    stores,
                                  ),
                          tooltip: 'Brand schedule',
                        );
                      },
                    ),
                  if (canUseBulkGovernance)
                    IconButton(
                      icon: Icon(
                        _isBulkSelectionMode
                            ? Icons.close_fullscreen_rounded
                            : Icons.verified_user_outlined,
                      ),
                      onPressed: () => _toggleBulkSelectionMode(),
                      tooltip: _isBulkSelectionMode
                          ? 'Exit bulk governance'
                          : 'Bulk governance',
                    ),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: _isBulkSelectionMode
                        ? null
                        : () => _showLogoutDialog(context),
                    tooltip: 'Logout',
                  ),
                ],
              ),
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
              return const Center(child: CircularProgressIndicator());
            }

            if (state is StoreSelectionError) {
              return AppErrorView(
                failure: state.failure,
                title: 'Stores unavailable',
                onRetry: () => context
                    .read<StoreSelectionBloc>()
                    .add(const LoadUserStores()),
              );
            }

            if (state is StoreSelectionLoaded) {
              return Column(
                children: [
                  _buildSearchBar(),
                  if (canUseBulkGovernance && _isBulkSelectionMode)
                    _buildBulkGovernanceBar(state.filteredStores),
                  if (state.filteredStores.isEmpty)
                    _buildEmptyState()
                  else
                    Expanded(
                      child: _buildStoreGrid(state.filteredStores),
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

  /// Loading screen shown to StoreManager while fetching their store.
  Widget _buildStoreManagerLoading() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Loading your store...',
            style: AppTypography.titleMedium.copyWith(
              color: isDark ? AppColors.textDarkSecondary : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// Error screen for StoreManager when store fetch fails.
  Widget _buildStoreManagerError(Failure failure) {
    return AppErrorView(
      failure: failure,
      title: 'Could not load your store',
      onRetry: () =>
          context.read<StoreSelectionBloc>().add(const LoadUserStores()),
      onSecondaryAction: () => _showLogoutDialog(context),
      secondaryLabel: 'Logout',
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search stores...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<StoreSelectionBloc>().add(
                          const SearchStores(''),
                        );
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: isDark ? AppColors.surfaceDark : Colors.grey[100],
        ),
        onChanged: (value) {
          context.read<StoreSelectionBloc>().add(SearchStores(value));
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No stores found',
              style: AppTypography.titleLarge.copyWith(
                color: isDark ? AppColors.textDarkSecondary : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? AppColors.textDarkTertiary : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkGovernanceBar(List<StoreSummary> filteredStores) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textDarkPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppColors.textDarkSecondary : AppColors.textSecondary;
    final filteredIds = filteredStores.map((store) => store.id).toSet();
    final selectedVisibleCount =
        _selectedStoreIds.where(filteredIds.contains).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryOrange.withValues(alpha: 0.12),
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
            padding: const EdgeInsets.all(16),
            itemCount: stores.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canUseBulkGovernance =
        context.read<AuthBloc>().state.user?.isBrandManager == true;
    final isSelected = _selectedStoreIds.contains(store.id);
    final topSectionHeight = isCompactTile ? 52.0 : 60.0;
    return Card(
      elevation: isSelected ? 0 : 2,
      color: isDark ? AppColors.surfaceDark : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primaryOrange : Colors.transparent,
          width: 1.5,
        ),
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: topSectionHeight,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.store,
                        size: 36,
                        color: AppColors.primaryOrange,
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
                        activeColor: AppColors.primaryOrange,
                      ),
                    ),
                ],
              ),
              SizedBox(height: isCompactTile ? 6 : 8),
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
                    final statusPadding = EdgeInsets.symmetric(
                      horizontal: isCompactTile ? 6 : 8,
                      vertical: isCompactTile ? 3 : 4,
                    );
                    final selectionLabel = isSelected
                        ? 'Selected for bulk action'
                        : 'Tap to select';

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.name,
                          style: AppTypography.titleLarge.copyWith(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textDarkPrimary
                                : AppColors.textPrimary,
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
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  store.fullAddress,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const Spacer(),
                        Container(
                          padding: statusPadding,
                          decoration: BoxDecoration(
                            color: store.status.isActive
                                ? AppColors.secondaryTeal.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                store.status.isActive
                                    ? Icons.check_circle_outline
                                    : Icons.pending_outlined,
                                size: 14,
                                color: store.status.isActive
                                    ? AppColors.secondaryTeal
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  store.status.displayName,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: store.status.isActive
                                        ? AppColors.secondaryTeal
                                        : Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showSelectionLabel) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryOrange
                                      .withValues(alpha: 0.12)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              selectionLabel,
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected
                                    ? AppColors.primaryOrange
                                    : (isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600]),
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
    List<ScheduleMusicItem> musicCatalog;
    try {
      musicCatalog = await _loadBrandScheduleMusicCatalog(brandId);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load playlists for brand schedule: $error'),
          backgroundColor: AppColors.error,
        ),
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
        brandId: brandId,
        musicCatalog: musicCatalog,
        remoteDataSource: sl<SpaceScheduleRemoteDataSource>(),
      ),
    );

    if (!context.mounted) return;
    context.read<StoreSelectionBloc>().add(const LoadUserStores());
  }

  Future<void> _showBulkGovernanceModeDialog() async {
    if (_selectedStoreIds.isEmpty || _isApplyingBulkMode) return;

    final selectedStoreIds = _selectedStoreIds.toList(growable: false);
    final modeSnapshot = _resolveBulkGovernanceModeSelection(selectedStoreIds);
    StoreGovernanceMode? selectedMode = modeSnapshot.initialMode;
    final result = await showDialog<StoreGovernanceMode>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Bulk governance mode'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
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
                      color: AppColors.warning,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                RadioGroup<StoreGovernanceMode>(
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
              ],
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
                  : () => Navigator.of(dialogContext).pop(selectedMode),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    setState(() => _isApplyingBulkMode = true);
    final response = await sl<SetStoreGovernanceMode>()(
      request: SetStoreGovernanceModeRequest(
        storeIds: selectedStoreIds,
        mode: result,
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
            backgroundColor: AppColors.error,
          ),
        );
      },
      (message) {
        setState(() {
          for (final storeId in selectedStoreIds) {
            _knownStoreGovernanceModes[storeId] = result;
          }
          _isApplyingBulkMode = false;
          _isBulkSelectionMode = false;
          _selectedStoreIds.clear();
        });
        context.read<StoreSelectionBloc>().add(const LoadUserStores());
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canUseBulkGovernance =
        context.read<AuthBloc>().state.user?.isBrandManager == true;
    final isSelected = _selectedStoreIds.contains(store.id);

    return Card(
      elevation: isSelected ? 0 : 2,
      color: isDark ? AppColors.surfaceDark : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primaryOrange : Colors.transparent,
          width: 1.5,
        ),
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primaryOrange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.store,
                        size: 34,
                        color: AppColors.primaryOrange,
                      ),
                    ),
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
                        activeColor: AppColors.primaryOrange,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      store.name,
                      style: AppTypography.titleLarge.copyWith(
                        fontSize: 15,
                        color: isDark
                            ? AppColors.textDarkPrimary
                            : AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            store.fullAddress,
                            style: AppTypography.labelSmall.copyWith(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: store.status.isActive
                                ? AppColors.secondaryTeal.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                store.status.isActive
                                    ? Icons.check_circle_outline
                                    : Icons.pending_outlined,
                                size: 14,
                                color: store.status.isActive
                                    ? AppColors.secondaryTeal
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                store.status.displayName,
                                style: AppTypography.labelSmall.copyWith(
                                  color: store.status.isActive
                                      ? AppColors.secondaryTeal
                                      : Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isBulkSelectionMode)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryOrange
                                      .withValues(alpha: 0.12)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isSelected
                                  ? 'Selected for bulk action'
                                  : 'Tap to select',
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected
                                    ? AppColors.primaryOrange
                                    : (isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600]),
                                fontWeight: FontWeight.w600,
                              ),
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
}

class _BulkGovernanceModeSelection {
  final StoreGovernanceMode? initialMode;
  final bool isMixed;

  const _BulkGovernanceModeSelection({
    this.initialMode,
    this.isMixed = false,
  });
}
