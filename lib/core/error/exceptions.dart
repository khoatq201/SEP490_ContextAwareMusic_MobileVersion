class ServerException implements Exception {
  final String message;
  ServerException([this.message = 'Server error occurred']);
}

class NetworkException implements Exception {
  final String message;
  NetworkException([this.message = 'No internet connection']);
}

class CacheException implements Exception {
  final String message;
  CacheException([this.message = 'Cache error occurred']);
}

class AuthenticationException implements Exception {
  final String message;
  AuthenticationException([this.message = 'Authentication failed']);
}

class MqttConnectionException implements Exception {
  final String message;
  MqttConnectionException([this.message = 'MQTT connection failed']);
}
