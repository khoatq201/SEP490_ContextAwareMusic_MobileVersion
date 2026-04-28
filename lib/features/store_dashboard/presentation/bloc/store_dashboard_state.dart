import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/presentation/app_feedback.dart';
import '../../domain/entities/store.dart';
import '../../domain/entities/space_summary.dart';

enum StoreDashboardStatus { initial, loading, loaded, error }

class StoreDashboardState extends Equatable {
  const StoreDashboardState({
    this.status = StoreDashboardStatus.initial,
    this.store,
    this.spaces = const [],
    this.failure,
    this.feedback,
  });

  final StoreDashboardStatus status;
  final Store? store;
  final List<SpaceSummary> spaces;
  final Failure? failure;
  final AppFeedback? feedback;

  String? get errorMessage => failure?.message;

  StoreDashboardState copyWith({
    StoreDashboardStatus? status,
    Store? store,
    bool clearStore = false,
    List<SpaceSummary>? spaces,
    Failure? failure,
    bool clearFailure = false,
    AppFeedback? feedback,
    bool clearFeedback = false,
  }) {
    return StoreDashboardState(
      status: status ?? this.status,
      store: clearStore ? null : (store ?? this.store),
      spaces: spaces ?? this.spaces,
      failure: clearFailure ? null : (failure ?? this.failure),
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
    );
  }

  @override
  List<Object?> get props => [status, store, spaces, failure, feedback];
}
