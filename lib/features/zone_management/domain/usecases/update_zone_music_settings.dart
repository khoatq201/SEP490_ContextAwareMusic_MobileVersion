import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../entities/music_profile.dart';
import '../repositories/music_profile_repository.dart';

/// Use case to update music settings for a zone
class UpdateZoneMusicSettings {
  final MusicProfileRepository repository;

  UpdateZoneMusicSettings(this.repository);

  Future<Either<Failure, void>> call(UpdateMusicSettingsParams params) async {
    if (params.volumeSettings != null) {
      final result = await repository.updateVolumeSettings(
        zoneId: params.zoneId,
        volumeSettings: params.volumeSettings!,
      );
      if (result.isLeft()) return result;
    }

    if (params.scheduleConfig != null) {
      final result = await repository.updateScheduleConfig(
        zoneId: params.zoneId,
        scheduleConfig: params.scheduleConfig,
      );
      if (result.isLeft()) return result;
    }

    if (params.autoMoodDetection != null) {
      final result = await repository.toggleAutoMoodDetection(
        zoneId: params.zoneId,
        enabled: params.autoMoodDetection!,
      );
      if (result.isLeft()) return result;
    }

    return const Right(null);
  }
}

class UpdateMusicSettingsParams extends Equatable {
  final String zoneId;
  final VolumeSettings? volumeSettings;
  final ScheduleConfig? scheduleConfig;
  final bool? autoMoodDetection;

  const UpdateMusicSettingsParams({
    required this.zoneId,
    this.volumeSettings,
    this.scheduleConfig,
    this.autoMoodDetection,
  });

  @override
  List<Object?> get props =>
      [zoneId, volumeSettings, scheduleConfig, autoMoodDetection];
}
