/// Matches backend TransitionTypeEnum.
/// Used in SignalR PlayStream events.
enum TransitionTypeEnum {
  immediate(1),
  crossfade(2),
  pending(3),
  queued(4);

  const TransitionTypeEnum(this.value);
  final int value;

  static TransitionTypeEnum fromValue(int value) {
    return TransitionTypeEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TransitionTypeEnum.immediate,
    );
  }

  static TransitionTypeEnum? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is int) return fromValue(json);
    return null;
  }

  String get displayName {
    switch (this) {
      case TransitionTypeEnum.immediate:
        return 'Immediate';
      case TransitionTypeEnum.crossfade:
        return 'Crossfade';
      case TransitionTypeEnum.pending:
        return 'Pending';
      case TransitionTypeEnum.queued:
        return 'Queued';
    }
  }
}
