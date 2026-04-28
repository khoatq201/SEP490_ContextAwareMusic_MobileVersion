import '../../../../core/error/exceptions.dart';
import '../../../../core/services/local_storage_service.dart';
import '../models/schedule_source_model.dart';
import '../models/space_schedule_model.dart';

class SpaceScheduleLocalDataSource {
  static const String _draftPrefix = 'space_schedule_draft_';
  static const String _libraryKey = 'space_schedule_library_items';

  final LocalStorageService localStorage;

  SpaceScheduleLocalDataSource({required this.localStorage});

  SpaceScheduleModel? getDraftSchedule(String spaceId) {
    try {
      final json = localStorage.getSetting('$_draftPrefix$spaceId');
      if (json is Map) {
        return SpaceScheduleModel.fromJson(Map<String, dynamic>.from(json));
      }
      return null;
    } catch (error) {
      throw CacheException('Failed to load schedule draft: $error');
    }
  }

  Future<void> saveDraftSchedule(SpaceScheduleModel schedule) async {
    try {
      await localStorage.saveSetting(
        '$_draftPrefix${schedule.spaceId}',
        schedule.toJson(),
      );
    } catch (error) {
      throw CacheException('Failed to save schedule draft: $error');
    }
  }

  List<ScheduleSourceModel> getLibrarySources() {
    try {
      final json = localStorage.getSetting(_libraryKey);
      if (json is List) {
        return json
            .map((item) => ScheduleSourceModel.fromJson(
                Map<String, dynamic>.from(item as Map)))
            .toList();
      }
      return const [];
    } catch (error) {
      throw CacheException('Failed to load saved schedules: $error');
    }
  }

  Future<void> saveLibrarySources(List<ScheduleSourceModel> sources) async {
    try {
      await localStorage.saveSetting(
        _libraryKey,
        sources.map((source) => source.toJson()).toList(),
      );
    } catch (error) {
      throw CacheException('Failed to save schedule library: $error');
    }
  }
}
