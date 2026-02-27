import 'package:equatable/equatable.dart';

import '../../domain/entities/settings_snapshot.dart';

enum SettingsStatus { initial, loading, loaded, error }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final SettingsSnapshot? snapshot;
  final String? errorMessage;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.snapshot,
    this.errorMessage,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    SettingsSnapshot? snapshot,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SettingsState(
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, snapshot, errorMessage];
}
