import 'package:hive_flutter/hive_flutter.dart';
import '../error/exceptions.dart';

class LocalStorageService {
  static const String _authBoxName = 'auth_box';
  static const String _playlistBoxName = 'playlist_box';
  static const String _settingsBoxName = 'settings_box';

  late Box _authBox;
  late Box _playlistBox;
  late Box _settingsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _authBox = await Hive.openBox(_authBoxName);
    _playlistBox = await Hive.openBox(_playlistBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  // Auth operations
  Future<void> saveToken(String token) async {
    try {
      await _authBox.put('token', token);
    } catch (e) {
      throw CacheException('Failed to save token');
    }
  }

  String? getToken() {
    try {
      return _authBox.get('token') as String?;
    } catch (e) {
      throw CacheException('Failed to get token');
    }
  }

  Future<void> removeToken() async {
    try {
      await _authBox.delete('token');
    } catch (e) {
      throw CacheException('Failed to remove token');
    }
  }

  // New auth methods
  Future<void> saveAuthToken(String token) async {
    await saveToken(token);
  }

  Future<String?> getAuthToken() async {
    return getToken();
  }

  Future<void> clearAuthToken() async {
    await removeToken();
    await _authBox.delete('token_expiry');
  }

  /// Save access token expiry time.
  Future<void> saveAccessTokenExpiry(DateTime expiresAt) async {
    try {
      await _authBox.put('token_expiry', expiresAt.toIso8601String());
    } catch (e) {
      throw CacheException('Failed to save token expiry');
    }
  }

  /// Get access token expiry time.
  DateTime? getAccessTokenExpiry() {
    try {
      final expiry = _authBox.get('token_expiry') as String?;
      return expiry != null ? DateTime.parse(expiry) : null;
    } catch (e) {
      return null;
    }
  }

  /// Check if the access token is expired.
  bool isTokenExpired() {
    final expiry = getAccessTokenExpiry();
    if (expiry == null) return true;
    return DateTime.now().toUtc().isAfter(expiry);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    try {
      await _authBox.put('user', user);
    } catch (e) {
      throw CacheException('Failed to save user');
    }
  }

  Future<Map<String, dynamic>?> getUser() async {
    try {
      final user = _authBox.get('user');
      return user != null ? Map<String, dynamic>.from(user) : null;
    } catch (e) {
      throw CacheException('Failed to get user');
    }
  }

  Future<void> clearUser() async {
    try {
      await _authBox.delete('user');
    } catch (e) {
      throw CacheException('Failed to clear user');
    }
  }

  // Playlist operations
  Future<void> savePlaylist(
      String playlistId, Map<String, dynamic> playlist) async {
    try {
      await _playlistBox.put(playlistId, playlist);
    } catch (e) {
      throw CacheException('Failed to save playlist');
    }
  }

  Map<String, dynamic>? getPlaylist(String playlistId) {
    try {
      final data = _playlistBox.get(playlistId);
      if (data == null) return null;
      return Map<String, dynamic>.from(data as Map);
    } catch (e) {
      throw CacheException('Failed to get playlist');
    }
  }

  List<Map<String, dynamic>> getAllPlaylists() {
    try {
      return _playlistBox.values
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      throw CacheException('Failed to get all playlists');
    }
  }

  Future<void> removePlaylist(String playlistId) async {
    try {
      await _playlistBox.delete(playlistId);
    } catch (e) {
      throw CacheException('Failed to remove playlist');
    }
  }

  Future<void> clearAllPlaylists() async {
    try {
      await _playlistBox.clear();
    } catch (e) {
      throw CacheException('Failed to clear playlists');
    }
  }

  // Settings operations
  Future<void> saveSetting(String key, dynamic value) async {
    try {
      await _settingsBox.put(key, value);
    } catch (e) {
      throw CacheException('Failed to save setting');
    }
  }

  dynamic getSetting(String key) {
    try {
      return _settingsBox.get(key);
    } catch (e) {
      throw CacheException('Failed to get setting');
    }
  }

  Future<void> clearAll() async {
    try {
      await _authBox.clear();
      await _playlistBox.clear();
      await _settingsBox.clear();
    } catch (e) {
      throw CacheException('Failed to clear all data');
    }
  }
}
