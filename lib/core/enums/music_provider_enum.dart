/// Matches backend MusicProviderEnum.
enum MusicProviderEnum {
  custom(0),
  suno(1);

  const MusicProviderEnum(this.value);
  final int value;

  static MusicProviderEnum fromValue(int value) {
    return MusicProviderEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MusicProviderEnum.custom,
    );
  }

  static MusicProviderEnum? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is int) return fromValue(json);
    return null;
  }

  String get displayName {
    switch (this) {
      case MusicProviderEnum.custom:
        return 'Custom Upload';
      case MusicProviderEnum.suno:
        return 'Suno AI';
    }
  }
}
