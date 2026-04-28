/// Matches backend EntityStatusEnum: 0=Inactive, 1=Active, 2=Pending, 3=Rejected.
enum EntityStatusEnum {
  inactive(0),
  active(1),
  pending(2),
  rejected(3);

  const EntityStatusEnum(this.value);
  final int value;

  static EntityStatusEnum fromValue(int value) {
    return EntityStatusEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EntityStatusEnum.inactive,
    );
  }

  /// Parse from JSON (supports both int and string).
  static EntityStatusEnum fromJson(dynamic json) {
    if (json is int) return fromValue(json);
    if (json is String) {
      return EntityStatusEnum.values.firstWhere(
        (e) => e.name.toLowerCase() == json.toLowerCase(),
        orElse: () => EntityStatusEnum.inactive,
      );
    }
    return EntityStatusEnum.inactive;
  }

  String get displayName {
    switch (this) {
      case EntityStatusEnum.inactive:
        return 'Inactive';
      case EntityStatusEnum.active:
        return 'Active';
      case EntityStatusEnum.pending:
        return 'Pending';
      case EntityStatusEnum.rejected:
        return 'Rejected';
    }
  }

  bool get isActive => this == EntityStatusEnum.active;
}
