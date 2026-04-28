import 'package:equatable/equatable.dart';

class ScheduleSlot extends Equatable {
  final String id;
  final List<int> daysOfWeek;
  final String startTime;
  final String endTime;
  final String musicId;

  const ScheduleSlot({
    required this.id,
    required this.daysOfWeek,
    required this.startTime,
    required this.endTime,
    required this.musicId,
  });

  ScheduleSlot copyWith({
    String? id,
    List<int>? daysOfWeek,
    String? startTime,
    String? endTime,
    String? musicId,
  }) {
    return ScheduleSlot(
      id: id ?? this.id,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      musicId: musicId ?? this.musicId,
    );
  }

  @override
  List<Object?> get props => [id, daysOfWeek, startTime, endTime, musicId];
}
