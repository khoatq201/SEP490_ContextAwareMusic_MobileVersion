import 'package:equatable/equatable.dart';

import '../../../../core/enums/store_fuzzy_override_level_enum.dart';

class SunoBrandMusicProfile extends Equatable {
  final String? fuzzyProfileTemplate;
  final StoreFuzzyOverrideLevelEnum? storeOverrideLevel;
  final int? chillBpmMin;
  final int? chillBpmMax;
  final int? focusBpmMin;
  final int? focusBpmMax;
  final int? energeticBpmMin;
  final int? energeticBpmMax;
  final num? pressureLowMax;
  final num? pressureCriticalMin;
  final num? stressComfortableMax;
  final num? stressHighMin;
  final num? densitySparseMax;
  final num? densityCrowdedMin;
  final int? spaceCapacity;
  final num? defaultDensityRatioWhenNull;

  const SunoBrandMusicProfile({
    this.fuzzyProfileTemplate,
    this.storeOverrideLevel,
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
  });

  bool get hasAnyData =>
      (fuzzyProfileTemplate?.trim().isNotEmpty ?? false) ||
      storeOverrideLevel != null ||
      chillBpmMin != null ||
      chillBpmMax != null ||
      focusBpmMin != null ||
      focusBpmMax != null ||
      energeticBpmMin != null ||
      energeticBpmMax != null ||
      pressureLowMax != null ||
      pressureCriticalMin != null ||
      stressComfortableMax != null ||
      stressHighMin != null ||
      densitySparseMax != null ||
      densityCrowdedMin != null ||
      spaceCapacity != null ||
      defaultDensityRatioWhenNull != null;

  bool get hasCompleteBpmBands =>
      chillBpmMin != null &&
      chillBpmMax != null &&
      focusBpmMin != null &&
      focusBpmMax != null &&
      energeticBpmMin != null &&
      energeticBpmMax != null;

  SunoBrandMusicProfile copyWith({
    String? fuzzyProfileTemplate,
    StoreFuzzyOverrideLevelEnum? storeOverrideLevel,
    int? chillBpmMin,
    int? chillBpmMax,
    int? focusBpmMin,
    int? focusBpmMax,
    int? energeticBpmMin,
    int? energeticBpmMax,
    num? pressureLowMax,
    num? pressureCriticalMin,
    num? stressComfortableMax,
    num? stressHighMin,
    num? densitySparseMax,
    num? densityCrowdedMin,
    int? spaceCapacity,
    num? defaultDensityRatioWhenNull,
  }) {
    return SunoBrandMusicProfile(
      fuzzyProfileTemplate: fuzzyProfileTemplate ?? this.fuzzyProfileTemplate,
      storeOverrideLevel: storeOverrideLevel ?? this.storeOverrideLevel,
      chillBpmMin: chillBpmMin ?? this.chillBpmMin,
      chillBpmMax: chillBpmMax ?? this.chillBpmMax,
      focusBpmMin: focusBpmMin ?? this.focusBpmMin,
      focusBpmMax: focusBpmMax ?? this.focusBpmMax,
      energeticBpmMin: energeticBpmMin ?? this.energeticBpmMin,
      energeticBpmMax: energeticBpmMax ?? this.energeticBpmMax,
      pressureLowMax: pressureLowMax ?? this.pressureLowMax,
      pressureCriticalMin: pressureCriticalMin ?? this.pressureCriticalMin,
      stressComfortableMax:
          stressComfortableMax ?? this.stressComfortableMax,
      stressHighMin: stressHighMin ?? this.stressHighMin,
      densitySparseMax: densitySparseMax ?? this.densitySparseMax,
      densityCrowdedMin: densityCrowdedMin ?? this.densityCrowdedMin,
      spaceCapacity: spaceCapacity ?? this.spaceCapacity,
      defaultDensityRatioWhenNull:
          defaultDensityRatioWhenNull ?? this.defaultDensityRatioWhenNull,
    );
  }

  @override
  List<Object?> get props => [
        fuzzyProfileTemplate,
        storeOverrideLevel,
        chillBpmMin,
        chillBpmMax,
        focusBpmMin,
        focusBpmMax,
        energeticBpmMin,
        energeticBpmMax,
        pressureLowMax,
        pressureCriticalMin,
        stressComfortableMax,
        stressHighMin,
        densitySparseMax,
        densityCrowdedMin,
        spaceCapacity,
        defaultDensityRatioWhenNull,
      ];
}
