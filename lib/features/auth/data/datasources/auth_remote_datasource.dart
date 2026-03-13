import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/models/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/auth_response_model.dart';
import '../models/profile_response_model.dart';

/// Contract for auth-related API calls.
abstract class AuthRemoteDataSource {
  /// POST /api/auth/login
  Future<AuthResponseModel> login({
    required String email,
    required String password,
    bool rememberMe = false,
  });

  /// POST /api/auth/logout
  Future<void> logout();

  /// GET /api/auth/profile
  Future<ProfileResponseModel> getProfile();

  /// POST /api/auth/refresh-token
  Future<AuthResponseModel> refreshToken();

  /// POST /api/auth/change-password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;
  final LocalStorageService localStorage;

  AuthRemoteDataSourceImpl({
    required this.dioClient,
    required this.localStorage,
  });

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final response = await dioClient.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
          'rememberMe': rememberMe,
        },
      );

      debugPrint(
        '[AuthRemoteDataSource] login set-cookie: ${response.headers['set-cookie']}',
      );
      await dioClient.debugDumpCookiesForPath(
        path: ApiConstants.refreshToken,
        label: 'after-login',
      );

      final apiResult = ApiResult<AuthResponseModel>.fromJson(
        response.data as Map<String, dynamic>,
        fromData: (data) =>
            AuthResponseModel.fromJson(data as Map<String, dynamic>),
      );

      if (!apiResult.isSuccess || apiResult.data == null) {
        throw ServerException(apiResult.userFriendlyError);
      }

      return apiResult.data!;
    } on DioException catch (e) {
      _throwApiError(
        e,
        fallbackMessage: 'Login failed. Please check your credentials.',
      );
    }
  }

  @override
  Future<void> logout() async {
    final response = await dioClient.post(ApiConstants.logout);

    final apiResult = ApiResult<void>.fromJson(
      response.data as Map<String, dynamic>,
    );

    if (!apiResult.isSuccess) {
      throw ServerException(apiResult.userFriendlyError);
    }
  }

  @override
  Future<ProfileResponseModel> getProfile() async {
    final response = await dioClient.get(ApiConstants.profile);

    final apiResult = ApiResult<ProfileResponseModel>.fromJson(
      response.data as Map<String, dynamic>,
      fromData: (data) =>
          ProfileResponseModel.fromJson(data as Map<String, dynamic>),
    );

    if (!apiResult.isSuccess || apiResult.data == null) {
      throw ServerException(apiResult.userFriendlyError);
    }

    return apiResult.data!;
  }

  @override
  Future<AuthResponseModel> refreshToken() async {
    // Backend requires the (possibly expired) access token in the header
    final expiredToken = await localStorage.getAuthToken();
    debugPrint(
      '[AuthRemoteDataSource] refreshToken auth header present: ${expiredToken != null && expiredToken.isNotEmpty}',
    );
    await dioClient.debugDumpCookiesForPath(
      path: ApiConstants.refreshToken,
      label: 'before-refresh-request',
    );

    final response = await dioClient.post(
      ApiConstants.refreshToken,
      options: Options(
        headers: {
          if (expiredToken != null) 'Authorization': 'Bearer $expiredToken',
        },
      ),
    );

    debugPrint(
      '[AuthRemoteDataSource] refresh response set-cookie: ${response.headers['set-cookie']}',
    );
    await dioClient.debugDumpCookiesForPath(
      path: ApiConstants.refreshToken,
      label: 'after-refresh-response',
    );

    final apiResult = ApiResult<AuthResponseModel>.fromJson(
      response.data as Map<String, dynamic>,
      fromData: (data) =>
          AuthResponseModel.fromJson(data as Map<String, dynamic>),
    );

    if (!apiResult.isSuccess || apiResult.data == null) {
      throw ServerException(apiResult.userFriendlyError);
    }

    return apiResult.data!;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await dioClient.post(
      ApiConstants.changePassword,
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );

    final apiResult = ApiResult<void>.fromJson(
      response.data as Map<String, dynamic>,
    );

    if (!apiResult.isSuccess) {
      throw ServerException(apiResult.userFriendlyError);
    }
  }

  Never _throwApiError(
    DioException e, {
    required String fallbackMessage,
  }) {
    final responseData = e.response?.data;
    if (responseData is Map) {
      final json = Map<String, dynamic>.from(responseData);
      final apiResult = ApiResult<void>.fromJson(json);
      throw ServerException(apiResult.userFriendlyError);
    }
    throw ServerException(fallbackMessage);
  }
}
