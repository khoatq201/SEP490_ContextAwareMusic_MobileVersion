import 'package:equatable/equatable.dart';

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
        completedAtUtc,
        lastPolledAtUtc,
      ];
}
