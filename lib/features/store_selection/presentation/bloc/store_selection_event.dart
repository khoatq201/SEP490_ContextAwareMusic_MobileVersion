import 'package:equatable/equatable.dart';

abstract class StoreSelectionEvent extends Equatable {
  const StoreSelectionEvent();

  @override
  List<Object> get props => [];
}

class LoadUserStores extends StoreSelectionEvent {
  const LoadUserStores({
    this.preferredBrandId,
    this.forceRefresh = false,
  });

  final String? preferredBrandId;
  final bool forceRefresh;

  @override
  List<Object> get props => [
        if (preferredBrandId != null) preferredBrandId!,
        forceRefresh,
      ];
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

class LoadBrandDetail extends StoreSelectionEvent {
  final String brandId;
  final bool forceRefresh;

  const LoadBrandDetail(this.brandId, {this.forceRefresh = false});

  @override
  List<Object> get props => [brandId, forceRefresh];
}
