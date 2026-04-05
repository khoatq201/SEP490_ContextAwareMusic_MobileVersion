import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/app_feedback.dart';
import '../../domain/usecases/get_space_summaries.dart';
import '../../domain/usecases/get_store_details.dart';
import 'store_dashboard_event.dart';
import 'store_dashboard_state.dart';

class StoreDashboardBloc
    extends Bloc<StoreDashboardEvent, StoreDashboardState> {
  StoreDashboardBloc({
    required this.getStoreDetails,
    required this.getSpaceSummaries,
  }) : super(const StoreDashboardState()) {
    on<LoadStoreDashboard>(_onLoadStoreDashboard);
    on<RefreshStoreDashboard>(_onRefreshStoreDashboard);
  }

  final GetStoreDetails getStoreDetails;
  final GetSpaceSummaries getSpaceSummaries;

  Future<void> _onLoadStoreDashboard(
    LoadStoreDashboard event,
    Emitter<StoreDashboardState> emit,
  ) async {
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
          (failure) => emit(
            state.copyWith(
              status: StoreDashboardStatus.error,
              failure: failure,
              clearFeedback: true,
            ),
          ),
          (spaces) => emit(
            state.copyWith(
              status: StoreDashboardStatus.loaded,
              store: store,
              spaces: spaces,
              clearFailure: true,
              clearFeedback: true,
            ),
          ),
        );
      },
    );
  }

  Future<void> _onRefreshStoreDashboard(
    RefreshStoreDashboard event,
    Emitter<StoreDashboardState> emit,
  ) async {
    emit(state.copyWith(clearFeedback: true));
    final spacesResult = await getSpaceSummaries(event.storeId);

    spacesResult.fold(
      (failure) => emit(
        state.copyWith(
          feedback: AppFeedback.fromFailure(
            failure,
            title: 'Refresh failed',
          ),
        ),
      ),
      (spaces) => emit(
        state.copyWith(
          spaces: spaces,
          clearFailure: true,
          clearFeedback: true,
        ),
      ),
    );
  }
}
