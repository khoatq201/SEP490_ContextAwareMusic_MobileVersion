import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_store_details.dart';
import '../../domain/usecases/get_space_summaries.dart';
import 'store_dashboard_event.dart';
import 'store_dashboard_state.dart';

class StoreDashboardBloc
    extends Bloc<StoreDashboardEvent, StoreDashboardState> {
  final GetStoreDetails getStoreDetails;
  final GetSpaceSummaries getSpaceSummaries;

  StoreDashboardBloc({
    required this.getStoreDetails,
    required this.getSpaceSummaries,
  }) : super(const StoreDashboardState()) {
    on<LoadStoreDashboard>(_onLoadStoreDashboard);
    on<RefreshStoreDashboard>(_onRefreshStoreDashboard);
  }

  Future<void> _onLoadStoreDashboard(
    LoadStoreDashboard event,
    Emitter<StoreDashboardState> emit,
  ) async {
    emit(state.copyWith(status: StoreDashboardStatus.loading));

    // Load store details and space summaries in parallel
    final storeResult = await getStoreDetails(event.storeId);
    final spacesResult = await getSpaceSummaries(event.storeId);

    storeResult.fold(
      (failure) {
        emit(state.copyWith(
          status: StoreDashboardStatus.error,
          errorMessage: failure.message,
        ));
      },
      (store) {
        spacesResult.fold(
          (failure) {
            emit(state.copyWith(
              status: StoreDashboardStatus.error,
              errorMessage: failure.message,
            ));
          },
          (spaces) {
            emit(state.copyWith(
              status: StoreDashboardStatus.loaded,
              store: store,
              spaces: spaces,
            ));
          },
        );
      },
    );
  }

  Future<void> _onRefreshStoreDashboard(
    RefreshStoreDashboard event,
    Emitter<StoreDashboardState> emit,
  ) async {
    // Load space summaries without changing status to loading
    final spacesResult = await getSpaceSummaries(event.storeId);

    spacesResult.fold(
      (failure) {
        // Keep current state, just show error
        emit(state.copyWith(errorMessage: failure.message));
      },
      (spaces) {
        emit(state.copyWith(
          spaces: spaces,
          errorMessage: null,
        ));
      },
    );
  }
}
