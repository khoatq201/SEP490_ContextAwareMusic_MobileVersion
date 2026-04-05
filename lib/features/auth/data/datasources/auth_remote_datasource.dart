import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/models/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/auth_response_model.dart';
import '../models/profile_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponseModel> login({
    required String email,
    required String password,
    bool rememberMe = false,
  });

  Future<void> logout();

  Future<ProfileResponseModel> getProfile();

  Future<AuthResponseModel> refreshToken();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required this.dioClient,
    required this.localStorage,
  });

  final DioClient dioClient;
  final LocalStorageService localStorage;

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
        throw ErrorMapper.fromApiErrorDetails(
          apiResult.errorDetails,
          fallbackMessage: 'Login failed. Please check your credentials.',
        );
      }

      return apiResult.data!;
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(
        error,
        fallbackMessage: 'Login failed. Please check your credentials.',
      );
    } on AppException {
      rethrow;
    } catch (error, stackTrace) {
      throw ErrorMapper.toException(
        error,
        fallbackMessage: 'Login failed. Please try again.',
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      final response = await dioClient.post(ApiConstants.logout);

      final apiResult = ApiResult<void>.fromJson(
        response.data as Map<String, dynamic>,
      );

      if (!apiResult.isSuccess) {
        throw ErrorMapper.fromApiErrorDetails(
          apiResult.errorDetails,
          fallbackMessage: 'We could not sign you out right now.',
        );
      }
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(
        error,
        fallbackMessage: 'We could not sign you out right now.',
      );
    }
  }

  @override
  Future<ProfileResponseModel> getProfile() async {
    try {
      final response = await dioClient.get(ApiConstants.profile);

      final apiResult = ApiResult<ProfileResponseModel>.fromJson(
        response.data as Map<String, dynamic>,
        fromData: (data) =>
            ProfileResponseModel.fromJson(data as Map<String, dynamic>),
      );

      if (!apiResult.isSuccess || apiResult.data == null) {
        throw ErrorMapper.fromApiErrorDetails(
          apiResult.errorDetails,
          fallbackMessage: 'We could not load your profile right now.',
        );
      }

      return apiResult.data!;
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(
        error,
        fallbackMessage: 'We could not load your profile right now.',
      );
    }
  }

  @override
  Future<AuthResponseModel> refreshToken() async {
    final expiredToken = localStorage.getManagerAuthToken();
    debugPrint(
      '[AuthRemoteDataSource] refreshToken auth header present: ${expiredToken != null && expiredToken.isNotEmpty}',
    );
    await dioClient.debugDumpCookiesForPath(
      path: ApiConstants.refreshToken,
      label: 'before-refresh-request',
    );

    try {
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
        throw ErrorMapper.fromApiErrorDetails(
          apiResult.errorDetails,
          fallbackMessage: 'Your session expired. Please sign in again.',
        );
      }

      return apiResult.data!;
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(
        error,
        fallbackMessage: 'Your session expired. Please sign in again.',
      );
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
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
        throw ErrorMapper.fromApiErrorDetails(
          apiResult.errorDetails,
          fallbackMessage: 'We could not change your password right now.',
        );
      }
    } on DioException catch (error) {
      throw ErrorMapper.fromDioException(
        error,
        fallbackMessage: 'We could not change your password right now.',
      );
    }
  }
}
