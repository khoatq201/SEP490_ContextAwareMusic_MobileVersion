import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/settings_snapshot.dart';
import '../repositories/settings_repository.dart';

class GetSettingsSnapshot {
  final SettingsRepository repository;

  GetSettingsSnapshot(this.repository);

  Future<Either<Failure, SettingsSnapshot>> call() async {
    return await repository.getSettingsSnapshot();
  }
}
