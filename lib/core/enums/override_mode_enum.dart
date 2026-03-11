/// Matches backend OverrideModeEnum.
/// Used by CAMS override API.
enum OverrideModeEnum {
  directPlaylist(1),
  moodOverride(2);

  const OverrideModeEnum(this.value);
  final int value;

  static OverrideModeEnum fromValue(int value) {
    return OverrideModeEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => OverrideModeEnum.directPlaylist,
    );
  }

  static OverrideModeEnum? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is int) return fromValue(json);
    return null;
  }

  String get displayName {
    switch (this) {
      case OverrideModeEnum.directPlaylist:
        return 'Direct Playlist';
      case OverrideModeEnum.moodOverride:
        return 'Mood Override';
    }
  }
}
