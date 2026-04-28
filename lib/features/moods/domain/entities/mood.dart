import 'package:equatable/equatable.dart';
import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/enums/mood_type_enum.dart';

/// Mood entity matching backend MoodListItem DTO.
class Mood extends Equatable {
  final String id;
  final MoodTypeEnum? moodType;
  final String name;
  final int? minBpm;
  final int? maxBpm;
  final String? genre;
  final double? energyLevel;
  final int? priority;
  final EntityStatusEnum status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Mood({
    required this.id,
    this.moodType,
    required this.name,
    this.minBpm,
    this.maxBpm,
    this.genre,
    this.energyLevel,
    this.priority,
    this.status = EntityStatusEnum.active,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        moodType,
        name,
        minBpm,
        maxBpm,
        genre,
        energyLevel,
        priority,
        status,
        createdAt,
        updatedAt,
      ];
}
