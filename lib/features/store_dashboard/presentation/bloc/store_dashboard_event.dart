import 'package:equatable/equatable.dart';

abstract class StoreDashboardEvent extends Equatable {
  const StoreDashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadStoreDashboard extends StoreDashboardEvent {
  final String storeId;
  final bool forceRefresh;

  const LoadStoreDashboard({
    required this.storeId,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [storeId, forceRefresh];
}

class RefreshStoreDashboard extends StoreDashboardEvent {
  final String storeId;

  const RefreshStoreDashboard({required this.storeId});

  @override
  List<Object?> get props => [storeId];
}
