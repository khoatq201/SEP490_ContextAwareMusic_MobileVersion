import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';
import 'auth_remote_datasource.dart';

/// Mock Auth Data Source for demo purposes
/// Allows login with demo credentials: admin/admin123
class AuthMockDataSource implements AuthRemoteDataSource {
  // Mock user data
  final UserModel _mockUser = UserModel(
    id: 'demo-user-001',
    username: 'admin',
    email: 'admin@cams-demo.com',
    fullName: 'Demo Administrator',
    role: 'admin',
    storeIds: [
      'store-001',
      'store-002',
      'store-003'
    ], // Multiple stores for testing
  );

  @override
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Check demo credentials
    if (username.toLowerCase() == 'admin' && password == 'admin123') {
      return _mockUser;
    }

    // Invalid credentials
    throw ServerException('Invalid username or password');
  }

  @override
  Future<void> logout() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock logout - always succeeds
  }

  @override
  Future<UserModel> getCurrentUser() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockUser;
  }

  @override
  Future<String> requestPasswordReset(String email) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return 'Password reset instructions have been sent to $email';
  }
}
