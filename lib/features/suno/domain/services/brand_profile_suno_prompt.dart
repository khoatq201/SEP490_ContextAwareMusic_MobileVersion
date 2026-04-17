import '../entities/suno_brand_music_profile.dart';

enum BrandProfileSunoMood { chill, focus, energetic }

extension BrandProfileSunoMoodPresentation on BrandProfileSunoMood {
  String get label {
    switch (this) {
      case BrandProfileSunoMood.chill:
        return 'Chill / calm zone';
      case BrandProfileSunoMood.focus:
        return 'Focus / steady zone';
      case BrandProfileSunoMood.energetic:
        return 'Energetic / peak zone';
    }
  }

  String get description {
    switch (this) {
      case BrandProfileSunoMood.chill:
        return 'relaxed, low-intensity background music';
      case BrandProfileSunoMood.focus:
        return 'neutral, concentration-friendly instrumental music';
      case BrandProfileSunoMood.energetic:
        return 'more driving, upbeat instrumental music';
    }
  }

  String get shortLabel {
    switch (this) {
      case BrandProfileSunoMood.chill:
        return 'Chill';
      case BrandProfileSunoMood.focus:
        return 'Focus';
      case BrandProfileSunoMood.energetic:
        return 'Energetic';
    }
  }
}

bool hasBrandMusicProfileData(SunoBrandMusicProfile? profile) {
  if (profile == null) return false;
  if (profile.fuzzyProfileTemplate?.trim().isNotEmpty ?? false) return true;
  return profile.hasCompleteBpmBands;
}

String buildPromptFromTemplate(
  String template,
  Map<String, String> variables,
) {
  var result = template;
  for (final entry in variables.entries) {
    result = result.replaceAll('{${entry.key}}', entry.value);
  }
  return result;
}

String buildBrandProfileSunoPrompt({
  required SunoBrandMusicProfile profile,
  required BrandProfileSunoMood mood,
  String? title,
  String? genre,
  String? artist,
  String? sunoPromptTemplate,
}) {
  final templateKey = profile.fuzzyProfileTemplate?.trim().isNotEmpty ?? false
      ? profile.fuzzyProfileTemplate!.trim()
      : 'brand profile';

  final chillMin = profile.chillBpmMin ?? 60;
  final chillMax = profile.chillBpmMax ?? 80;
  final focusMin = profile.focusBpmMin ?? 85;
  final focusMax = profile.focusBpmMax ?? 105;
  final energeticMin = profile.energeticBpmMin ?? 120;
  final energeticMax = profile.energeticBpmMax ?? 140;

  final chillBand = '$chillMin-$chillMax';
  final focusBand = '$focusMin-$focusMax';
  final energeticBand = '$energeticMin-$energeticMax';
  final bpmBand = switch (mood) {
    BrandProfileSunoMood.chill => chillBand,
    BrandProfileSunoMood.focus => focusBand,
    BrandProfileSunoMood.energetic => energeticBand,
  };

  final pressureLine =
      profile.pressureLowMax != null && profile.pressureCriticalMin != null
          ? 'Venue traffic context from brand profile: light load up to '
              '${_formatNumber(profile.pressureLowMax!)} concurrent guests, '
              'busy peak from ${_formatNumber(profile.pressureCriticalMin!)} '
              'upward (inform the energy curve only; do not mention numbers '
              'in lyrics).'
          : '';

  final defaultNarrative = [
    'Create royalty-free instrumental background music for a commercial '
        'space using the brand CAMS music profile (template: $templateKey).',
    'Primary direction: ${mood.label} - ${mood.description}. Use roughly the '
        '$bpmBand BPM range as a tempo guide (do not speak BPM numbers to the listener).',
    'Palette: also allow calm ($chillBand BPM feel) and high-energy '
        '($energeticBand BPM feel) for consistency with the same brand - '
        'this track should emphasize the ${mood.name} zone.',
    pressureLine,
    if (title?.trim().isNotEmpty ?? false) 'Working title: ${title!.trim()}.',
    if (genre?.trim().isNotEmpty ?? false) 'Genre hint: ${genre!.trim()}.',
    if (artist?.trim().isNotEmpty ?? false)
      'Style or artist inspiration: ${artist!.trim()}.',
    'Keep dynamics smooth for in-store playback; loop-friendly; no vocals '
        'unless the genre hint clearly requires subtle vocal texture.',
  ].join('\n\n');

  final template = sunoPromptTemplate?.trim();
  if (template != null && template.isNotEmpty) {
    final resolvedGenre = genre?.trim().isNotEmpty == true
        ? genre!.trim()
        : artist?.trim().isNotEmpty == true
            ? artist!.trim()
            : 'instrumental ambient suitable for retail';

    final fromTemplate = buildPromptFromTemplate(
      template,
      {
        'mood': mood.label,
        'genre': resolvedGenre,
        'title': title?.trim() ?? '',
        'artist': artist?.trim() ?? '',
        'fuzzyTemplate': templateKey,
        'bpmBand': bpmBand,
        'chillBpm': chillBand,
        'focusBpm': focusBand,
        'energeticBpm': energeticBand,
        'pressureLowMax': _formatNullable(profile.pressureLowMax),
        'pressureCriticalMin': _formatNullable(profile.pressureCriticalMin),
        'stressComfortableMax':
            _formatNullable(profile.stressComfortableMax),
        'stressHighMin': _formatNullable(profile.stressHighMin),
        'densitySparseMax': _formatNullable(profile.densitySparseMax),
        'densityCrowdedMin': _formatNullable(profile.densityCrowdedMin),
        'spaceCapacity': _formatNullable(profile.spaceCapacity),
      },
    );

    final camsSummary = _buildCamsProfileSummaryBlock(
      profile: profile,
      mood: mood,
      templateKey: templateKey,
      chillBand: chillBand,
      focusBand: focusBand,
      energeticBand: energeticBand,
      bpmBand: bpmBand,
    );

    return _joinPromptWithinLimit(camsSummary, fromTemplate, 4000);
  }

  return defaultNarrative.substring(
    0,
    defaultNarrative.length > 4000 ? 4000 : defaultNarrative.length,
  );
}

