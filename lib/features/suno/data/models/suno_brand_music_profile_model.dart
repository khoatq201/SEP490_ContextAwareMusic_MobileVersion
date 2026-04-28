import '../../../../core/enums/store_fuzzy_override_level_enum.dart';
import '../../domain/entities/suno_brand_music_profile.dart';

class SunoBrandMusicProfileModel extends SunoBrandMusicProfile {
  const SunoBrandMusicProfileModel({
    super.fuzzyProfileTemplate,
    super.storeOverrideLevel,
    super.chillBpmMin,
    super.chillBpmMax,
    super.focusBpmMin,
    super.focusBpmMax,
    super.energeticBpmMin,
    super.energeticBpmMax,
    super.pressureLowMax,
    super.pressureCriticalMin,
    super.stressComfortableMax,
    super.stressHighMin,
    super.densitySparseMax,
    super.densityCrowdedMin,
    super.spaceCapacity,
    super.defaultDensityRatioWhenNull,
  });

  factory SunoBrandMusicProfileModel.fromJson(Map<String, dynamic> json) {
    return SunoBrandMusicProfileModel(
      fuzzyProfileTemplate: _readString(json, const [
        'fuzzyProfileTemplate',
        'defaultFuzzyProfileTemplate',
        'brandMusicProfileTemplate',
        'templateName',
        'profileTemplate',
      ]),
      storeOverrideLevel: _readOverrideLevel(json),
      chillBpmMin: _readInt(json, const ['chillBpmMin']),
      chillBpmMax: _readInt(json, const ['chillBpmMax']),
      focusBpmMin: _readInt(json, const ['focusBpmMin']),
      focusBpmMax: _readInt(json, const ['focusBpmMax']),
      energeticBpmMin: _readInt(json, const ['energeticBpmMin']),
      energeticBpmMax: _readInt(json, const ['energeticBpmMax']),
      pressureLowMax: _readNum(json, const ['pressureLowMax']),
      pressureCriticalMin: _readNum(json, const ['pressureCriticalMin']),
      stressComfortableMax: _readNum(json, const ['stressComfortableMax']),
      stressHighMin: _readNum(json, const ['stressHighMin']),
      densitySparseMax: _readNum(json, const ['densitySparseMax']),
      densityCrowdedMin: _readNum(json, const ['densityCrowdedMin']),
      spaceCapacity: _readInt(json, const ['spaceCapacity']),
      defaultDensityRatioWhenNull:
          _readNum(json, const ['defaultDensityRatioWhenNull']),
    );
  }

  static SunoBrandMusicProfile? fromRootJson(Map<String, dynamic> json) {
    for (final key in const [
      'brandMusicProfile',
      'musicProfile',
      'brandMusicPolicy',
    ]) {
      final candidate = json[key];
      if (candidate is Map<String, dynamic>) {
        final parsed = SunoBrandMusicProfileModel.fromJson(candidate);
        if (parsed.hasAnyData) {
          return parsed;
        }
      } else if (candidate is Map) {
        final parsed = SunoBrandMusicProfileModel.fromJson(
          Map<String, dynamic>.from(candidate),
        );
        if (parsed.hasAnyData) {
          return parsed;
        }
      }
    }

    final flattened = SunoBrandMusicProfileModel.fromJson(json);
    return flattened.hasAnyData ? flattened : null;
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = num.tryParse(value);
        if (parsed != null) return parsed.toInt();
      }
    }
    return null;
  }

  static num? _readNum(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value;
      if (value is String) {
        final parsed = num.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }

  static StoreFuzzyOverrideLevelEnum? _readOverrideLevel(
    Map<String, dynamic> json,
  ) {
    for (final key in const [
      'storeOverrideLevel',
      'overrideLevel',
      'fuzzyOverrideLevel',
    ]) {
      final value = json[key];
      if (value == null) continue;
      final parsed = StoreFuzzyOverrideLevelEnum.fromJson(value);
      if (parsed != StoreFuzzyOverrideLevelEnum.unknown) {
        return parsed;
      }
    }
    return null;
  }
}
