import '../../domain/entities/mood.dart';
import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/enums/mood_type_enum.dart';

class MoodModel extends Mood {
  const MoodModel({
    required super.id,
    super.moodType,
    required super.name,
    super.minBpm,
    super.maxBpm,
    super.genre,
    super.energyLevel,
    super.priority,
    super.status,
    required super.createdAt,
    super.updatedAt,
  });

  factory MoodModel.fromJson(Map<String, dynamic> json) {
    return MoodModel(
      id: json['id'] as String,
      moodType: MoodTypeEnum.fromJson(json['moodType']),
      name: json['name'] as String? ?? '',
      minBpm: json['minBpm'] as int?,
      maxBpm: json['maxBpm'] as int?,
      genre: json['genre'] as String?,
      energyLevel: (json['energyLevel'] as num?)?.toDouble(),
      priority: json['priority'] as int?,
      status: EntityStatusEnum.fromJson(json['status'] ?? 1),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'moodType': moodType?.value,
      'name': name,
      'minBpm': minBpm,
      'maxBpm': maxBpm,
      'genre': genre,
      'energyLevel': energyLevel,
      'priority': priority,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Parse the API response: { "isSuccess": true, "data": [...] }
  static List<MoodModel> fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => MoodModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
