enum SpaceTypeEnum {
  counter(1, 'Counter'),
  hall(2, 'Hall'),
  entrance(3, 'Entrance'),
  outdoor(4, 'Outdoor'),
  kitchen(5, 'Kitchen'),
  restroom(6, 'Restroom');

  final int value;
  final String displayName;

  const SpaceTypeEnum(this.value, this.displayName);

  static SpaceTypeEnum fromValue(int? value) {
    return SpaceTypeEnum.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SpaceTypeEnum.hall, // Default fallback
    );
  }

  static SpaceTypeEnum fromName(String? name) {
    return SpaceTypeEnum.values.firstWhere(
      (e) => e.name.toLowerCase() == name?.toLowerCase(),
      orElse: () => SpaceTypeEnum.hall, // Default fallback
    );
  }
}
