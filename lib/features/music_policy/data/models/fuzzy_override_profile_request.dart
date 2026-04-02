class FuzzyOverrideProfileRequest {
  final String? name;
  final int? chillBpmMin;
  final int? chillBpmMax;
  final int? focusBpmMin;
  final int? focusBpmMax;
  final int? energeticBpmMin;
  final int? energeticBpmMax;
  final double? pressureLowMax;
  final double? pressureCriticalMin;
  final double? stressComfortableMax;
  final double? stressHighMin;
  final double? densitySparseMax;
  final double? densityCrowdedMin;
  final int? spaceCapacity;
  final double? defaultDensityRatioWhenNull;
  final List<String>? allowedPlaylistIds;

  const FuzzyOverrideProfileRequest({
    this.name,
    this.chillBpmMin,
    this.chillBpmMax,
    this.focusBpmMin,
    this.focusBpmMax,
    this.energeticBpmMin,
    this.energeticBpmMax,
    this.pressureLowMax,
    this.pressureCriticalMin,
    this.stressComfortableMax,
    this.stressHighMin,
    this.densitySparseMax,
    this.densityCrowdedMin,
    this.spaceCapacity,
    this.defaultDensityRatioWhenNull,
    this.allowedPlaylistIds,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null && name!.trim().isNotEmpty) 'name': name!.trim(),
      if (chillBpmMin != null) 'chillBpmMin': chillBpmMin,
      if (chillBpmMax != null) 'chillBpmMax': chillBpmMax,
      if (focusBpmMin != null) 'focusBpmMin': focusBpmMin,
      if (focusBpmMax != null) 'focusBpmMax': focusBpmMax,
      if (energeticBpmMin != null) 'energeticBpmMin': energeticBpmMin,
      if (energeticBpmMax != null) 'energeticBpmMax': energeticBpmMax,
      if (pressureLowMax != null) 'pressureLowMax': pressureLowMax,
      if (pressureCriticalMin != null)
        'pressureCriticalMin': pressureCriticalMin,
      if (stressComfortableMax != null)
        'stressComfortableMax': stressComfortableMax,
      if (stressHighMin != null) 'stressHighMin': stressHighMin,
      if (densitySparseMax != null) 'densitySparseMax': densitySparseMax,
      if (densityCrowdedMin != null) 'densityCrowdedMin': densityCrowdedMin,
      if (spaceCapacity != null) 'spaceCapacity': spaceCapacity,
      if (defaultDensityRatioWhenNull != null)
        'defaultDensityRatioWhenNull': defaultDensityRatioWhenNull,
      if (allowedPlaylistIds != null) 'allowedPlaylistIds': allowedPlaylistIds,
    };
  }
}
