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

  bool _shouldSkipAuthorization(String path) {
    return path == ApiConstants.login ||
        path == ApiConstants.refreshToken ||
        path == ApiConstants.authPair ||
        path == ApiConstants.authDeviceRefreshToken;
  }

  void _log(String message) {
    developer.log(message, name: 'DioClient');
    debugPrint('[DioClient] $message');
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

          final token = _localStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          final path = error.requestOptions.path;
          if (error.response?.statusCode == 401 &&
              !_shouldSkipAuthorization(path)) {
            String? refreshedToken;
            final inFlightRefresh = _refreshCompleter;
            if (inFlightRefresh != null) {
              refreshedToken = await inFlightRefresh.future;
            } else {
              final refreshCompleter = Completer<String?>();
              _refreshCompleter = refreshCompleter;
              try {
                refreshedToken = await _refreshActiveSessionToken();
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

  Future<void> _clearLocalSessionAfterRefreshFailure(String reason) async {
    try {
      final isPlaybackMode = _localStorage.getActiveSessionMode() ==
          LocalStorageService.sessionModePlaybackDevice;
      if (isPlaybackMode) {
        await _localStorage.clearDeviceSession();
      } else {
        await _localStorage.clearManagerSession();
        await clearCookies();
      }
      _log('Cleared local auth session after refresh failure ($reason)');
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

  Future<String?> _refreshActiveSessionToken() async {
    final mode = _localStorage.getActiveSessionMode();
    if (mode == LocalStorageService.sessionModePlaybackDevice) {
      return _refreshDeviceToken();
    }
    return _refreshManagerToken();
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
      await _clearLocalSessionAfterRefreshFailure('invalid refresh response');
      rethrow;
    } on DioException catch (e) {
      _log(
        'Refresh token DioException: ${e.response?.statusCode} - ${e.response?.data}',
      );
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        await _clearLocalSessionAfterRefreshFailure(
          'refresh endpoint returned $statusCode',
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

        _log('Device token refreshed successfully');
        return newToken;
      }

      throw AuthenticationException('Device refresh token failed.');
    } on AuthenticationException {
      await _clearLocalSessionAfterRefreshFailure('invalid device refresh');
      rethrow;
    } on DioException catch (e) {
      _log(
        'Device refresh DioException: ${e.response?.statusCode} - ${e.response?.data}',
      );
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        await _clearLocalSessionAfterRefreshFailure(
          'device refresh endpoint returned $statusCode',
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
}
