import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/forgot_password_metadata.dart';
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

  /// Request password reset OTP for a public forgot password flow.
  Future<Either<Failure, ForgotPasswordOtpInfo>> requestForgotPasswordOtp({
    required String email,
  });

  /// Verify the OTP sent to the email in the forgot password flow.
  Future<Either<Failure, ForgotPasswordVerifyInfo>> verifyForgotPasswordOtp({
    required String email,
    required String otp,
  });

  /// Reset password after OTP verification.
  Future<Either<Failure, void>> resetForgotPassword({
    required String email,
    required String newPassword,
    required String confirmPassword,
  });

  /// Refresh access token (uses HttpOnly cookie refresh token).
  Future<Either<Failure, User>> refreshToken();
}
