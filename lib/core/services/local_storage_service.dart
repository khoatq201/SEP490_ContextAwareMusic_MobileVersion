import 'package:hive_flutter/hive_flutter.dart';
import '../error/exceptions.dart';

class LocalStorageService {
  static const String _authBoxName = 'auth_box';
  static const String _playlistBoxName = 'playlist_box';
  static const String _settingsBoxName = 'settings_box';
  static const String sessionModeManager = 'manager';
  static const String sessionModePlaybackDevice = 'playback_device';

  static const String _legacyTokenKey = 'token';
  static const String _legacyTokenExpiryKey = 'token_expiry';
  static const String _managerTokenKey = 'manager_token';
  static const String _managerTokenExpiryKey = 'manager_token_expiry';
  static const String _managerUserKey = 'user';
  static const String _deviceSessionKey = 'device_session';
  static const String _activeSessionModeKey = 'active_session_mode';

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
    await saveManagerAuthToken(token);
  }

  String? getToken() {
    final mode = getActiveSessionMode();
    if (mode == sessionModePlaybackDevice) {
      return getDeviceAccessToken();
    }
    return getManagerAuthToken();
  }

  Future<void> removeToken() async {
    await clearManagerAuthToken();
  }

  Future<void> saveManagerAuthToken(String token) async {
    try {
      await _authBox.put(_managerTokenKey, token);
      await _authBox.put(_legacyTokenKey, token);
    } catch (e) {
      throw CacheException('Failed to save manager token');
    }
  }

  Future<void> saveAuthToken(String token) async {
    await saveManagerAuthToken(token);
  }

  Future<String?> getAuthToken() async {
    return getToken();
  }

  Future<void> clearAuthToken() async {
    await clearManagerAuthToken();
  }

  String? getManagerAuthToken() {
    try {
      return (_authBox.get(_managerTokenKey) ?? _authBox.get(_legacyTokenKey))
          as String?;
    } catch (e) {
      throw CacheException('Failed to get manager token');
    }
  }

  Future<void> clearManagerAuthToken() async {
    try {
      await _authBox.delete(_managerTokenKey);
      await _authBox.delete(_legacyTokenKey);
      await _authBox.delete(_managerTokenExpiryKey);
      await _authBox.delete(_legacyTokenExpiryKey);
      if (getActiveSessionMode() == sessionModeManager) {
        await clearActiveSessionMode();
      }
    } catch (e) {
      throw CacheException('Failed to clear manager token');
    }
  }

  /// Save access token expiry time.
  Future<void> saveAccessTokenExpiry(DateTime expiresAt) async {
    await saveManagerAccessTokenExpiry(expiresAt);
  }

  Future<void> saveManagerAccessTokenExpiry(DateTime expiresAt) async {
    try {
      final value = expiresAt.toIso8601String();
      await _authBox.put(_managerTokenExpiryKey, value);
      await _authBox.put(_legacyTokenExpiryKey, value);
    } catch (e) {
      throw CacheException('Failed to save manager token expiry');
    }
  }

  /// Get access token expiry time.
  DateTime? getAccessTokenExpiry() {
    return getManagerAccessTokenExpiry();
  }

  DateTime? getManagerAccessTokenExpiry() {
    try {
      final expiry = (_authBox.get(_managerTokenExpiryKey) ??
          _authBox.get(_legacyTokenExpiryKey)) as String?;
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

  Future<void> saveDeviceSession(Map<String, dynamic> session) async {
    try {
      await _authBox.put(_deviceSessionKey, session);
    } catch (e) {
      throw CacheException('Failed to save device session');
    }
  }

  Map<String, dynamic>? getDeviceSession() {
    try {
      final raw = _authBox.get(_deviceSessionKey);
      if (raw is! Map) return null;
      return Map<String, dynamic>.from(raw);
    } catch (e) {
      throw CacheException('Failed to get device session');
    }
  }

  Future<void> updateDeviceSession(Map<String, dynamic> updates) async {
    final current = getDeviceSession() ?? <String, dynamic>{};
    current.addAll(updates);
    await saveDeviceSession(current);
  }

  String? getDeviceAccessToken() {
    return getDeviceSession()?['deviceAccessToken'] as String?;
  }

  Future<void> saveDeviceAccessToken(String token) async {
    await updateDeviceSession({'deviceAccessToken': token});
  }

  String? getDeviceRefreshToken() {
    return getDeviceSession()?['deviceRefreshToken'] as String?;
  }

  Future<void> saveDeviceRefreshToken(String token) async {
    await updateDeviceSession({'deviceRefreshToken': token});
  }

  DateTime? getDeviceAccessTokenExpiry() {
    final raw = getDeviceSession()?['accessTokenExpiresAt'] as String?;
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> saveDeviceAccessTokenExpiry(DateTime expiresAt) async {
    await updateDeviceSession({
      'accessTokenExpiresAt': expiresAt.toIso8601String(),
    });
  }

  bool isDeviceTokenExpired() {
    final expiry = getDeviceAccessTokenExpiry();
    if (expiry == null) return true;
    return DateTime.now().toUtc().isAfter(expiry);
  }

  Future<void> clearDeviceSession() async {
    try {
      await _authBox.delete(_deviceSessionKey);
      if (getActiveSessionMode() == sessionModePlaybackDevice) {
        await clearActiveSessionMode();
      }
    } catch (e) {
      throw CacheException('Failed to clear device session');
    }
  }

  Future<void> saveActiveSessionMode(String mode) async {
    try {
      await _authBox.put(_activeSessionModeKey, mode);
    } catch (e) {
      throw CacheException('Failed to save active session mode');
    }
  }

  String? getActiveSessionMode() {
    try {
      return _authBox.get(_activeSessionModeKey) as String?;
    } catch (e) {
      throw CacheException('Failed to get active session mode');
    }
  }

  Future<void> clearActiveSessionMode() async {
    try {
      await _authBox.delete(_activeSessionModeKey);
    } catch (e) {
      throw CacheException('Failed to clear active session mode');
    }
  }

  Future<void> clearManagerSession() async {
    await clearManagerAuthToken();
    await clearUser();
  }

  Future<void> clearAllAuthSessions() async {
    await clearManagerSession();
    await clearDeviceSession();
    await clearActiveSessionMode();
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    try {
      await _authBox.put(_managerUserKey, user);
    } catch (e) {
      throw CacheException('Failed to save user');
    }
  }

  Future<Map<String, dynamic>?> getUser() async {
    try {
      final user = _authBox.get(_managerUserKey);
      return user != null ? Map<String, dynamic>.from(user) : null;
    } catch (e) {
      throw CacheException('Failed to get user');
    }
  }

  Future<void> clearUser() async {
    try {
      await _authBox.delete(_managerUserKey);
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

  Future<void> removeSetting(String key) async {
    try {
      await _settingsBox.delete(key);
    } catch (e) {
      throw CacheException('Failed to remove setting');
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
