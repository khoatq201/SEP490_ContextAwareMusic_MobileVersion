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
    if (json is String) {
      final parsedValue = int.tryParse(json);
      if (parsedValue != null) return fromValue(parsedValue);
      return MusicProviderEnum.values.firstWhere(
        (provider) => provider.name.toLowerCase() == json.toLowerCase(),
        orElse: () => MusicProviderEnum.custom,
      );
    }
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
