import '../../domain/entities/suno_generation.dart';
import '../../domain/entities/suno_generation_status.dart';
import '../../../../core/enums/ai_generation_mode_enum.dart';
import '../../../../core/enums/music_provider_enum.dart';

class SunoGenerationModel extends SunoGeneration {
  const SunoGenerationModel({
    required super.id,
    super.brandId,
    super.generationStatus,
    super.progressPercent,
    super.errorMessage,
    super.generatedTrackId,
    super.externalTaskId,
    super.outputAudioUrl,
    super.prompt,
    super.title,
    super.artist,
    super.moodId,
    super.targetPlaylistId,
    super.autoAddToTargetPlaylist,
    super.aiGenerationMode,
    super.provider,
    super.fuzzyProfileTemplate,
    super.fuzzyProfileName,
    super.recommendedBpmMin,
    super.recommendedBpmMax,
    super.recommendedBpmTarget,
    super.completedAtUtc,
    super.lastPolledAtUtc,
  });

  factory SunoGenerationModel.fromJson(Map<String, dynamic> json) {
    return SunoGenerationModel(
      id: json['id']?.toString() ?? '',
      brandId: json['brandId']?.toString(),
      generationStatus: SunoGenerationStatus.fromJson(json['generationStatus']),
      progressPercent: (json['progressPercent'] as num?)?.toInt(),
      errorMessage: json['errorMessage']?.toString(),
      generatedTrackId: json['generatedTrackId']?.toString(),
      externalTaskId: json['externalTaskId']?.toString(),
      outputAudioUrl: json['outputAudioUrl']?.toString(),
      prompt: json['prompt']?.toString(),
      title: json['title']?.toString(),
      artist: json['artist']?.toString(),
      moodId: json['moodId']?.toString(),
      targetPlaylistId: json['targetPlaylistId']?.toString(),
      autoAddToTargetPlaylist:
          json['autoAddToTargetPlaylist'] as bool? ?? false,
      aiGenerationMode: _readGenerationMode(json),
      provider: MusicProviderEnum.fromJson(
        json['provider'] ?? json['generatedTrackProvider'],
      ),
      fuzzyProfileTemplate: _readString(json, const [
        'fuzzyProfileTemplate',
        'profileTemplate',
      ]),
      fuzzyProfileName: _readString(json, const [
        'fuzzyProfileName',
        'profileName',
      ]),
      recommendedBpmMin: _readNum(json, const [
        'recommendedBpmMin',
        'bpmMin',
      ]),
      recommendedBpmMax: _readNum(json, const [
        'recommendedBpmMax',
        'bpmMax',
      ]),
      recommendedBpmTarget: _readNum(json, const [
        'recommendedBpmTarget',
        'bpmTarget',
      ]),
      completedAtUtc: _parseDateTime(json['completedAtUtc']),
      lastPolledAtUtc: _parseDateTime(json['lastPolledAtUtc']),
    );
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toUtc();
    return DateTime.tryParse(raw.toString())?.toUtc();
  }

  static AiGenerationModeEnum? _readGenerationMode(Map<String, dynamic> json) {
    for (final key in const ['aiGenerationMode', 'generationMode']) {
      final value = json[key];
      if (value == null) continue;
      final parsed = AiGenerationModeEnum.fromJson(value);
      if (parsed != AiGenerationModeEnum.unknown) {
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
}
