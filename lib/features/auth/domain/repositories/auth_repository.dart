import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  /// Login with email & password. Returns User (fetched from /profile after login).
  Future<Either<Failure, User>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  });

  /// Logout and clear local tokens/session.
  Future<Either<Failure, void>> logout();

  /// Get current user profile (cache-first, then API fallback).
  Future<Either<Failure, User>> getCurrentUser();

  /// Check if user is logged in (has valid token in storage).
  Future<Either<Failure, bool>> isLoggedIn();

  /// Change password for the current user.
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  /// Refresh access token (uses HttpOnly cookie refresh token).
  Future<Either<Failure, User>> refreshToken();
}
