import '../../../../core/enums/ai_generation_mode_enum.dart';
import '../../../../core/enums/store_fuzzy_override_level_enum.dart';
import '../../domain/entities/fuzzy_override_summary.dart';

class FuzzyOverrideSummaryModel extends FuzzyOverrideSummary {
  const FuzzyOverrideSummaryModel({
    super.profileId,
    super.name,
    super.templateName,
    super.aiGenerationMode,
    super.overrideLevel,
    super.allowedPlaylistIds,
    super.restrictedToAllowedPlaylists,
  });

  factory FuzzyOverrideSummaryModel.fromJson(Map<String, dynamic> json) {
    return FuzzyOverrideSummaryModel(
      profileId: _readString(json, const [
        'id',
        'profileId',
        'activeFuzzyMusicProfileId',
      ]),
      name: _readString(json, const [
        'name',
        'profileName',
        'fuzzyProfileName',
        'activeFuzzyMusicProfileName',
      ]),
      templateName: _readString(json, const [
        'templateName',
        'fuzzyProfileTemplate',
        'profileTemplate',
        'fuzzyTemplate',
      ]),
      aiGenerationMode: _readAiGenerationMode(json),
      overrideLevel: _readOverrideLevel(json),
      allowedPlaylistIds: _readStringList(json, const [
        'allowedPlaylistIds',
        'playlistIds',
      ]),
      restrictedToAllowedPlaylists: _readBool(json, const [
        'restricted',
        'isRestricted',
        'restrictedToAllowedPlaylists',
      ]),
    );
  }

  static FuzzyOverrideSummary? fromRootJson(Map<String, dynamic> json) {
    for (final key in const [
      'activeFuzzyMusicProfile',
      'activeFuzzyProfile',
      'fuzzyOverrideSummary',
      'fuzzyProfile',
      'brandMusicPolicy',
      'musicPolicy',
    ]) {
      final candidate = json[key];
      if (candidate is Map<String, dynamic>) {
        final parsed = FuzzyOverrideSummaryModel.fromJson(candidate);
        if (parsed.hasAnyData) {
          return parsed;
        }
      } else if (candidate is Map) {
        final parsed = FuzzyOverrideSummaryModel.fromJson(
          Map<String, dynamic>.from(candidate),
        );
        if (parsed.hasAnyData) {
          return parsed;
        }
      }
    }

    final flattened = FuzzyOverrideSummaryModel.fromJson(json);
    return flattened.hasAnyData ? flattened : null;
  }

  static AiGenerationModeEnum? _readAiGenerationMode(
      Map<String, dynamic> json) {
    for (final key in const [
      'aiGenerationMode',
      'generationMode',
      'defaultAiGenerationMode',
    ]) {
      final value = json[key];
      final parsed = AiGenerationModeEnum.fromJson(value);
      if (value != null && parsed != AiGenerationModeEnum.unknown) {
        return parsed;
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

  static bool? _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value is String) {
        if (value.toLowerCase() == 'true') return true;
        if (value.toLowerCase() == 'false') return false;
      }
    }
    return null;
  }
}
