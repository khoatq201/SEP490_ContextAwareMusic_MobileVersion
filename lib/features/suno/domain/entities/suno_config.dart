import 'package:equatable/equatable.dart';

import '../../../../core/enums/ai_generation_mode_enum.dart';
import '../../../../core/enums/store_fuzzy_override_level_enum.dart';

class SunoConfig extends Equatable {
  final String? brandId;
  final String? sunoPromptTemplate;
  final String? sunoDefaultPlaylistId;
  final AiGenerationModeEnum? aiGenerationMode;
  final List<AiGenerationModeEnum> availableGenerationModes;
  final String? fuzzyProfileTemplate;
  final List<String> availableFuzzyProfileTemplates;
  final int? recommendedBpmMin;
  final int? recommendedBpmMax;
  final int? recommendedBpmTarget;
  final StoreFuzzyOverrideLevelEnum? fuzzyOverrideLevel;

  const SunoConfig({
    this.brandId,
    this.sunoPromptTemplate,
    this.sunoDefaultPlaylistId,
    this.aiGenerationMode,
    this.availableGenerationModes = const [],
    this.fuzzyProfileTemplate,
    this.availableFuzzyProfileTemplates = const [],
    this.recommendedBpmMin,
    this.recommendedBpmMax,
    this.recommendedBpmTarget,
    this.fuzzyOverrideLevel,
  });

  bool get supportsAdvancedGeneration =>
      aiGenerationMode != null ||
      availableGenerationModes.isNotEmpty ||
      (fuzzyProfileTemplate?.trim().isNotEmpty ?? false) ||
      availableFuzzyProfileTemplates.isNotEmpty ||
      recommendedBpmMin != null ||
      recommendedBpmMax != null ||
      recommendedBpmTarget != null;

  SunoConfig copyWith({
    String? brandId,
    String? sunoPromptTemplate,
    String? sunoDefaultPlaylistId,
    AiGenerationModeEnum? aiGenerationMode,
    List<AiGenerationModeEnum>? availableGenerationModes,
    String? fuzzyProfileTemplate,
    List<String>? availableFuzzyProfileTemplates,
    int? recommendedBpmMin,
    int? recommendedBpmMax,
    int? recommendedBpmTarget,
    StoreFuzzyOverrideLevelEnum? fuzzyOverrideLevel,
  }) {
    return SunoConfig(
      brandId: brandId ?? this.brandId,
      sunoPromptTemplate: sunoPromptTemplate ?? this.sunoPromptTemplate,
      sunoDefaultPlaylistId:
          sunoDefaultPlaylistId ?? this.sunoDefaultPlaylistId,
      aiGenerationMode: aiGenerationMode ?? this.aiGenerationMode,
      availableGenerationModes:
          availableGenerationModes ?? this.availableGenerationModes,
      fuzzyProfileTemplate: fuzzyProfileTemplate ?? this.fuzzyProfileTemplate,
      availableFuzzyProfileTemplates:
          availableFuzzyProfileTemplates ?? this.availableFuzzyProfileTemplates,
      recommendedBpmMin: recommendedBpmMin ?? this.recommendedBpmMin,
      recommendedBpmMax: recommendedBpmMax ?? this.recommendedBpmMax,
      recommendedBpmTarget: recommendedBpmTarget ?? this.recommendedBpmTarget,
      fuzzyOverrideLevel: fuzzyOverrideLevel ?? this.fuzzyOverrideLevel,
    );
  }

  @override
  List<Object?> get props => [
        brandId,
        sunoPromptTemplate,
        sunoDefaultPlaylistId,
        aiGenerationMode,
        availableGenerationModes,
        fuzzyProfileTemplate,
        availableFuzzyProfileTemplates,
        recommendedBpmMin,
        recommendedBpmMax,
        recommendedBpmTarget,
        fuzzyOverrideLevel,
      ];
}
