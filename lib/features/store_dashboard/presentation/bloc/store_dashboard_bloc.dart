import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failure_kind.dart';
import '../../../../core/presentation/app_feedback.dart';
import '../../../../core/services/session_data_cache.dart';
import '../../domain/entities/space_summary.dart';
import '../../domain/entities/store.dart';
import '../../domain/usecases/get_space_summaries.dart';
import '../../domain/usecases/get_store_details.dart';
import 'store_dashboard_event.dart';
import 'store_dashboard_state.dart';

class StoreDashboardBloc
    extends Bloc<StoreDashboardEvent, StoreDashboardState> {
  StoreDashboardBloc({
    required this.getStoreDetails,
    required this.getSpaceSummaries,
    this.sessionDataCache,
  }) : super(const StoreDashboardState()) {
    on<LoadStoreDashboard>(_onLoadStoreDashboard);
    on<RefreshStoreDashboard>(_onRefreshStoreDashboard);
  }

  final GetStoreDetails getStoreDetails;
  final GetSpaceSummaries getSpaceSummaries;
  final SessionDataCache? sessionDataCache;

  Future<void> _onLoadStoreDashboard(
    LoadStoreDashboard event,
    Emitter<StoreDashboardState> emit,
  ) async {
    final cached = _cachedDashboard(event.storeId);
    if (!event.forceRefresh && cached != null) {
      emit(cached);
      return;
    }

    emit(
      state.copyWith(
        status: StoreDashboardStatus.loading,
        clearFailure: true,
        clearFeedback: true,
      ),
    );

    final storeResult = await getStoreDetails(event.storeId);
    final spacesResult = await getSpaceSummaries(event.storeId);

    storeResult.fold(
      (failure) => emit(
        state.copyWith(
          status: StoreDashboardStatus.error,
          failure: failure,
          clearFeedback: true,
        ),
      ),
      (store) {
        spacesResult.fold(
          (failure) {
            if (failure.kind == FailureKind.forbidden) {
              emit(
                state.copyWith(
                  status: StoreDashboardStatus.loaded,
                  store: store,
                  spaces: const [],
                  clearFailure: true,
                  feedback: AppFeedback.warning(
                    'Store loaded, but the backend denied the spaces request for this account. '
                    'This usually means the `/api/spaces` permission does not match the docs for StoreManager.',
                    title: 'Spaces unavailable',
                  ),
                ),
              );
              return;
            }

            emit(
              state.copyWith(
                status: StoreDashboardStatus.error,
                failure: failure,
                clearFeedback: true,
              ),
            );
          },
          (spaces) {
            final next = state.copyWith(
              status: StoreDashboardStatus.loaded,
              store: store,
              spaces: spaces,
              clearFailure: true,
              clearFeedback: true,
            );
            _cacheDashboard(event.storeId, store, spaces);
            emit(next);
          },
        );
      },
    );
  }

  Future<void> _onRefreshStoreDashboard(
    RefreshStoreDashboard event,
    Emitter<StoreDashboardState> emit,
  ) async {
    emit(state.copyWith(clearFeedback: true));

    final storeResult = await getStoreDetails(event.storeId);
    final spacesResult = await getSpaceSummaries(event.storeId);

    storeResult.fold(
      (failure) => emit(
        state.copyWith(
          feedback: AppFeedback.fromFailure(
            failure,
            title: 'Refresh failed',
          ),
        ),
      ),
      (store) {
        spacesResult.fold(
          (failure) {
            if (failure.kind == FailureKind.forbidden) {
              emit(
                state.copyWith(
                  store: store,
                  spaces: const [],
                  clearFailure: true,
                  feedback: AppFeedback.warning(
                    'Store refreshed, but the backend denied the spaces request for this account.',
                    title: 'Spaces unavailable',
                  ),
                ),
              );
              return;
            }

            emit(
              state.copyWith(
                store: store,
                feedback: AppFeedback.fromFailure(
                  failure,
                  title: 'Refresh failed',
                ),
              ),
            );
          },
          (spaces) {
            _cacheDashboard(event.storeId, store, spaces);
            emit(
              state.copyWith(
                status: StoreDashboardStatus.loaded,
                store: store,
                spaces: spaces,
                clearFailure: true,
                clearFeedback: true,
              ),
            );
          },
        );
      },
    );
  }

  StoreDashboardState? _cachedDashboard(String storeId) {
    final store = sessionDataCache?.get<Store>('storeDashboard.$storeId.store');
    final spaces = sessionDataCache
        ?.get<List<SpaceSummary>>('storeDashboard.$storeId.spaces');
    if (store == null || spaces == null) return null;
    return StoreDashboardState(
      status: StoreDashboardStatus.loaded,
      store: store,
      spaces: spaces,
    );
  }

  void _cacheDashboard(
    String storeId,
    Store store,
    List<SpaceSummary> spaces,
  ) {
    sessionDataCache?.put('storeDashboard.$storeId.store', store);
    sessionDataCache?.put('storeDashboard.$storeId.spaces', spaces);
  }
}
