import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // ==========================================
  // Configuration
  // ==========================================

  static const String _defaultBaseUrl = 'https://logcams.cloud';
  static const String _dartDefinedApiBaseUrl =
      String.fromEnvironment('API_BASE_URL');
  static const String _dartDefinedBaseUrl = String.fromEnvironment('BASE_URL');
  static const String _dartDefinedUseMockData =
      String.fromEnvironment('USE_MOCK_DATA');
  static const String _dartDefinedEnvName = String.fromEnvironment('ENV_NAME');

  /// Toggle between mock and real API datasources.
  ///
  /// Priority: --dart-define USE_MOCK_DATA > dotenv USE_MOCK_DATA > false.
  static bool get useMockData {
    final value = _firstNonEmpty([
      _dartDefinedUseMockData,
      _dotenvValue(['USE_MOCK_DATA']),
    ]);
    return value?.toLowerCase() == 'true';
  }

  /// Base URL for all API and SignalR requests.
  ///
  /// Priority:
  /// 1. --dart-define API_BASE_URL or BASE_URL
  /// 2. dotenv API_BASE_URL or BASE_URL
  /// 3. production fallback
  static String get baseUrl {
    final value = _firstNonEmpty([
      _dartDefinedApiBaseUrl,
      _dartDefinedBaseUrl,
      _dotenvValue(['API_BASE_URL', 'BASE_URL', 'api_base_url']),
      _defaultBaseUrl,
    ]);
    return _withoutTrailingSlash(value!);
  }

  static String get envName =>
      _firstNonEmpty([
        _dartDefinedEnvName,
        _dotenvValue(['ENV_NAME']),
      ]) ??
      'release';

  static String? _dotenvValue(List<String> keys) {
    final env = _safeDotenvEnv();
    if (env == null) return null;

    for (final key in keys) {
      final value = env[key]?.trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static Map<String, String>? _safeDotenvEnv() {
    try {
      return dotenv.env;
    } catch (_) {
      return null;
    }
  }

  static String? _firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return null;
  }

  static String _withoutTrailingSlash(String value) =>
      value.replaceFirst(RegExp(r'/+$'), '');

  // Default request headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  static const String mqttBrokerUrl = 'mqtt.cams.example.com';
  static const int mqttPort = 1883;

  // API Endpoints - Auth
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String refreshToken = '/api/auth/refresh-token';
  static const String authPair = '/api/auth/pair';
  static const String authDeviceRefreshToken = '/api/auth/device/refresh-token';
  static const String profile = '/api/auth/profile';
  static const String changePassword = '/api/auth/change-password';

  // Stores & Spaces
  static const String getStoresEndpoint = '/api/stores';
  static String getStoreDetail(String storeId) => '/api/stores/$storeId';
  static String updateStore(String storeId) => '/api/stores/$storeId';
  static String deleteStore(String storeId) => '/api/stores/$storeId';
  static String toggleStoreStatus(String storeId) =>
      '/api/stores/$storeId/toggle-status';
  static String storeFuzzyProfiles(String storeId) =>
      '/api/stores/$storeId/fuzzy-profiles';
  static String storeContextLogs(String storeId) =>
      '/api/stores/$storeId/context-logs';
  static const String getSpacesEndpoint = '/api/spaces';
  static const String getSpaceDetailEndpoint = '/api/spaces/{spaceId}';
  static String getSpaceDetail(String spaceId) => '/api/spaces/$spaceId';
  static String updateSpace(String spaceId) => '/api/spaces/$spaceId';
  static String deleteSpace(String spaceId) => '/api/spaces/$spaceId';
  static const String toggleSpaceStatusEndpoint =
      '/api/spaces/{spaceId}/toggle-status';
  static String toggleSpaceStatus(String spaceId) =>
      '/api/spaces/$spaceId/toggle-status';
  static String spaceFuzzyProfiles(String spaceId) =>
      '/api/spaces/$spaceId/fuzzy-profiles';
  static String spaceHubBinding(String spaceId) =>
      '/api/spaces/$spaceId/hub-binding';
  static String restartSpaceHub(String spaceId) =>
      '/api/spaces/$spaceId/hub-binding/restart';

  // Moods
  static const String getMoods = '/api/moods';

  // Tracks
  static const String getTracks = '/api/tracks';
  static String getTrackDetail(String id) => '/api/tracks/$id';
  static String updateTrack(String id) => '/api/tracks/$id';
  static String deleteTrack(String id) => '/api/tracks/$id';
  static String toggleTrackStatus(String id) => '/api/tracks/$id/toggle-status';
  static String retranscodeTrack(String id) => '/api/tracks/$id/retranscode';
  static String trackCopyrightClearance(String id) =>
      '/api/tracks/$id/copyright-clearance';

  // Suno
  static const String sunoBase = '/api/cms/suno';
  static const String sunoGenerations = '$sunoBase/generations';
  static String sunoGenerationDetail(String id) => '$sunoGenerations/$id';
  static String sunoGenerationCancel(String id) =>
      '$sunoGenerations/$id/cancel';
  static const String sunoConfig = '$sunoBase/config';

  // Playlists
  static const String getPlaylists = '/api/playlists';
  static const String createPlaylist = getPlaylists;
  static String getPlaylistDetail(String id) => '/api/playlists/$id';
  static String updatePlaylist(String id) => '/api/playlists/$id';
  static String deletePlaylist(String id) => '/api/playlists/$id';
  static String togglePlaylistStatus(String id) =>
      '/api/playlists/$id/toggle-status';
  static String addTracksToPlaylist(String id) => '/api/playlists/$id/tracks';
  static String removeTrackFromPlaylist(String playlistId, String trackId) =>
      '/api/playlists/$playlistId/tracks/$trackId';
  // CAMS — Context-Aware Music System
  static String camsOverride(String spaceId) =>
      '/api/cams/spaces/$spaceId/override';
  static String camsCancelOverride(String spaceId) =>
      '/api/cams/spaces/$spaceId/override';
  static String camsPlayback(String spaceId) =>
      '/api/cams/spaces/$spaceId/playback';
  static String camsState(String spaceId) => '/api/cams/spaces/$spaceId/state';
  static const String camsCurrentDeviceState = '/api/cams/spaces/state';
  static String camsAudioState(String spaceId) =>
      '/api/cams/spaces/$spaceId/state/audio';
  static const String camsCurrentDeviceAudioState =
      '/api/cams/spaces/state/audio';
  static String camsSchedulingState(String spaceId) =>
      '/api/cams/spaces/$spaceId/state/scheduling';
  static const String camsCurrentDeviceSchedulingState =
      '/api/cams/spaces/state/scheduling';
  static String camsQueueTracks(String spaceId) =>
      '/api/cams/spaces/$spaceId/queue/tracks';
  static const String camsCurrentDeviceQueueTracks =
      '/api/cams/spaces/queue/tracks';
  static String camsQueuePlaylist(String spaceId) =>
      '/api/cams/spaces/$spaceId/queue/playlist';
  static const String camsCurrentDeviceQueuePlaylist =
      '/api/cams/spaces/queue/playlist';
  static String camsQueueReorder(String spaceId) =>
      '/api/cams/spaces/$spaceId/queue/reorder';
  static const String camsCurrentDeviceQueueReorder =
      '/api/cams/spaces/queue/reorder';
  static String camsQueue(String spaceId) => '/api/cams/spaces/$spaceId/queue';
  static const String camsCurrentDeviceQueue = '/api/cams/spaces/queue';
  static String camsQueueAll(String spaceId) =>
      '/api/cams/spaces/$spaceId/queue/all';
  static const String camsCurrentDeviceQueueAll = '/api/cams/spaces/queue/all';
  static String camsPairDevice(String spaceId) =>
      '/api/cams/spaces/$spaceId/pair-device';
  static const String camsCurrentPairDevice = '/api/cams/spaces/pair-device';
  static String camsPairCode(String spaceId) =>
      '/api/cams/spaces/$spaceId/pair-code';
  static String camsUnpair(String spaceId) =>
      '/api/cams/spaces/$spaceId/unpair';

  // Config Governance
  static const String cmsConfigBase = '/api/cms/config';
  static const String cmsConfigBrand = '$cmsConfigBase/brand';
  static const String cmsConfigBrandValue = '$cmsConfigBase/brand-value';
  static const String cmsConfigStore = '$cmsConfigBase/store';
  static const String cmsConfigStoreValue = '$cmsConfigBase/store-value';
  static const String cmsConfigStoresGovernanceMode =
      '$cmsConfigBase/stores/governance-mode';
  static const String cmsConfigVersionPublish =
      '$cmsConfigBase/version/publish';
  static const String cmsConfigVersionRollback =
      '$cmsConfigBase/version/rollback';
  static String cmsConfigStoreById(String storeId) =>
      '$cmsConfigBase/store/$storeId';
  static String cmsConfigStoreValueById(String storeId) =>
      '$cmsConfigBase/store/$storeId/value';
  static String cmsConfigSpace(String spaceId) =>
      '$cmsConfigBase/space/$spaceId';
  static String cmsConfigSpaceValue(String spaceId) =>
      '$cmsConfigBase/space/$spaceId/value';

  // CMS Schedule
  static const String cmsScheduleBase = '/api/cms/schedule';
  static String cmsScheduleSpaceBootstrap(String spaceId) =>
      '$cmsScheduleBase/spaces/$spaceId/bootstrap';
  static String cmsScheduleSpaceSlot(String spaceId, String slotId) =>
      '$cmsScheduleBase/spaces/$spaceId/slots/$slotId';
  static String cmsScheduleSpaceApplySource(String spaceId) =>
      '$cmsScheduleBase/spaces/$spaceId/apply-source';
  static String cmsScheduleSpaceSaveToLibrary(String spaceId) =>
      '$cmsScheduleBase/spaces/$spaceId/save-to-library';
  static String cmsScheduleSpaceToggle(String spaceId) =>
      '$cmsScheduleBase/spaces/$spaceId/toggle';
  static String cmsScheduleBrandLibrary(String brandId) =>
      '$cmsScheduleBase/brands/$brandId/library';
  static String cmsScheduleBrandTemplates(String brandId) =>
      '$cmsScheduleBase/brands/$brandId/templates';
  static const String cmsScheduleBrandSources =
      '$cmsScheduleBase/brands/sources';
  static String cmsScheduleBrandSource(String sourceId) =>
      '$cmsScheduleBrandSources/$sourceId';
  static String cmsScheduleBrandSourceSlot(String sourceId, String slotId) =>
      '$cmsScheduleBrandSources/$sourceId/slots/$slotId';

  // SignalR
  static String get storeHubUrl => '$baseUrl/hubs/store';

  // MQTT Topics - Space Level
  static String spaceStatusTopic(String storeId, String spaceId) =>
      'cams/store/$storeId/space/$spaceId/status';

  static String spaceSensorTopic(String storeId, String spaceId) =>
      'cams/store/$storeId/space/$spaceId/sensor';

  static String spaceMusicTopic(String storeId, String spaceId) =>
      'cams/store/$storeId/space/$spaceId/music';

  // MQTT Topics - Zone Level (for multi-zone spaces)
  static String zoneStatusTopic(
          String storeId, String spaceId, String zoneId) =>
      'cams/store/$storeId/space/$spaceId/zone/$zoneId/status';

  static String zoneSensorTopic(
          String storeId, String spaceId, String zoneId) =>
      'cams/store/$storeId/space/$spaceId/zone/$zoneId/sensor';

  static String zoneMusicTopic(String storeId, String spaceId, String zoneId) =>
      'cams/store/$storeId/space/$spaceId/zone/$zoneId/music';

  static String zoneSpeakerTopic(
          String storeId, String spaceId, String zoneId, String speakerId) =>
      'cams/store/$storeId/space/$spaceId/zone/$zoneId/speaker/$speakerId';

  // Zone sync topic - for coordinating multi-zone playback
  static String zoneSyncTopic(String storeId, String spaceId) =>
      'cams/store/$storeId/space/$spaceId/zone/sync';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  // Cache Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String cachedPlaylistsKey = 'cached_playlists';
  static const String lastApiBaseUrlKey = 'last_api_base_url';
}
