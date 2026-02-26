import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';
import 'auth_remote_datasource.dart';

/// Mock Auth Data Source for demo purposes
/// Allows login with demo credentials: admin/admin123
class AuthMockDataSource implements AuthRemoteDataSource {
  final Map<String, UserModel> _mockUsers = {
    'admin': const UserModel(
      id: 'demo-admin-001',
      username: 'admin',
      email: 'admin@cams-demo.com',
      fullName: 'Demo Administrator',
      role: 'admin',
      storeIds: ['store-1', 'store-2', 'store-3'],
    ),
    'store': const UserModel(
      id: 'demo-store-123',
      username: 'store',
      email: 'manager@store.com',
      fullName: 'Store Manager',
      role: 'store_manager',
      storeIds: ['store-1'],
    ),
    'brand': const UserModel(
      id: 'demo-brand-999',
      username: 'brand',
      email: 'director@brand.com',
      fullName: 'Brand Director',
      role: 'brand_manager',
      storeIds: ['store-1', 'store-2', 'store-3'],
    ),
  };

  @override
  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Check demo credentials
    final user = _mockUsers[username.toLowerCase()];
    if (user != null && password == '${username.toLowerCase()}123') {
      return user;
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
    return _mockUsers['admin']!;
  }

  @override
  Future<String> requestPasswordReset(String email) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return 'Password reset instructions have been sent to $email';
  }
}
