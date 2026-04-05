import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/store_summary.dart';

abstract class StoreSelectionState extends Equatable {
  const StoreSelectionState();

  @override
  List<Object?> get props => [];
}

class StoreSelectionInitial extends StoreSelectionState {}

class StoreSelectionLoading extends StoreSelectionState {}

class StoreSelectionLoaded extends StoreSelectionState {
  const StoreSelectionLoaded({
    required this.stores,
    required this.filteredStores,
    this.searchQuery = '',
  });

  final List<StoreSummary> stores;
  final List<StoreSummary> filteredStores;
  final String searchQuery;

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
  const StoreSelectionError(this.failure);

  final Failure failure;

  String get message => failure.message;

  @override
  List<Object?> get props => [failure];
}

class StoreSelected extends StoreSelectionState {
  const StoreSelected(this.storeId);

  final String storeId;

  @override
  List<Object?> get props => [storeId];
}
