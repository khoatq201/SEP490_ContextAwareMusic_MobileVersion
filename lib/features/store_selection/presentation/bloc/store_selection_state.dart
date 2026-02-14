import 'package:equatable/equatable.dart';
import '../../domain/entities/store_summary.dart';

abstract class StoreSelectionState extends Equatable {
  const StoreSelectionState();

  @override
  List<Object?> get props => [];
}

class StoreSelectionInitial extends StoreSelectionState {}

class StoreSelectionLoading extends StoreSelectionState {}

class StoreSelectionLoaded extends StoreSelectionState {
  final List<StoreSummary> stores;
  final List<StoreSummary> filteredStores;
  final String searchQuery;

  const StoreSelectionLoaded({
    required this.stores,
    required this.filteredStores,
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [stores, filteredStores, searchQuery];

  StoreSelectionLoaded copyWith({
    List<StoreSummary>? stores,
    List<StoreSummary>? filteredStores,
    String? searchQuery,
  }) {
    return StoreSelectionLoaded(
      stores: stores ?? this.stores,
      filteredStores: filteredStores ?? this.filteredStores,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class StoreSelectionError extends StoreSelectionState {
  final String message;

  const StoreSelectionError(this.message);

  @override
  List<Object?> get props => [message];
}

class StoreSelected extends StoreSelectionState {
  final String storeId;

  const StoreSelected(this.storeId);

  @override
  List<Object?> get props => [storeId];
}
