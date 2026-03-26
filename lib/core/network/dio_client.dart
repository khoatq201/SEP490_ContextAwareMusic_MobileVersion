import 'dart:async';
import 'dart:developer' as developer;
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/api_constants.dart';
import '../error/exceptions.dart';
import '../services/local_storage_service.dart';

class DioClient {
  late final Dio _dio;
  final LocalStorageService _localStorage;
  PersistCookieJar? _cookieJar;
  Completer<String?>? _refreshCompleter;
  final StreamController<void> _sessionInvalidatedController =
      StreamController<void>.broadcast();

  bool _shouldSkipAuthorization(String path) {
    return path == ApiConstants.login ||
        path == ApiConstants.refreshToken ||
        path == ApiConstants.authPair ||
        path == ApiConstants.authDeviceRefreshToken;
  }

  String _normalizePath(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      final uri = Uri.tryParse(path);
      return uri?.path ?? path;
    }
    return path;
  }

  bool _isPlaybackDeviceScopedPath(String path) {
    final normalizedPath = _normalizePath(path).toLowerCase();
    final managerScopedPlaybackPattern = RegExp(
      r'^/api/cams/spaces/[^/]+/(playback|override|state|state/audio|queue|queue/tracks|queue/playlist|queue/reorder|queue/all|pair-device)$',
    );
    return normalizedPath == '/api/cams/spaces/playback' ||
        normalizedPath == '/api/cams/spaces/override' ||
        normalizedPath == ApiConstants.camsCurrentDeviceState.toLowerCase() ||
        normalizedPath ==
            ApiConstants.camsCurrentDeviceAudioState.toLowerCase() ||
        normalizedPath ==
            ApiConstants.camsCurrentDeviceQueueTracks.toLowerCase() ||
        normalizedPath ==
            ApiConstants.camsCurrentDeviceQueuePlaylist.toLowerCase() ||
        normalizedPath ==
            ApiConstants.camsCurrentDeviceQueueReorder.toLowerCase() ||
        normalizedPath == ApiConstants.camsCurrentDeviceQueue.toLowerCase() ||
        normalizedPath ==
            ApiConstants.camsCurrentDeviceQueueAll.toLowerCase() ||
        normalizedPath == ApiConstants.camsCurrentPairDevice.toLowerCase() ||
        managerScopedPlaybackPattern.hasMatch(normalizedPath);
  }

  bool _hasDeviceRefreshContext() {
    final refreshToken = _localStorage.getDeviceRefreshToken();
    return refreshToken != null && refreshToken.isNotEmpty;
  }

  bool _hasDeviceAccessContext() {
    final accessToken = _localStorage.getDeviceAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  String _deviceExpiryDebugValue() {
    final expiry = _localStorage.getDeviceAccessTokenExpiry();
    if (expiry == null) return 'null';
    return expiry.toUtc().toIso8601String();
  }

  String _managerExpiryDebugValue() {
    final expiry = _localStorage.getManagerAccessTokenExpiry();
    if (expiry == null) return 'null';
    return expiry.toUtc().toIso8601String();
  }

  void _logAuthSnapshot(String label, {String? path}) {
    final managerToken = _localStorage.getManagerAuthToken();
    final deviceToken = _localStorage.getDeviceAccessToken();
    final deviceRefreshToken = _localStorage.getDeviceRefreshToken();
    final deviceSession = _localStorage.getDeviceSession();
    _log(
      '[$label] '
      'path=${path ?? '-'} '
      'activeMode=${_localStorage.getActiveSessionMode()} '
      'hasManagerToken=${managerToken != null && managerToken.isNotEmpty} '
      'managerExpiry=${_managerExpiryDebugValue()} '
      'hasDeviceAccessToken=${deviceToken != null && deviceToken.isNotEmpty} '
      'deviceAccessExpiry=${_deviceExpiryDebugValue()} '
      'hasDeviceRefreshToken=${deviceRefreshToken != null && deviceRefreshToken.isNotEmpty} '
      'deviceSessionKeys=${deviceSession?.keys.join(',') ?? '(none)'}',
    );
  }

  String? _resolveAuthorizationTokenForRequest(String path) {
    final mode = _localStorage.getActiveSessionMode();
    final managerToken = _localStorage.getManagerAuthToken();
    final deviceToken = _localStorage.getDeviceAccessToken();
    final hasManagerToken = managerToken != null && managerToken.isNotEmpty;
    final hasDeviceToken = deviceToken != null && deviceToken.isNotEmpty;
    final isPlaybackScopedPath = _isPlaybackDeviceScopedPath(path);

    if (mode == LocalStorageService.sessionModePlaybackDevice) {
      if (hasDeviceToken) return deviceToken;
      return managerToken;
    }

    if (mode == LocalStorageService.sessionModeManager) {
      if (hasManagerToken) return managerToken;
      if (isPlaybackScopedPath && hasDeviceToken) return deviceToken;
      return null;
    }

    if (isPlaybackScopedPath && hasDeviceToken) {
      return deviceToken;
    }

    if (hasManagerToken) return managerToken;
    if (hasDeviceToken) return deviceToken;
    return null;
  }

  void _notifySessionInvalidated() {
    if (_sessionInvalidatedController.isClosed) return;
    _sessionInvalidatedController.add(null);
  }

  void _log(String message) {
    developer.log(message, name: 'DioClient');
    debugPrint('[DioClient] $message');
  }

  String _tokenPreview(String token) {
    if (token.isEmpty) return '(empty)';
    final previewLength = token.length < 12 ? token.length : 12;
    return '${token.substring(0, previewLength)}...';
  }

  DioClient({required LocalStorageService localStorage})
      : _localStorage = localStorage {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: ApiConstants.defaultHeaders,
      ),
    );

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
    ));

    // NOTE: CookieManager is added in initCookieJar() and MUST be called
    // before the auth interceptor below so cookies are attached first.
    // The auth token interceptor is added after initCookieJar() completes.
  }

  /// Initialize persistent cookie jar for HttpOnly refresh token cookies.
  /// Must be called after app starts (needs path_provider).
  /// Adds CookieManager BEFORE the auth interceptor so cookies are
  /// properly attached on every request (including refresh-token).
  Future<void> initCookieJar() async {
    final dir = await getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(
      ignoreExpires: true, // Always send cookies — let the server validate
      storage: FileStorage('${dir.path}/.cookies/'),
    );

    // 1. Add CookieManager FIRST — so cookies (incl. HttpOnly refresh token)
    //    are attached to every outgoing request.
    _dio.interceptors.add(CookieManager(_cookieJar!));

    // 2. Log Set-Cookie headers from login/refresh responses for debugging.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          final path = response.requestOptions.path;
          if (path == ApiConstants.login || path == ApiConstants.refreshToken) {
            final setCookie = response.headers['set-cookie'];
            _log('Set-Cookie from $path: ${setCookie ?? '(none)'}');
          }
          return handler.next(response);
        },
      ),
    );

    // 3. THEN add the auth token interceptor — so it can read/write the
    //    Authorization header after cookies are already attached.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final path = options.path;
          if (_shouldSkipAuthorization(path)) {
            return handler.next(options);
          }

          final token = _resolveAuthorizationTokenForRequest(path);
          final isPlaybackScopedPath = _isPlaybackDeviceScopedPath(path);
          _log(
            'Preparing auth header for "$path": '
            'playbackScoped=$isPlaybackScopedPath '
            'selectedToken=${token == null ? 'none' : _tokenPreview(token)}',
          );
          _logAuthSnapshot('request-auth', path: path);
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          final path = error.requestOptions.path;
          if (error.response?.statusCode == 401 &&
              !_shouldSkipAuthorization(path)) {
            _log(
              '401 on "$path" -> attempting token refresh '
              '(activeMode=${_localStorage.getActiveSessionMode()})',
            );
            String? refreshedToken;
            final inFlightRefresh = _refreshCompleter;
            if (inFlightRefresh != null) {
              refreshedToken = await inFlightRefresh.future;
            } else {
              final refreshCompleter = Completer<String?>();
              _refreshCompleter = refreshCompleter;
              try {
                refreshedToken = await _refreshActiveSessionToken(
                  failedRequestOptions: error.requestOptions,
                );
                if (!refreshCompleter.isCompleted) {
                  refreshCompleter.complete(refreshedToken);
                }
              } on AuthenticationException {
                if (!refreshCompleter.isCompleted) {
                  refreshCompleter.complete(null);
                }
              } catch (_) {
                if (!refreshCompleter.isCompleted) {
                  refreshCompleter.complete(null);
                }
              } finally {
                _refreshCompleter = null;
              }
            }

            if (refreshedToken != null && refreshedToken.isNotEmpty) {
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $refreshedToken';
              final response = await _dio.fetch(opts);
              _log(
                'Retry succeeded for "$path" after refresh '
                '(status=${response.statusCode})',
              );
              return handler.resolve(response);
            }
            return handler.next(error);
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Clear all cookies (used on logout).
  Future<void> clearCookies() async {
    await _cookieJar?.deleteAll();
  }

  Stream<void> get onSessionInvalidated => _sessionInvalidatedController.stream;

  Future<String?> refreshPlaybackDeviceTokenIfNeeded({
    Duration threshold = const Duration(minutes: 2),
    bool force = false,
  }) async {
    final refreshToken = _localStorage.getDeviceRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }

    final expiry = _localStorage.getDeviceAccessTokenExpiry();
    final now = DateTime.now().toUtc();
    final shouldRefresh =
        force || expiry == null || !expiry.isAfter(now.add(threshold));
    if (!shouldRefresh) {
      return _localStorage.getDeviceAccessToken();
    }

    final inFlightRefresh = _refreshCompleter;
    if (inFlightRefresh != null) {
      return inFlightRefresh.future;
    }

    final refreshCompleter = Completer<String?>();
    _refreshCompleter = refreshCompleter;
    try {
      final refreshedToken = await _refreshDeviceToken();
      if (!refreshCompleter.isCompleted) {
        refreshCompleter.complete(refreshedToken);
      }
      return refreshedToken;
    } on AuthenticationException {
      if (!refreshCompleter.isCompleted) {
        refreshCompleter.complete(null);
      }
      return null;
    } catch (_) {
      if (!refreshCompleter.isCompleted) {
        refreshCompleter.complete(null);
      }
      return null;
    } finally {
      _refreshCompleter = null;
    }
  }

  Future<void> _clearLocalSessionAfterRefreshFailure(
    String reason, {
    required bool playbackSession,
  }) async {
    try {
      if (playbackSession) {
        await _localStorage.clearDeviceSession();
      } else {
        await _localStorage.clearManagerSession();
        await clearCookies();
      }
      _log('Cleared local auth session after refresh failure ($reason)');
      _notifySessionInvalidated();
    } catch (e) {
      _log('Failed to clear local auth session after refresh failure: $e');
    }
  }

  /// Debug helper: print all cookies currently matched for [path].
  /// Use this after login to verify refresh-token cookie is actually stored.
  Future<void> debugDumpCookiesForPath({
    required String path,
    String label = 'cookie-dump',
  }) async {
    if (_cookieJar == null) {
      _log('[$label] Cookie jar is null (initCookieJar may not be called)');
      return;
    }

    final uri = path.startsWith('http')
        ? Uri.parse(path)
        : Uri.parse('${ApiConstants.baseUrl}$path');
    final cookies = await _cookieJar!.loadForRequest(uri);
    final cookieLines = cookies
        .map(
          (c) =>
              '${c.name}: len=${c.value.length}, secure=${c.secure}, httpOnly=${c.httpOnly}, domain=${c.domain}, path=${c.path}, expires=${c.expires}',
        )
        .toList();

    _log('[$label] uri=$uri -> count=${cookies.length}');
    for (final line in cookieLines) {
      _log('[$label] $line');
    }

    final baseUri = Uri.parse(ApiConstants.baseUrl);
    final baseCookies = await _cookieJar!.loadForRequest(baseUri);
    _log('[$label] baseUri=$baseUri -> count=${baseCookies.length}');
    for (final c in baseCookies) {
      _log(
        '[$label] base ${c.name}: len=${c.value.length}, secure=${c.secure}, httpOnly=${c.httpOnly}, domain=${c.domain}, path=${c.path}, expires=${c.expires}',
      );
    }
  }

  Future<String?> _refreshActiveSessionToken({
    required RequestOptions failedRequestOptions,
  }) async {
    final mode = _localStorage.getActiveSessionMode();
    final failedPath = failedRequestOptions.path;
    final isPlaybackScopedPath = _isPlaybackDeviceScopedPath(failedPath);
    final managerToken = _localStorage.getManagerAuthToken();
    final hasManagerToken = managerToken != null && managerToken.isNotEmpty;
    final hasDeviceAccessContext = _hasDeviceAccessContext();
    final hasDeviceRefreshContext = _hasDeviceRefreshContext();
    _log(
      'Refresh decision for "$failedPath": '
      'mode=$mode, playbackScoped=$isPlaybackScopedPath, '
      'hasManagerToken=$hasManagerToken, '
      'hasDeviceAccessContext=$hasDeviceAccessContext, '
      'hasDeviceRefreshContext=$hasDeviceRefreshContext',
    );
    _logAuthSnapshot('refresh-decision', path: failedPath);

    if (mode == LocalStorageService.sessionModePlaybackDevice) {
      _log('Refreshing playback-device token (active mode: playback_device)');
      return _refreshDeviceToken();
    }

    if (mode == LocalStorageService.sessionModeManager) {
      if (!hasManagerToken && hasDeviceRefreshContext) {
        _log(
          'Active mode is manager but manager token is empty; '
          'falling back to playback-device refresh.',
        );
        return _refreshDeviceToken();
      }
      if (isPlaybackScopedPath && hasDeviceRefreshContext) {
        _log(
          'Request path "$failedPath" is playback-device scoped while active '
          'mode is manager; using playback-device refresh.',
        );
        return _refreshDeviceToken();
      }
      _log('Refreshing manager token (active mode: manager)');
      return _refreshManagerToken();
    }

    if (isPlaybackScopedPath && hasDeviceRefreshContext) {
      _log(
        'Active session mode is unset; playback-device scoped request '
        'detected for "$failedPath", using playback-device refresh.',
      );
      return _refreshDeviceToken();
    }

    if (hasManagerToken) {
      _log(
        'Active session mode is unset; manager token present, '
        'using manager refresh.',
      );
      return _refreshManagerToken();
    }

    if (hasDeviceRefreshContext) {
      _log(
        'Active session mode is unset; playback-device refresh token present, '
        'using playback-device refresh.',
      );
      return _refreshDeviceToken();
    }

    _log(
      'No refresh context available for failed request "$failedPath" '
      '(mode=$mode, hasManagerToken=$hasManagerToken, '
      'hasDeviceRefreshContext=$hasDeviceRefreshContext).',
    );
    _notifySessionInvalidated();
    return null;
  }

  /// Attempt to refresh the manager access token using the HttpOnly cookie.
  Future<String?> _refreshManagerToken() async {
    try {
      if (_cookieJar != null) {
        final uri =
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshToken}');
        final cookies = await _cookieJar!.loadForRequest(uri);
        _log(
          'Refresh token - cookies for $uri: '
          '${cookies.map((c) => '${c.name}=${c.value.length > 10 ? c.value.substring(0, 10) : c.value}...').toList()}',
        );
        if (cookies.isEmpty) {
          // Also check the base URL (different path may yield different results)
          final baseUri = Uri.parse(ApiConstants.baseUrl);
          final baseCookies = await _cookieJar!.loadForRequest(baseUri);
          _log(
            'WARNING: No cookies for refresh URI. '
            'Base URL cookies ($baseUri): '
            '${baseCookies.map((c) => c.name).toList()}. '
            'The server may not have set the refresh token cookie during login, '
            'or the cookie domain/path does not match the request URL.',
          );
        }
      }

      final expiredToken = _localStorage.getManagerAuthToken();
      _log(
        'Refresh token - sending with Authorization: '
        '${expiredToken != null ? "Bearer ${expiredToken.substring(0, 20)}..." : "null"}',
      );

      final response = await _dio.post(
        ApiConstants.refreshToken,
        options: Options(
          headers: {
            if (expiredToken != null) 'Authorization': 'Bearer $expiredToken',
          },
          // Ensure cookies are sent even for cross-origin requests
          extra: {'withCredentials': true},
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['isSuccess'] == true &&
          data['data'] != null) {
        final newToken = data['data']['accessToken'] as String;
        final expiresAt = DateTime.parse(data['data']['expiresAt'] as String);

        await _localStorage.saveManagerAuthToken(newToken);
        await _localStorage.saveManagerAccessTokenExpiry(expiresAt);
        await _localStorage
            .saveActiveSessionMode(LocalStorageService.sessionModeManager);

        _log('Token refreshed successfully');
        return newToken;
      }

      throw AuthenticationException('Refresh token failed');
    } on AuthenticationException {
      await _clearLocalSessionAfterRefreshFailure(
        'invalid refresh response',
        playbackSession: false,
      );
      rethrow;
    } on DioException catch (e) {
      _log(
        'Refresh token DioException: ${e.response?.statusCode} - ${e.response?.data}',
      );
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        await _clearLocalSessionAfterRefreshFailure(
          'refresh endpoint returned $statusCode',
          playbackSession: false,
        );
      }
      throw AuthenticationException(
        'Session expired. Please login again.',
      );
    }
  }

  Future<String?> _refreshDeviceToken() async {
    try {
      final expiredToken = _localStorage.getDeviceAccessToken();
      final refreshToken = _localStorage.getDeviceRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        throw AuthenticationException('Missing device refresh token.');
      }

      _log(
        'Calling device refresh endpoint "${ApiConstants.authDeviceRefreshToken}" '
        '(hasExpiredAccessToken=${expiredToken != null && expiredToken.isNotEmpty}, '
        'refreshTokenPreview=${_tokenPreview(refreshToken)})',
      );
      _logAuthSnapshot('device-refresh-before-call',
          path: ApiConstants.authDeviceRefreshToken);

      final response = await _dio.post(
        ApiConstants.authDeviceRefreshToken,
        data: {
          'deviceRefreshToken': refreshToken,
        },
        options: Options(
          headers: {
            if (expiredToken != null && expiredToken.isNotEmpty)
              'Authorization': 'Bearer $expiredToken',
          },
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['isSuccess'] == true &&
          data['data'] != null) {
        final payload = Map<String, dynamic>.from(data['data'] as Map);
        final newToken =
            (payload['deviceAccessToken'] ?? payload['accessToken']) as String?;
        if (newToken == null || newToken.isEmpty) {
          throw AuthenticationException(
            'Device refresh response missing access token.',
          );
        }

        final rotatedRefreshToken = (payload['deviceRefreshToken'] ??
            payload['refreshToken']) as String?;
        final expiresRaw = payload['expiresAt'] ??
            payload['accessTokenExpiresAt'] ??
            payload['deviceAccessTokenExpiresAt'];
        final expiresAt =
            DateTime.tryParse(expiresRaw?.toString() ?? '')?.toUtc();
        if (expiresAt == null) {
          throw AuthenticationException(
            'Device refresh response missing token expiry.',
          );
        }

        await _localStorage.saveDeviceAccessToken(newToken);
        if (rotatedRefreshToken != null && rotatedRefreshToken.isNotEmpty) {
          await _localStorage.saveDeviceRefreshToken(rotatedRefreshToken);
        }
        await _localStorage.saveDeviceAccessTokenExpiry(expiresAt);
        await _localStorage.saveActiveSessionMode(
          LocalStorageService.sessionModePlaybackDevice,
        );

        _log(
          'Device token refreshed successfully '
          '(accessTokenPreview=${_tokenPreview(newToken)}, '
          'expiresAt=${expiresAt.toIso8601String()})',
        );
        _logAuthSnapshot('device-refresh-success',
            path: ApiConstants.authDeviceRefreshToken);
        return newToken;
      }

      throw AuthenticationException('Device refresh token failed.');
    } on AuthenticationException {
      await _clearLocalSessionAfterRefreshFailure(
        'invalid device refresh',
        playbackSession: true,
      );
      rethrow;
    } on DioException catch (e) {
      _log(
        'Device refresh DioException: ${e.response?.statusCode} - ${e.response?.data}',
      );
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        await _clearLocalSessionAfterRefreshFailure(
          'device refresh endpoint returned $statusCode',
          playbackSession: true,
        );
      }
      throw AuthenticationException(
        'Device session expired. Please pair again.',
      );
    }
  }

  Dio get dio => _dio;

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<void> dispose() async {
    await _sessionInvalidatedController.close();
  }
}
