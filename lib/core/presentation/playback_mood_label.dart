String? buildPlaybackMoodLabel({
  required bool isManualOverride,
  String? primaryMoodName,
  List<String?> fallbackMoodNames = const [],
}) {
  final primaryMood = _trimOrNull(primaryMoodName);

  if (isManualOverride) {
    if (primaryMood != null) {
      return 'Manual: $primaryMood';
    }
    return 'Manual override';
  }

  final resolvedMood = primaryMood ?? _firstNonEmpty(fallbackMoodNames);
  if (resolvedMood == null) {
    return null;
  }
  return 'AI: $resolvedMood';
}

String? _firstNonEmpty(List<String?> candidates) {
  for (final candidate in candidates) {
    final trimmed = _trimOrNull(candidate);
    if (trimmed != null) {
      return trimmed;
    }
  }
  return null;
}

String? _trimOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
