import '../../../../core/error/exceptions.dart';
import '../../../../core/models/api_result.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
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

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    final response = await dioClient.post(
      ApiConstants.login,
      data: {
        'email': email,
        'password': password,
        'rememberMe': rememberMe,
      },
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
    final response = await dioClient.post(ApiConstants.refreshToken);

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
}
