class ApiConstants {
  // ==========================================
  // Configuration
  // ==========================================

  /// Toggle between mock and real API datasources.
  /// Set to `false` to use real backend API.
  static const bool useMockData = false;

  // Base URLs
  // Use 10.0.2.2 for Android emulator (maps to host machine's localhost)
  static const String baseUrl = 'http://10.0.2.2:7001';
  static const String mqttBrokerUrl = 'mqtt.cams.example.com';
  static const int mqttPort = 1883;

  // API Endpoints - Auth
  static const String login = '/api/auth/login';
  static const String logout = '/api/auth/logout';
  static const String refreshToken = '/api/auth/refresh-token';
  static const String profile = '/api/auth/profile';
  static const String changePassword = '/api/auth/change-password';

  // Stores & Spaces
  static const String getStoresEndpoint = '/api/stores';
  static const String getSpacesEndpoint = '/api/stores/{storeId}/spaces';
  static const String getSpaceDetailEndpoint = '/api/spaces/{spaceId}';
  static const String overrideMoodEndpoint =
      '/api/spaces/{spaceId}/override-mood';
  static const String musicControlEndpoint =
      '/api/spaces/{spaceId}/music/control';
  static const String getPlaylistEndpoint = '/api/playlists/{playlistId}';

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
}
