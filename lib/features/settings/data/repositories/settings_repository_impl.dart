import 'package:dartz/dartz.dart';

import '../../../../core/error/error_mapper.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/settings_snapshot.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_mock_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsDataSource dataSource;

  SettingsRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, SettingsSnapshot>> getSettingsSnapshot() async {
    try {
      final snapshot = await dataSource.getSettingsSnapshot();
      return Right(snapshot);
    } catch (error) {
      return Left(
        ErrorMapper.toFailure(
          error,
          fallbackMessage: 'Unable to load settings right now.',
        ),
      );
    }
  }
}
