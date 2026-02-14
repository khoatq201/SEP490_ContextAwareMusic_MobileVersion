import 'package:equatable/equatable.dart';

abstract class StoreDashboardEvent extends Equatable {
  const StoreDashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadStoreDashboard extends StoreDashboardEvent {
  final String storeId;

  const LoadStoreDashboard({required this.storeId});

  @override
  List<Object?> get props => [storeId];
}

class RefreshStoreDashboard extends StoreDashboardEvent {
  final String storeId;

  const RefreshStoreDashboard({required this.storeId});

  @override
  List<Object?> get props => [storeId];
}
