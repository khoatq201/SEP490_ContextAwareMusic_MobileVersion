enum SchedulingSlotOriginEnum {
  space(1, 'Space'),
  brand(2, 'Brand');

  const SchedulingSlotOriginEnum(this.value, this.label);

  final int value;
  final String label;

  static SchedulingSlotOriginEnum? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is int) return fromValue(json);
    if (json is num) return fromValue(json.toInt());
    if (json is String) {
      final parsed = int.tryParse(json);
      if (parsed != null) return fromValue(parsed);
      final normalized = json.trim().toLowerCase();
      for (final origin in SchedulingSlotOriginEnum.values) {
        if (origin.name.toLowerCase() == normalized ||
            origin.label.toLowerCase() == normalized) {
          return origin;
        }
      }
    }
    return null;
  }

  static SchedulingSlotOriginEnum? fromValue(int value) {
    for (final origin in SchedulingSlotOriginEnum.values) {
      if (origin.value == value) return origin;
    }
    return null;
  }
}
