import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/zone.dart';
import '../../domain/entities/speaker.dart';
import '../../domain/repositories/zone_repository.dart';
import '../datasources/zone_mock_datasource.dart';

class ZoneRepositoryImpl implements ZoneRepository {
  final ZoneMockDataSource mockDataSource;

  ZoneRepositoryImpl({required this.mockDataSource});

  @override
  Future<Either<Failure, List<Zone>>> getZonesBySpace(String spaceId) async {
    try {
      final zones = await mockDataSource.getZonesBySpace(spaceId);
      return Right(zones);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch zones: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Zone>> getZoneById(String zoneId) async {
    try {
      // For MVP, get all zones and filter
      // In production, this would be a dedicated API call
      final allZones = await mockDataSource.getZonesBySpace('space-1');
      final zone = allZones.firstWhere(
        (z) => z.id == zoneId,
        orElse: () => throw ServerException('Zone not found'),
      );
      return Right(zone);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch zone: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Zone>> createZone(Zone zone) async {
    try {
      // Mock implementation - in production would call API
      await Future.delayed(const Duration(milliseconds: 500));
      return Right(zone);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to create zone: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Zone>> updateZone(Zone zone) async {
    try {
      // Mock implementation - in production would call API
      await Future.delayed(const Duration(milliseconds: 500));
      return Right(zone);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to update zone: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteZone(String zoneId) async {
    try {
      // Mock implementation - in production would call API
      await Future.delayed(const Duration(milliseconds: 500));
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to delete zone: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Speaker>>> getSpeakersByZone(
      String zoneId) async {
    try {
      final speakers = await mockDataSource.getSpeakersByZone(zoneId);
      return Right(speakers);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to fetch speakers: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateSpeakerVolume({
    required String speakerId,
    required int volume,
  }) async {
    try {
      // Mock implementation - in production would call API/MQTT
      await Future.delayed(const Duration(milliseconds: 300));
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(
          ServerFailure('Failed to update speaker volume: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> syncZonesMusic(List<String> zoneIds) async {
    try {
      // Mock implementation - in production would call API/MQTT
      // This would instruct the server to sync music playback across zones
      await Future.delayed(const Duration(milliseconds: 500));
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to sync zones: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> unsyncZones(List<String> zoneIds) async {
    try {
      // Mock implementation - in production would call API/MQTT
      await Future.delayed(const Duration(milliseconds: 500));
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure('Failed to unsync zones: ${e.toString()}'));
    }
  }
}
