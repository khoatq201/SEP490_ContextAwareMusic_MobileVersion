import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/music_profile.dart';
import '../repositories/music_profile_repository.dart';

/// Use case to get music profile configuration for a zone
class GetMusicProfileForZone {
  final MusicProfileRepository repository;

  GetMusicProfileForZone(this.repository);

  Future<Either<Failure, MusicProfile>> call(String zoneId) async {
    return await repository.getProfileByZone(zoneId);
  }
}
