import 'package:equatable/equatable.dart';

import '../../../../core/enums/ai_generation_mode_enum.dart';
import '../../../../core/enums/music_provider_enum.dart';
import 'suno_generation_status.dart';

class SunoGeneration extends Equatable {
  final String id;
  final String? brandId;
  final SunoGenerationStatus generationStatus;
  final int? progressPercent;
  final String? errorMessage;
  final String? generatedTrackId;
  final String? externalTaskId;
  final String? outputAudioUrl;
  final String? prompt;
  final String? title;
  final String? artist;
  final String? moodId;
  final String? targetPlaylistId;
  final bool autoAddToTargetPlaylist;
  final AiGenerationModeEnum? aiGenerationMode;
  final MusicProviderEnum? provider;
  final String? fuzzyProfileTemplate;
  final String? fuzzyProfileName;
  final int? recommendedBpmMin;
  final int? recommendedBpmMax;
  final int? recommendedBpmTarget;
  final DateTime? completedAtUtc;
  final DateTime? lastPolledAtUtc;

  const SunoGeneration({
    required this.id,
    this.brandId,
    this.generationStatus = SunoGenerationStatus.queued,
    this.progressPercent,
    this.errorMessage,
    this.generatedTrackId,
    this.externalTaskId,
    this.outputAudioUrl,
    this.prompt,
    this.title,
    this.artist,
    this.moodId,
    this.targetPlaylistId,
    this.autoAddToTargetPlaylist = false,
    this.aiGenerationMode,
    this.provider,
    this.fuzzyProfileTemplate,
    this.fuzzyProfileName,
    this.recommendedBpmMin,
    this.recommendedBpmMax,
    this.recommendedBpmTarget,
    this.completedAtUtc,
    this.lastPolledAtUtc,
  });

  SunoGeneration copyWith({
    String? id,
    String? brandId,
    SunoGenerationStatus? generationStatus,
    int? progressPercent,
    String? errorMessage,
    String? generatedTrackId,
    String? externalTaskId,
    String? outputAudioUrl,
    String? prompt,
    String? title,
    String? artist,
    String? moodId,
    String? targetPlaylistId,
    bool? autoAddToTargetPlaylist,
    AiGenerationModeEnum? aiGenerationMode,
    MusicProviderEnum? provider,
    String? fuzzyProfileTemplate,
    String? fuzzyProfileName,
    int? recommendedBpmMin,
    int? recommendedBpmMax,
    int? recommendedBpmTarget,
    DateTime? completedAtUtc,
    DateTime? lastPolledAtUtc,
  }) {
    return SunoGeneration(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      generationStatus: generationStatus ?? this.generationStatus,
      progressPercent: progressPercent ?? this.progressPercent,
      errorMessage: errorMessage ?? this.errorMessage,
      generatedTrackId: generatedTrackId ?? this.generatedTrackId,
      externalTaskId: externalTaskId ?? this.externalTaskId,
      outputAudioUrl: outputAudioUrl ?? this.outputAudioUrl,
      prompt: prompt ?? this.prompt,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      moodId: moodId ?? this.moodId,
      targetPlaylistId: targetPlaylistId ?? this.targetPlaylistId,
      autoAddToTargetPlaylist:
          autoAddToTargetPlaylist ?? this.autoAddToTargetPlaylist,
      aiGenerationMode: aiGenerationMode ?? this.aiGenerationMode,
      provider: provider ?? this.provider,
      fuzzyProfileTemplate: fuzzyProfileTemplate ?? this.fuzzyProfileTemplate,
      fuzzyProfileName: fuzzyProfileName ?? this.fuzzyProfileName,
      recommendedBpmMin: recommendedBpmMin ?? this.recommendedBpmMin,
      recommendedBpmMax: recommendedBpmMax ?? this.recommendedBpmMax,
      recommendedBpmTarget: recommendedBpmTarget ?? this.recommendedBpmTarget,
      completedAtUtc: completedAtUtc ?? this.completedAtUtc,
      lastPolledAtUtc: lastPolledAtUtc ?? this.lastPolledAtUtc,
    );
  }

  @override
  List<Object?> get props => [
        id,
        brandId,
        generationStatus,
        progressPercent,
        errorMessage,
        generatedTrackId,
        externalTaskId,
        outputAudioUrl,
        prompt,
        title,
        artist,
        moodId,
        targetPlaylistId,
        autoAddToTargetPlaylist,
        aiGenerationMode,
        provider,
        fuzzyProfileTemplate,
        fuzzyProfileName,
        recommendedBpmMin,
        recommendedBpmMax,
        recommendedBpmTarget,
        completedAtUtc,
        lastPolledAtUtc,
      ];
}
