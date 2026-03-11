/// Matches backend MoodTypeEnum.
/// Maps to CAMS Engine: Calm→Chill(0), Energetic→Energetic(2), Focus→Focus(1).
enum MoodTypeEnum {
  calm(1),
  energetic(2),
  focus(3),
  social(4),
  romantic(5),
  uplifting(6);

  const MoodTypeEnum(this.value);
  final int value;

  static MoodTypeEnum fromValue(int value) {
    return MoodTypeEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MoodTypeEnum.calm,
    );
  }

  static MoodTypeEnum? fromJson(dynamic json) {
    if (json == null) return null;
    if (json is int) return fromValue(json);
    return null;
  }

  String get displayName {
    switch (this) {
      case MoodTypeEnum.calm:
        return 'Calm';
      case MoodTypeEnum.energetic:
        return 'Energetic';
      case MoodTypeEnum.focus:
        return 'Focus';
      case MoodTypeEnum.social:
        return 'Social';
      case MoodTypeEnum.romantic:
        return 'Romantic';
      case MoodTypeEnum.uplifting:
        return 'Uplifting';
    }
  }
}
