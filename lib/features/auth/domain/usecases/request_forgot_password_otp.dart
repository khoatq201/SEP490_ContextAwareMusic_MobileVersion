import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class RequestForgotPasswordOtp {
  RequestForgotPasswordOtp(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, void>> call({
    required String email,
  }) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      return const Left(ValidationFailure('Please enter your email'));
    }

    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(normalizedEmail)) {
      return const Left(
          ValidationFailure('Please enter a valid email address'));
    }

    return repository.requestForgotPasswordOtp(email: normalizedEmail);
  }
}
