class ApiConstants {
  // Base URLs
  static const String baseUrl = 'https://api.cams.example.com';
  static const String mqttBrokerUrl = 'mqtt.cams.example.com';
  static const int mqttPort = 1883;

  // API Endpoints
  // Auth
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String currentUser = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';

  // Stores & Spaces
  static const String loginEndpoint = '/auth/login';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String getStoresEndpoint = '/stores';
  static const String getSpacesEndpoint = '/stores/{storeId}/spaces';
  static const String getSpaceDetailEndpoint = '/spaces/{spaceId}';
  static const String overrideMoodEndpoint = '/spaces/{spaceId}/override-mood';
  static const String musicControlEndpoint = '/spaces/{spaceId}/music/control';
  static const String getPlaylistEndpoint = '/playlists/{playlistId}';

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
