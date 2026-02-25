import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/settings_snapshot.dart';

abstract class SettingsRepository {
  Future<Either<Failure, SettingsSnapshot>> getSettingsSnapshot();
}
