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
  bool _isRefreshing = false;

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
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
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
          // Skip token injection for login and refresh-token endpoints
          final path = options.path;
          if (path == ApiConstants.login || path == ApiConstants.refreshToken) {
            return handler.next(options);
          }

          final token = await _localStorage.getAuthToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 with automatic token refresh
          if (error.response?.statusCode == 401 &&
              error.requestOptions.path != ApiConstants.login &&
              error.requestOptions.path != ApiConstants.refreshToken) {
            if (!_isRefreshing) {
              _isRefreshing = true;
              try {
                final newToken = await _refreshToken();
                if (newToken != null) {
                  // Retry original request with new token
                  final opts = error.requestOptions;
                  opts.headers['Authorization'] = 'Bearer $newToken';
                  final response = await _dio.fetch(opts);
                  return handler.resolve(response);
                }
              } on AuthenticationException {
                // Refresh failed — propagate as 401
              } catch (_) {
                // Unexpected error during refresh
              } finally {
                _isRefreshing = false;
              }
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
      await _localStorage.clearAuthToken();
      await _localStorage.clearUser();
      await clearCookies();
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

  /// Attempt to refresh the access token using the HttpOnly cookie.
  Future<String?> _refreshToken() async {
    try {
      // Log cookies for debugging
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

      // Include expired access token in header (backend requires it for refresh)
      final expiredToken = await _localStorage.getAuthToken();
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

        await _localStorage.saveAuthToken(newToken);
        await _localStorage.saveAccessTokenExpiry(expiresAt);

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
