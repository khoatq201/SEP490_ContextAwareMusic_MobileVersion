import 'package:equatable/equatable.dart';

abstract class StoreSelectionEvent extends Equatable {
  const StoreSelectionEvent();

  @override
  List<Object> get props => [];
}

class LoadUserStores extends StoreSelectionEvent {
  final List<String> storeIds;

  const LoadUserStores(this.storeIds);

  @override
  List<Object> get props => [storeIds];
}

class SelectStore extends StoreSelectionEvent {
  final String storeId;

  const SelectStore(this.storeId);

  @override
  List<Object> get props => [storeId];
}

class SearchStores extends StoreSelectionEvent {
  final String query;

  const SearchStores(this.query);

  @override
  List<Object> get props => [query];
}
