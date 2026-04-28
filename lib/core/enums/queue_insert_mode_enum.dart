/// Matches backend QueueInsertModeEnum.
enum QueueInsertModeEnum {
  playNow(1),
  playNext(2),
  addToQueue(3);

  const QueueInsertModeEnum(this.value);
  final int value;
}
