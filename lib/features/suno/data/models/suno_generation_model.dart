import '../../domain/entities/suno_generation.dart';
import '../../domain/entities/suno_generation_status.dart';

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
      completedAtUtc: _parseDateTime(json['completedAtUtc']),
      lastPolledAtUtc: _parseDateTime(json['lastPolledAtUtc']),
    );
  }

  static DateTime? _parseDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toUtc();
    return DateTime.tryParse(raw.toString())?.toUtc();
  }
}
