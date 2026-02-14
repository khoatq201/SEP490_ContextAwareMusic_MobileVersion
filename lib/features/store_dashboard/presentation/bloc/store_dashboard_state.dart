import 'package:equatable/equatable.dart';
import '../../domain/entities/store.dart';
import '../../domain/entities/space_summary.dart';

enum StoreDashboardStatus { initial, loading, loaded, error }

class StoreDashboardState extends Equatable {
  final StoreDashboardStatus status;
  final Store? store;
  final List<SpaceSummary> spaces;
  final String? errorMessage;

  const StoreDashboardState({
    this.status = StoreDashboardStatus.initial,
    this.store,
    this.spaces = const [],
    this.errorMessage,
  });

  StoreDashboardState copyWith({
    StoreDashboardStatus? status,
    Store? store,
    List<SpaceSummary>? spaces,
    String? errorMessage,
  }) {
    return StoreDashboardState(
      status: status ?? this.status,
      store: store ?? this.store,
      spaces: spaces ?? this.spaces,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, store, spaces, errorMessage];
}
