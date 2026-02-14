import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/zone.dart';
import '../entities/speaker.dart';

/// Repository interface for zone management operations
abstract class ZoneRepository {
  /// Get all zones for a specific space
  Future<Either<Failure, List<Zone>>> getZonesBySpace(String spaceId);

  /// Get a single zone by its ID
  Future<Either<Failure, Zone>> getZoneById(String zoneId);

  /// Create a new zone
  Future<Either<Failure, Zone>> createZone(Zone zone);

  /// Update an existing zone
  Future<Either<Failure, Zone>> updateZone(Zone zone);

  /// Delete a zone
  Future<Either<Failure, void>> deleteZone(String zoneId);

  /// Get all speakers for a zone
  Future<Either<Failure, List<Speaker>>> getSpeakersByZone(String zoneId);

  /// Update speaker volume
  Future<Either<Failure, void>> updateSpeakerVolume({
    required String speakerId,
    required int volume,
  });

  /// Sync music playback across multiple zones
  /// All zones in the list will play the same music simultaneously
  Future<Either<Failure, void>> syncZonesMusic(List<String> zoneIds);

  /// Unsync zones - each zone plays independently
  Future<Either<Failure, void>> unsyncZones(List<String> zoneIds);
}
