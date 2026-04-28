import '../../domain/entities/schedule_slot.dart';

class ScheduleSlotModel extends ScheduleSlot {
  const ScheduleSlotModel({
    required super.id,
    required super.daysOfWeek,
    required super.startTime,
    required super.endTime,
    required super.musicId,
  });

  factory ScheduleSlotModel.fromJson(Map<String, dynamic> json) {
    final rawMusicId = json['musicId'] ?? json['playlistId'];
    return ScheduleSlotModel(
      id: json['id']?.toString() ?? '',
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>? ?? const [])
          .map((day) => int.tryParse(day.toString()))
          .whereType<int>()
          .map(_normalizeDayOfWeek)
          .whereType<int>()
          .toSet()
          .toList(),
      startTime: json['startTime']?.toString() ?? '00:00',
      endTime: json['endTime']?.toString() ?? '00:00',
      musicId: rawMusicId?.toString() ?? '',
    );
  }

  static int? _normalizeDayOfWeek(int day) {
    if (day >= 0 && day <= 6) return day;
    if (day == 7) return 0;
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'daysOfWeek': daysOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'musicId': musicId,
    };
  }
}
