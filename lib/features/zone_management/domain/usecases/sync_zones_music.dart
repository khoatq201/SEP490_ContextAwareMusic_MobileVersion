import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../repositories/zone_repository.dart';

/// Use case to synchronize music playback across multiple zones
/// All zones in the list will play the same music simultaneously (Hybrid approach - Option C)
class SyncZonesMusic {
  final ZoneRepository repository;

  SyncZonesMusic(this.repository);

  Future<Either<Failure, void>> call(SyncZonesMusicParams params) async {
    if (params.unsync) {
      return await repository.unsyncZones(params.zoneIds);
    } else {
      return await repository.syncZonesMusic(params.zoneIds);
    }
  }
}

class SyncZonesMusicParams extends Equatable {
  final List<String> zoneIds;
  final bool unsync; // If true, unsync the zones; if false, sync them

  const SyncZonesMusicParams({
    required this.zoneIds,
    this.unsync = false,
  });

  @override
  List<Object?> get props => [zoneIds, unsync];
}
