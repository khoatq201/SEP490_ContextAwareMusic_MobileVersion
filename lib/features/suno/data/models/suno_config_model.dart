import '../../../../core/enums/ai_generation_mode_enum.dart';
import '../../../../core/enums/store_fuzzy_override_level_enum.dart';
import '../../domain/entities/suno_config.dart';
import 'suno_brand_music_profile_model.dart';

class SunoConfigModel extends SunoConfig {
  const SunoConfigModel({
    super.brandId,
    super.sunoPromptTemplate,
    super.sunoDefaultPlaylistId,
    super.aiGenerationMode,
    super.availableGenerationModes,
    super.brandMusicProfile,
    super.fuzzyProfileTemplate,
    super.availableFuzzyProfileTemplates,
    super.recommendedBpmMin,
    super.recommendedBpmMax,
    super.recommendedBpmTarget,
    super.fuzzyOverrideLevel,
  });

  factory SunoConfigModel.fromJson(Map<String, dynamic> json) {
    final brandMusicProfile = SunoBrandMusicProfileModel.fromRootJson(json);

    return SunoConfigModel(
      brandId: json['brandId']?.toString(),
      sunoPromptTemplate: json['sunoPromptTemplate']?.toString(),
      sunoDefaultPlaylistId: json['sunoDefaultPlaylistId']?.toString(),
      aiGenerationMode: _readGenerationMode(json),
      availableGenerationModes: _readGenerationModes(json),
      brandMusicProfile: brandMusicProfile,
      fuzzyProfileTemplate: _readString(json, const [
        'fuzzyProfileTemplate',
        'defaultFuzzyProfileTemplate',
        'brandMusicProfileTemplate',
      ]) ??
          brandMusicProfile?.fuzzyProfileTemplate,
      availableFuzzyProfileTemplates: _readStringList(json, const [
        'availableFuzzyProfileTemplates',
        'fuzzyProfileTemplates',
        'musicProfileTemplates',
      ]),
      recommendedBpmMin: _readNum(json, const [
        'recommendedBpmMin',
        'defaultRecommendedBpmMin',
      ]),
      recommendedBpmMax: _readNum(json, const [
        'recommendedBpmMax',
        'defaultRecommendedBpmMax',
      ]),
      recommendedBpmTarget: _readNum(json, const [
        'recommendedBpmTarget',
        'defaultRecommendedBpmTarget',
      ]),
      fuzzyOverrideLevel:
          _readOverrideLevel(json) ?? brandMusicProfile?.storeOverrideLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brandId': brandId,
      'sunoPromptTemplate': sunoPromptTemplate,
      'sunoDefaultPlaylistId': sunoDefaultPlaylistId,
      'aiGenerationMode': aiGenerationMode?.value,
      'fuzzyProfileTemplate': fuzzyProfileTemplate,
      'recommendedBpmMin': recommendedBpmMin,
      'recommendedBpmMax': recommendedBpmMax,
      'recommendedBpmTarget': recommendedBpmTarget,
      'fuzzyOverrideLevel': fuzzyOverrideLevel?.displayName,
    };
  }

  static AiGenerationModeEnum? _readGenerationMode(Map<String, dynamic> json) {
    for (final key in const [
      'aiGenerationMode',
      'generationMode',
      'defaultAiGenerationMode',
    ]) {
      final value = json[key];
      if (value == null) continue;
      final parsed = AiGenerationModeEnum.fromJson(value);
      if (parsed != AiGenerationModeEnum.unknown) {
        return parsed;
      }
    }
    return null;
  }

  static List<AiGenerationModeEnum> _readGenerationModes(
    Map<String, dynamic> json,
  ) {
    for (final key in const [
      'availableAiGenerationModes',
      'aiGenerationModes',
      'generationModes',
    ]) {
      final value = json[key];
      if (value is! List) continue;
      return value
          .map(AiGenerationModeEnum.fromJson)
          .where((mode) => mode != AiGenerationModeEnum.unknown)
          .toList(growable: false);
    }
    return const <AiGenerationModeEnum>[];
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

  static List<String> _readStringList(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value is List) {
        return value
            .map((entry) => entry.toString().trim())
            .where((entry) => entry.isNotEmpty)
            .toList(growable: false);
      }
    }
    return const <String>[];
  }

  static int? _readNum(Map<String, dynamic> json, List<String> keys) {
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

  static StoreFuzzyOverrideLevelEnum? _readOverrideLevel(
    Map<String, dynamic> json,
  ) {
    final parsed = StoreFuzzyOverrideLevelEnum.fromJson(
      json['storeOverrideLevel'] ?? json['fuzzyOverrideLevel'],
    );
    return parsed == StoreFuzzyOverrideLevelEnum.unknown ? null : parsed;
  }
}