String _buildCamsProfileSummaryBlock({
  required SunoBrandMusicProfile profile,
  required BrandProfileSunoMood mood,
  required String templateKey,
  required String chillBand,
  required String focusBand,
  required String energeticBand,
  required String bpmBand,
}) {
  final parts = [
    '[CAMS brand music profile] Template: $templateKey.',
    if (profile.storeOverrideLevel != null)
      'Store override policy: ${profile.storeOverrideLevel!.displayName}.',
    'BPM guide (tempo hints for production, not for spoken lyrics): '
        'Chill $chillBand, Focus $focusBand, Energetic $energeticBand.',
    'Primary zone for this request: ${mood.label} '
        '(emphasize about $bpmBand BPM feel).',
  ];

  if (profile.pressureLowMax != null && profile.pressureCriticalMin != null) {
    parts.add(
      'Crowding / pressure hints from profile: treat light load up to '
      '${_formatNumber(profile.pressureLowMax!)} guests, busy peak from '
      '${_formatNumber(profile.pressureCriticalMin!)} upward when shaping energy.',
    );
  }

  return parts.join(' ');
}

String _joinPromptWithinLimit(String prefix, String body, int maxLength) {
  const separator = '\n\n';
  final combined = '$prefix$separator$body';
  if (combined.length <= maxLength) {
    return combined;
  }

  final remainingBudget = maxLength - prefix.length - separator.length;
  if (remainingBudget < 80) {
    return prefix.substring(0, maxLength.clamp(0, prefix.length));
  }

  final truncatedBody = body.substring(
    0,
    remainingBudget.clamp(0, body.length),
  );
  final joined = '$prefix$separator$truncatedBody';
  return joined.substring(0, joined.length.clamp(0, maxLength));
}

String _formatNullable(num? value) {
  if (value == null) return '';
  return _formatNumber(value);
}

String _formatNumber(num value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }
  return value.toString();
}
