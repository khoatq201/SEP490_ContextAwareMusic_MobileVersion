import '../../domain/entities/space_queue_state_item.dart';

class SpaceQueueStateItemModel extends SpaceQueueStateItem {
  const SpaceQueueStateItemModel({
    required super.queueItemId,
    required super.trackId,
    super.trackName,
    required super.position,
    required super.queueStatus,
    required super.source,
    super.hlsUrl,
    super.isReadyToStream,
  });

  factory SpaceQueueStateItemModel.fromJson(Map<String, dynamic> json) {
    return SpaceQueueStateItemModel(
      queueItemId: _readString(json, 'queueItemId') ?? '',
      trackId: _readString(json, 'trackId') ?? '',
      trackName: _readString(json, 'trackName'),
      position: _readNum(json, 'position')?.toInt() ?? 0,
      queueStatus: _readNum(json, 'queueStatus')?.toInt() ?? 0,
      source: _readNum(json, 'source')?.toInt() ?? 0,
      hlsUrl: _readString(json, 'hlsUrl'),
      isReadyToStream: _readBool(json, 'isReadyToStream') ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'queueItemId': queueItemId,
      'trackId': trackId,
      'trackName': trackName,
      'position': position,
      'queueStatus': queueStatus,
      'source': source,
      'hlsUrl': hlsUrl,
      'isReadyToStream': isReadyToStream,
    };
  }

  static List<SpaceQueueStateItemModel> listFromDynamic(dynamic raw) {
    if (raw is! List) return const <SpaceQueueStateItemModel>[];

    return raw
        .whereType<Map>()
        .map((item) => SpaceQueueStateItemModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  static dynamic _readValue(Map<String, dynamic> json, String key) {
    if (json.containsKey(key)) return json[key];
    if (key.isEmpty) return null;
    final pascalCaseKey = '${key[0].toUpperCase()}${key.substring(1)}';
    return json[pascalCaseKey];
  }

  static String? _readString(Map<String, dynamic> json, String key) {
    final value = _readValue(json, key);
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  static num? _readNum(Map<String, dynamic> json, String key) {
    final value = _readValue(json, key);
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  static bool? _readBool(Map<String, dynamic> json, String key) {
    final value = _readValue(json, key);
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return null;
  }
}
