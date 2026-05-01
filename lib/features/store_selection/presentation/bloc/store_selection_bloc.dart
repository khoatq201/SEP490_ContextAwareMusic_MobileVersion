import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/session_data_cache.dart';
import '../../domain/entities/brand_detail.dart';
import '../../domain/entities/store_summary.dart';
import '../../domain/usecases/get_brand_detail.dart';
import '../../domain/usecases/get_user_stores.dart';
import 'store_selection_event.dart';
import 'store_selection_state.dart';

class StoreSelectionBloc
    extends Bloc<StoreSelectionEvent, StoreSelectionState> {
  final GetUserStores getUserStores;
  final GetBrandDetail getBrandDetail;
  final SessionDataCache? sessionDataCache;

  StoreSelectionBloc({
    required this.getUserStores,
    required this.getBrandDetail,
    this.sessionDataCache,
  }) : super(StoreSelectionInitial()) {
    on<LoadUserStores>(_onLoadUserStores);
    on<SelectStore>(_onSelectStore);
    on<SearchStores>(_onSearchStores);
    on<LoadBrandDetail>(_onLoadBrandDetail);
  }

  Future<void> _onLoadUserStores(
    LoadUserStores event,
    Emitter<StoreSelectionState> emit,
  ) async {
    const cacheKey = 'storeSelection.userStores';
    if (!event.forceRefresh) {
      final cached = sessionDataCache?.get<List<StoreSummary>>(cacheKey);
      if (cached != null) {
        emit(StoreSelectionLoaded(
          stores: cached,
          filteredStores: cached,
        ));
        final brandId = _normalizeId(event.preferredBrandId) ??
            _resolvePrimaryBrandId(cached);
        if (brandId != null) {
          add(LoadBrandDetail(brandId));
        }
        return;
      }
    }

    if (state is! StoreSelectionLoaded) {
      emit(StoreSelectionLoading());
    }

    final result = await getUserStores();

    result.fold(
      (failure) => emit(StoreSelectionError(failure)),
      (stores) {
        sessionDataCache?.put(cacheKey, stores);
        emit(StoreSelectionLoaded(
          stores: stores,
          filteredStores: stores,
        ));
        final brandId = _normalizeId(event.preferredBrandId) ??
            _resolvePrimaryBrandId(stores);
        if (brandId != null) {
          add(LoadBrandDetail(brandId));
        }
      },
    );
  }

  void _onSelectStore(
    SelectStore event,
    Emitter<StoreSelectionState> emit,
  ) {
    emit(StoreSelected(event.storeId));
  }

  void _onSearchStores(
    SearchStores event,
    Emitter<StoreSelectionState> emit,
  ) {
    final currentState = state;
    if (currentState is StoreSelectionLoaded) {
      final query = event.query.toLowerCase();

      if (query.isEmpty) {
        emit(currentState.copyWith(
          filteredStores: currentState.stores,
          searchQuery: '',
        ));
      } else {
        final filtered = currentState.stores.where((store) {
          return store.name.toLowerCase().contains(query) ||
              store.fullAddress.toLowerCase().contains(query);
        }).toList();

        emit(currentState.copyWith(
          filteredStores: filtered,
          searchQuery: query,
        ));
      }
    }
  }

  Future<void> _onLoadBrandDetail(
    LoadBrandDetail event,
    Emitter<StoreSelectionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! StoreSelectionLoaded) return;
    final cacheKey = 'storeSelection.brandDetail.${event.brandId}';

    if (!event.forceRefresh) {
      final cached = sessionDataCache?.get<BrandDetail>(cacheKey);
      if (cached != null) {
        emit(currentState.copyWith(
          brandDetail: cached,
          isBrandDetailLoading: false,
          clearBrandDetailFailure: true,
        ));
        return;
      }
    }

    emit(currentState.copyWith(
      isBrandDetailLoading: true,
      clearBrandDetailFailure: true,
    ));

    final result = await getBrandDetail(event.brandId);
    final latestState = state;
    if (latestState is! StoreSelectionLoaded) return;

    result.fold(
      (failure) => emit(latestState.copyWith(
        brandDetailFailure: failure,
        isBrandDetailLoading: false,
      )),
      (brandDetail) {
        sessionDataCache?.put(cacheKey, brandDetail);
        emit(latestState.copyWith(
          brandDetail: brandDetail,
          isBrandDetailLoading: false,
          clearBrandDetailFailure: true,
        ));
      },
    );
  }

  String? _resolvePrimaryBrandId(List<StoreSummary> stores) {
    for (final store in stores) {
      final brandId = _normalizeId(store.brandId);
      if (brandId != null) return brandId;
    }
    return null;
  }

  String? _normalizeId(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }
}
