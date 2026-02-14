import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String username,
    required String password,
  });

  Future<void> logout();

  Future<UserModel> getCurrentUser();

  Future<String> requestPasswordReset(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    final response = await dioClient.post(
      ApiConstants.login,
      data: {
        'username': username,
        'password': password,
      },
    );

    return UserModel.fromJson(response.data['user']);
  }

  @override
  Future<void> logout() async {
    await dioClient.post(ApiConstants.logout);
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await dioClient.get(ApiConstants.currentUser);
    return UserModel.fromJson(response.data['user']);
  }

  @override
  Future<String> requestPasswordReset(String email) async {
    final response = await dioClient.post(
      ApiConstants.forgotPassword,
      data: {'email': email},
    );
    return response.data['message'] ?? 'Password reset email sent successfully';
  }
}
