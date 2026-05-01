import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/brand_detail.dart';
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
    this.brandDetail,
    this.brandDetailFailure,
    this.isBrandDetailLoading = false,
  });

  final List<StoreSummary> stores;
  final List<StoreSummary> filteredStores;
  final String searchQuery;
  final BrandDetail? brandDetail;
  final Failure? brandDetailFailure;
  final bool isBrandDetailLoading;

  @override
  List<Object?> get props => [
        stores,
        filteredStores,
        searchQuery,
        brandDetail,
        brandDetailFailure,
        isBrandDetailLoading,
      ];

  StoreSelectionLoaded copyWith({
    List<StoreSummary>? stores,
    List<StoreSummary>? filteredStores,
    String? searchQuery,
    BrandDetail? brandDetail,
    Failure? brandDetailFailure,
    bool? isBrandDetailLoading,
    bool clearBrandDetailFailure = false,
  }) {
    return StoreSelectionLoaded(
      stores: stores ?? this.stores,
      filteredStores: filteredStores ?? this.filteredStores,
      searchQuery: searchQuery ?? this.searchQuery,
      brandDetail: brandDetail ?? this.brandDetail,
      brandDetailFailure: clearBrandDetailFailure
          ? null
          : brandDetailFailure ?? this.brandDetailFailure,
      isBrandDetailLoading: isBrandDetailLoading ?? this.isBrandDetailLoading,
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
