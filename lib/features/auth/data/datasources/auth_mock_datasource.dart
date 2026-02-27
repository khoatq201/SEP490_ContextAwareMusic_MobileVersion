import '../../../../core/error/exceptions.dart';
import '../models/auth_response_model.dart';
import '../models/profile_response_model.dart';
import 'auth_remote_datasource.dart';

/// Mock Auth Data Source for demo/development purposes.
/// Allows login with demo credentials: admin@example.com / Admin@123
class AuthMockDataSource implements AuthRemoteDataSource {
  static const _mockProfiles = {
    'admin@example.com': ProfileResponseModel(
      userId: 'demo-admin-001',
      email: 'admin@example.com',
      firstName: 'Demo',
      lastName: 'Administrator',
      roles: ['SystemAdmin'],
      phoneNumber: null,
      avatarPath: null,
    ),
    'store@example.com': ProfileResponseModel(
      userId: 'demo-store-123',
      email: 'store@example.com',
      firstName: 'Store',
      lastName: 'Manager',
      roles: ['StoreManager'],
      phoneNumber: null,
      avatarPath: null,
    ),
    'brand@example.com': ProfileResponseModel(
      userId: 'demo-brand-999',
      email: 'brand@example.com',
      firstName: 'Brand',
      lastName: 'Director',
      roles: ['BrandManager'],
      phoneNumber: null,
      avatarPath: null,
    ),
  };

  static const _mockPasswords = {
    'admin@example.com': 'Admin@123',
    'store@example.com': 'Store@123',
    'brand@example.com': 'Brand@123',
  };

  String? _loggedInEmail;

  @override
  Future<AuthResponseModel> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final expectedPassword = _mockPasswords[email.toLowerCase()];
    if (expectedPassword != null && password == expectedPassword) {
      _loggedInEmail = email.toLowerCase();
      final profile = _mockProfiles[_loggedInEmail]!;
      return AuthResponseModel(
        accessToken: 'mock_access_token_${profile.userId}',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        roles: profile.roles,
      );
    }

    throw ServerException('Invalid email or password');
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _loggedInEmail = null;
  }

  @override
  Future<ProfileResponseModel> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final email = _loggedInEmail ?? 'admin@example.com';
    return _mockProfiles[email]!;
  }

  @override
  Future<AuthResponseModel> refreshToken() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final email = _loggedInEmail ?? 'admin@example.com';
    final profile = _mockProfiles[email]!;
    return AuthResponseModel(
      accessToken: 'mock_refreshed_token_${profile.userId}',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      roles: profile.roles,
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (newPassword != confirmPassword) {
      throw ServerException('New password and confirm password do not match');
    }
    // Mock: always succeeds
  }
}
