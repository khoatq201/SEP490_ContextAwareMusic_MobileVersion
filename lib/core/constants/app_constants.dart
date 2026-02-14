class AppConstants {
  // App Info
  static const String appName = 'CAMS Store Manager';
  static const String appVersion = '1.0.0';

  // Moods
  static const List<String> availableMoods = [
    'Happy',
    'Chill',
    'Energetic',
    'Romantic',
    'Focus',
  ];

  // Space Status
  static const String spaceStatusOnline = 'Online';
  static const String spaceStatusOffline = 'Offline';
  static const String spaceStatusError = 'Error';

  // Player Status
  static const String playerStatusPlaying = 'Playing';
  static const String playerStatusPaused = 'Paused';
  static const String playerStatusStopped = 'Stopped';
  static const String playerStatusBuffering = 'Buffering';

  // Default Values
  static const int defaultOverrideDuration = 60; // minutes
  static const int maxSensorDataPoints = 100;
  static const int reconnectDelay = 5; // seconds
}
