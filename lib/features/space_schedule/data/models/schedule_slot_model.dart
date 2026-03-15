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
    return ScheduleSlotModel(
      id: json['id'] as String,
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>)
          .map((day) => day as int)
          .toList(),
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      musicId: json['musicId'] as String,
    );
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
