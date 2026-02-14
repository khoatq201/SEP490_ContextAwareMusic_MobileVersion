import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class RequestPasswordReset {
  final AuthRepository repository;

  RequestPasswordReset(this.repository);

  Future<Either<Failure, String>> call(String email) async {
    return await repository.requestPasswordReset(email);
  }
}
