class ApiConstants {
  // ==========================================
  // Configuration
  // ==========================================

  /// Toggle between mock and real API datasources.
  /// Set to `true` for demo mode (mock data, no backend required).
  /// Set to `false` to use real backend API.
  static const bool useMockData = false;

  // Base URLs
  // Android emulator can use 10.0.2.2 (host localhost); real devices should use LAN IP.
  static const String baseUrl = 'http://192.168.1.4:7001';

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
  static const String getSpacesEndpoint = '/api/spaces';
  static const String getSpaceDetailEndpoint = '/api/spaces/{spaceId}';
  static String getSpaceDetail(String spaceId) => '/api/spaces/$spaceId';
  static String updateSpace(String spaceId) => '/api/spaces/$spaceId';
  static String deleteSpace(String spaceId) => '/api/spaces/$spaceId';
  static const String toggleSpaceStatusEndpoint =
      '/api/spaces/{spaceId}/toggle-status';
  static String toggleSpaceStatus(String spaceId) =>
      '/api/spaces/$spaceId/toggle-status';

  // Moods
  static const String getMoods = '/api/moods';

  // Tracks
  static const String getTracks = '/api/tracks';
  static String getTrackDetail(String id) => '/api/tracks/$id';
  static String updateTrack(String id) => '/api/tracks/$id';
  static String deleteTrack(String id) => '/api/tracks/$id';
  static String toggleTrackStatus(String id) => '/api/tracks/$id/toggle-status';
  static String retranscodeTrack(String id) => '/api/tracks/$id/retranscode';

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
  static String retranscodePlaylist(String id) =>
      '/api/playlists/$id/retranscode';

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
