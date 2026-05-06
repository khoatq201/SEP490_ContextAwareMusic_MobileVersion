import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class ResetForgotPassword {
  ResetForgotPassword(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, void>> call({
    required String email,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (email.trim().isEmpty) {
      return const Left(ValidationFailure('Please enter your email'));
    }
    if (newPassword.length < 6) {
      return const Left(
        ValidationFailure('Password must be at least 6 characters'),
      );
    }
    if (newPassword != confirmPassword) {
      return const Left(ValidationFailure('Passwords do not match'));
    }

    return repository.resetForgotPassword(
      email: email.trim(),
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }
}
