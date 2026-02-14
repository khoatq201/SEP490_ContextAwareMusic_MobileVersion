import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_user_stores.dart';
import 'store_selection_event.dart';
import 'store_selection_state.dart';

class StoreSelectionBloc
    extends Bloc<StoreSelectionEvent, StoreSelectionState> {
  final GetUserStores getUserStores;

  StoreSelectionBloc({
    required this.getUserStores,
  }) : super(StoreSelectionInitial()) {
    on<LoadUserStores>(_onLoadUserStores);
    on<SelectStore>(_onSelectStore);
    on<SearchStores>(_onSearchStores);
  }

  Future<void> _onLoadUserStores(
    LoadUserStores event,
    Emitter<StoreSelectionState> emit,
  ) async {
    emit(StoreSelectionLoading());

    final result = await getUserStores(event.storeIds);

    result.fold(
      (failure) => emit(StoreSelectionError(failure.message)),
      (stores) => emit(StoreSelectionLoaded(
        stores: stores,
        filteredStores: stores,
      )),
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
              store.address.toLowerCase().contains(query);
        }).toList();

        emit(currentState.copyWith(
          filteredStores: filtered,
          searchQuery: query,
        ));
      }
    }
  }
}
