import 'package:equatable/equatable.dart';

import '../../../../core/enums/ai_generation_mode_enum.dart';
import '../../../../core/enums/store_fuzzy_override_level_enum.dart';

class FuzzyOverrideSummary extends Equatable {
  final String? profileId;
  final String? name;
  final String? templateName;
  final AiGenerationModeEnum? aiGenerationMode;
  final StoreFuzzyOverrideLevelEnum? overrideLevel;
  final List<String> allowedPlaylistIds;
  final bool? restrictedToAllowedPlaylists;

  const FuzzyOverrideSummary({
    this.profileId,
    this.name,
    this.templateName,
    this.aiGenerationMode,
    this.overrideLevel,
    this.allowedPlaylistIds = const [],
    this.restrictedToAllowedPlaylists,
  });

  bool get hasAnyData =>
      (profileId?.trim().isNotEmpty ?? false) ||
      (name?.trim().isNotEmpty ?? false) ||
      (templateName?.trim().isNotEmpty ?? false) ||
      aiGenerationMode != null ||
      overrideLevel != null ||
      allowedPlaylistIds.isNotEmpty ||
      restrictedToAllowedPlaylists != null;

  String? get headline {
    final trimmedName = name?.trim();
    if (trimmedName != null && trimmedName.isNotEmpty) {
      return trimmedName;
    }
    final trimmedTemplate = templateName?.trim();
    if (trimmedTemplate != null && trimmedTemplate.isNotEmpty) {
      return trimmedTemplate;
    }
    return null;
  }

  String? get playlistSummary {
    if (restrictedToAllowedPlaylists == false && allowedPlaylistIds.isEmpty) {
      return 'No playlist restriction';
    }
    if (allowedPlaylistIds.isNotEmpty) {
      final count = allowedPlaylistIds.length;
      return '$count allowed playlist${count == 1 ? '' : 's'}';
    }
    if (restrictedToAllowedPlaylists == true) {
      return 'Playlist restriction enabled';
    }
    return null;
  }

  @override
  List<Object?> get props => [
        profileId,
        name,
        templateName,
        aiGenerationMode,
        overrideLevel,
        allowedPlaylistIds,
        restrictedToAllowedPlaylists,
      ];
}
