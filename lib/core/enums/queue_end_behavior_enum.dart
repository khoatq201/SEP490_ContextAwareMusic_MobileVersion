enum QueueEndBehaviorEnum {
  stop(0, 'Stop'),
  repeatAll(1, 'Repeat all'),
  repeatOne(2, 'Repeat one');

  const QueueEndBehaviorEnum(this.value, this.label);

  final int value;
  final String label;

  static QueueEndBehaviorEnum fromValue(int? value) {
    for (final behavior in QueueEndBehaviorEnum.values) {
      if (behavior.value == value) {
        return behavior;
      }
    }
    return QueueEndBehaviorEnum.stop;
  }
}
