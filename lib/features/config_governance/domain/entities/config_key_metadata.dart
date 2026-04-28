import 'config_governance_enums.dart';

class ConfigKeyMetadata {
  final String key;
  final String label;
  final String description;
  final bool hardLocked;
  final bool brandBlocked;
  final bool storeBlocked;
  final bool spaceBlocked;

  const ConfigKeyMetadata({
    required this.key,
    required this.label,
    required this.description,
    this.hardLocked = false,
    this.brandBlocked = false,
    this.storeBlocked = false,
    this.spaceBlocked = false,
  });
}

const Map<String, ConfigKeyMetadata> configKeyMetadataByKey = {
  'ops.openTime': ConfigKeyMetadata(
    key: 'ops.openTime',
    label: 'Opening Time',
    description: 'Store opening time used by operations and scheduling.',
    spaceBlocked: true,
  ),
  'ops.closeTime': ConfigKeyMetadata(
    key: 'ops.closeTime',
    label: 'Closing Time',
    description: 'Store closing time used by operations and scheduling.',
    spaceBlocked: true,
  ),
  'playback.maxVolume': ConfigKeyMetadata(
    key: 'playback.maxVolume',
    label: 'Max Volume',
    description: 'Upper playback volume limit.',
  ),
  'playback.minVolume': ConfigKeyMetadata(
    key: 'playback.minVolume',
    label: 'Min Volume',
    description: 'Lower playback volume limit.',
  ),
  'playback.baseVolume': ConfigKeyMetadata(
    key: 'playback.baseVolume',
    label: 'Base Volume',
    description: 'Default playback volume before adaptive adjustments.',
  ),
  'playback.crossfadeSec': ConfigKeyMetadata(
    key: 'playback.crossfadeSec',
    label: 'Crossfade Duration',
    description: 'Crossfade duration between tracks, in seconds.',
  ),
  'fuzzy.defaultMoodId': ConfigKeyMetadata(
    key: 'fuzzy.defaultMoodId',
    label: 'Default Mood',
    description: 'Fallback mood used when context is unavailable.',
  ),
  'fuzzy.profileRef': ConfigKeyMetadata(
    key: 'fuzzy.profileRef',
    label: 'Fuzzy Profile Reference',
    description: 'Reference to the active fuzzy profile.',
  ),
  'fuzzy.allowedPlaylists': ConfigKeyMetadata(
    key: 'fuzzy.allowedPlaylists',
    label: 'Allowed Playlists',
    description: 'Playlist set allowed for fuzzy music selection.',
  ),
  'content.defaultPlaylistId': ConfigKeyMetadata(
    key: 'content.defaultPlaylistId',
    label: 'Default Playlist',
    description: 'Fallback playlist for normal content playback.',
  ),
  'content.copyrightFallbackPlaylistId': ConfigKeyMetadata(
    key: 'content.copyrightFallbackPlaylistId',
    label: 'Copyright Fallback Playlist',
    description: 'System-owned fallback playlist for copyright-safe playback.',
    hardLocked: true,
    spaceBlocked: true,
  ),
  'content.enableAudioAds': ConfigKeyMetadata(
    key: 'content.enableAudioAds',
    label: 'Enable Audio Ads',
    description: 'Controls audio ad insertion for playback.',
  ),
  'content.allowlist.playlists': ConfigKeyMetadata(
    key: 'content.allowlist.playlists',
    label: 'Playlist Allowlist',
    description: 'Explicit playlist allowlist for this scope.',
  ),
  'governance.mode': ConfigKeyMetadata(
    key: 'governance.mode',
    label: 'Governance Mode',
    description: 'Governance behavior for child config inheritance.',
    brandBlocked: true,
    storeBlocked: true,
    spaceBlocked: true,
  ),
  'governance.brandProfileRef': ConfigKeyMetadata(
    key: 'governance.brandProfileRef',
    label: 'Brand Profile Reference',
    description: 'Reference to the brand governance profile.',
    spaceBlocked: true,
  ),
  'scheduling.slots': ConfigKeyMetadata(
    key: 'scheduling.slots',
    label: 'Schedule Slots',
    description: 'Serialized schedule slots for automatic playback windows.',
    spaceBlocked: true,
  ),
  'cams.slidingWindowMinutes': ConfigKeyMetadata(
    key: 'cams.slidingWindowMinutes',
    label: 'Sliding Window',
    description: 'CAMS context aggregation window in minutes.',
  ),
  'cams.aiQueueTrackLimit': ConfigKeyMetadata(
    key: 'cams.aiQueueTrackLimit',
    label: 'AI Queue Track Limit',
    description: 'Maximum AI-selected tracks queued at once.',
  ),
  'cams.recentPlaybackCooldown': ConfigKeyMetadata(
    key: 'cams.recentPlaybackCooldown',
    label: 'Recent Playback Cooldown',
    description: 'Cooldown before recently played tracks can return.',
  ),
  'cams.moodTrackLimit': ConfigKeyMetadata(
    key: 'cams.moodTrackLimit',
    label: 'Mood Track Limit',
    description: 'Maximum tracks considered for each mood.',
  ),
  'cams.isAiClearManagerTracks': ConfigKeyMetadata(
    key: 'cams.isAiClearManagerTracks',
    label: 'AI Clears Manager Tracks',
    description: 'Allows AI automation to clear manager-added tracks.',
  ),
  'cams.isAiPriorityInsert': ConfigKeyMetadata(
    key: 'cams.isAiPriorityInsert',
    label: 'AI Priority Insert',
    description: 'Allows AI automation to insert priority tracks.',
  ),
  'cams.sunoPromptTemplate': ConfigKeyMetadata(
    key: 'cams.sunoPromptTemplate',
    label: 'Suno Prompt Template',
    description: 'Prompt template for AI music generation.',
  ),
  'cams.aiGenerationMode': ConfigKeyMetadata(
    key: 'cams.aiGenerationMode',
    label: 'AI Generation Mode',
    description: 'Mode used by AI generation workflows.',
  ),
  'cams.copyrightScanEnabled': ConfigKeyMetadata(
    key: 'cams.copyrightScanEnabled',
    label: 'Copyright Scan Enabled',
    description: 'Enables copyright scanning for generated or uploaded audio.',
  ),
  'cams.copyrightRiskThreshold': ConfigKeyMetadata(
    key: 'cams.copyrightRiskThreshold',
    label: 'Copyright Risk Threshold',
    description: 'Risk threshold used by copyright scanning.',
  ),
};

ConfigKeyMetadata metadataForConfigKey(String key) {
  return configKeyMetadataByKey[key] ??
      ConfigKeyMetadata(
        key: key,
        label: key,
        description: 'Custom config key.',
      );
}

bool isConfigKeySpaceBlocked(String key, ConfigDomain domain) {
  final metadata = metadataForConfigKey(key);
  if (metadata.hardLocked || metadata.spaceBlocked) return true;

  return domain == ConfigDomain.ops ||
      domain == ConfigDomain.governance ||
      domain == ConfigDomain.scheduling;
}

bool isConfigKeyBrandBlocked(String key) {
  return metadataForConfigKey(key).brandBlocked;
}

bool isConfigKeyStoreBlocked(String key) {
  return metadataForConfigKey(key).storeBlocked;
}
