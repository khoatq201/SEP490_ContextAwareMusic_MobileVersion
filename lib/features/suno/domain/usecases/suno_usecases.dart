import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/datasources/suno_remote_datasource.dart';
import '../../data/repositories/suno_repository_impl.dart';
import '../entities/suno_config.dart';
import '../entities/suno_generation.dart';

class CreateSunoGeneration {
  final SunoRepository repository;

  CreateSunoGeneration(this.repository);

  Future<Either<Failure, String>> call(CreateSunoGenerationRequest request) {
    return repository.createGeneration(request);
  }
}

class GetSunoGeneration {
  final SunoRepository repository;

  GetSunoGeneration(this.repository);

  Future<Either<Failure, SunoGeneration>> call(String id) {
    return repository.getGeneration(id);
  }
}

class CancelSunoGeneration {
  final SunoRepository repository;

  CancelSunoGeneration(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.cancelGeneration(id);
  }
}

class GetSunoConfig {
  final SunoRepository repository;

  GetSunoConfig(this.repository);

  Future<Either<Failure, SunoConfig>> call() {
    return repository.getConfig();
  }
}

class UpdateSunoConfig {
  final SunoRepository repository;

  UpdateSunoConfig(this.repository);

  Future<Either<Failure, SunoConfig>> call(UpdateSunoConfigRequest request) {
    return repository.updateConfig(request);
  }
}
