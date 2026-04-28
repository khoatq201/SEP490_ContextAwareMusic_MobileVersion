import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class ChangePassword {
  final AuthRepository repository;

  ChangePassword(this.repository);

  Future<Either<Failure, void>> call({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // Client-side validation
    if (newPassword != confirmPassword) {
      return const Left(ValidationFailure('Passwords do not match'));
    }
    if (newPassword.length < 6) {
      return const Left(
          ValidationFailure('Password must be at least 6 characters'));
    }

    return await repository.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }
}
