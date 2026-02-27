import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';

import '../constants/api_constants.dart';
import '../error/exceptions.dart';
import '../services/local_storage_service.dart';

class DioClient {
  late final Dio _dio;
  final LocalStorageService _localStorage;
  late final PersistCookieJar _cookieJar;
  bool _isRefreshing = false;

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

    // Auth token interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Skip token injection for login and refresh-token endpoints
          final path = options.path;
          if (path == ApiConstants.login) {
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

  /// Initialize persistent cookie jar for HttpOnly refresh token cookies.
  /// Must be called after app starts (needs path_provider).
  Future<void> initCookieJar() async {
    final dir = await getApplicationDocumentsDirectory();
    _cookieJar = PersistCookieJar(
      storage: FileStorage('${dir.path}/.cookies/'),
    );
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  /// Clear all cookies (used on logout).
  Future<void> clearCookies() async {
    await _cookieJar.deleteAll();
  }

  /// Attempt to refresh the access token using the HttpOnly cookie.
  Future<String?> _refreshToken() async {
    try {
      // Include expired access token in header (backend allows it for refresh)
      final expiredToken = await _localStorage.getAuthToken();
      final response = await _dio.post(
        ApiConstants.refreshToken,
        options: Options(
          headers: {
            if (expiredToken != null) 'Authorization': 'Bearer $expiredToken',
          },
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

        return newToken;
      }

      throw AuthenticationException('Refresh token failed');
    } on DioException {
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
