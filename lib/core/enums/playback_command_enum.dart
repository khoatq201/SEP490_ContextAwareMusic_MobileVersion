/// Matches backend PlaybackCommandEnum.
/// Used in CAMS playback API and SignalR PlaybackStateChanged events.
enum PlaybackCommandEnum {
  pause(1),
  resume(2),
  seek(3),
  seekForward(4),
  seekBackward(5),
  skipNext(6),
  skipPrevious(7),
  skipToTrack(8);

  const PlaybackCommandEnum(this.value);
  final int value;

  static PlaybackCommandEnum fromValue(int value) {
    return PlaybackCommandEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PlaybackCommandEnum.pause,
    );
  }

  static PlaybackCommandEnum? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is int) return fromValue(json);
    return null;
  }

  String get displayName {
    switch (this) {
      case PlaybackCommandEnum.pause:
        return 'Pause';
      case PlaybackCommandEnum.resume:
        return 'Resume';
      case PlaybackCommandEnum.seek:
        return 'Seek';
      case PlaybackCommandEnum.seekForward:
        return 'Seek Forward';
      case PlaybackCommandEnum.seekBackward:
        return 'Seek Backward';
      case PlaybackCommandEnum.skipNext:
        return 'Skip Next';
      case PlaybackCommandEnum.skipPrevious:
        return 'Skip Previous';
      case PlaybackCommandEnum.skipToTrack:
        return 'Skip To Track';
    }
  }
}
