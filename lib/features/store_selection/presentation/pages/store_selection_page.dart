import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
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

  /// Whether the current user is a StoreManager (should skip store selection).
  bool get _isStoreManager {
    final user = context.read<AuthBloc>().state.user;
    return user != null && user.isStoreManager;
  }

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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Show logout confirmation instead of exiting
        _showLogoutDialog(context);
      },
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDarkPrimary
            : AppColors.backgroundPrimary,
        appBar: _isStoreManager
            ? null // StoreManager sees a loading screen, no app bar
            : AppBar(
                title: const Text('Select Store'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () => _showLogoutDialog(context),
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
            if (state is StoreSelectionLoaded && _isStoreManager) {
              if (state.stores.isNotEmpty) {
                // StoreManager always manages exactly one store
                context.go('/store/${state.stores.first.id}');
              }
            }
          },
          builder: (context, state) {
            // ── StoreManager: always show a loading/redirecting screen ──
            if (_isStoreManager) {
              if (state is StoreSelectionError) {
                return _buildStoreManagerError(state.message);
              }
              return _buildStoreManagerLoading();
            }

            // ── BrandManager / SystemAdmin: full store selection UI ──
            if (state is StoreSelectionLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is StoreSelectionError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Error loading stores',
                      style: AppTypography.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.message,
                      style: AppTypography.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<StoreSelectionBloc>().add(
                              const LoadUserStores(),
                            );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is StoreSelectionLoaded) {
              return Column(
                children: [
                  _buildSearchBar(),
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
  Widget _buildStoreManagerError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Could not load your store',
              style: AppTypography.titleLarge),
          const SizedBox(height: 8),
          Text(message,
              style: AppTypography.bodyMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.read<StoreSelectionBloc>().add(const LoadUserStores());
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _showLogoutDialog(context),
            child: const Text('Logout'),
          ),
        ],
      ),
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

  Widget _buildStoreGrid(List<StoreSummary> stores) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: stores.length,
      itemBuilder: (context, index) {
        final store = stores[index];
        return _buildStoreCard(store);
      },
    );
  }

  Widget _buildStoreCard(StoreSummary store) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 2,
      color: isDark ? AppColors.surfaceDark : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          context.read<StoreSelectionBloc>().add(SelectStore(store.id));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryOrange.withOpacity(0.1),
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
              const SizedBox(height: 8),
              Text(
                store.name,
                style: AppTypography.titleLarge.copyWith(
                  fontSize: 14,
                  color: isDark
                      ? AppColors.textDarkPrimary
                      : AppColors.textPrimary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      store.address,
                      style: AppTypography.labelSmall.copyWith(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.secondaryTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.space_dashboard,
                      size: 14,
                      color: AppColors.secondaryTeal,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${store.spacesCount} spaces',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondaryTeal,
                        fontWeight: FontWeight.w600,
                      ),
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
}
