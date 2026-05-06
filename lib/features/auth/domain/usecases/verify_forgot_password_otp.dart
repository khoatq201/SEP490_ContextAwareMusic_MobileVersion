import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/forgot_password_metadata.dart';
import '../repositories/auth_repository.dart';

class VerifyForgotPasswordOtp {
  VerifyForgotPasswordOtp(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, ForgotPasswordVerifyInfo>> call({
    required String email,
    required String otp,
  }) async {
    final normalizedEmail = email.trim();
    final normalizedOtp = otp.trim();
    if (normalizedEmail.isEmpty) {
      return const Left(ValidationFailure('Please enter your email'));
    }
    if (!RegExp(r'^\d{6}$').hasMatch(normalizedOtp)) {
      return const Left(
        ValidationFailure('Please enter the 6-digit verification code'),
      );
    }

    return repository.verifyForgotPasswordOtp(
      email: normalizedEmail,
      otp: normalizedOtp,
    );
  }
}
