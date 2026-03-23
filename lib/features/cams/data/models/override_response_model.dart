import 'package:equatable/equatable.dart';

import '../../../../core/enums/override_mode_enum.dart';
import '../../../../core/enums/transition_type_enum.dart';

/// Response from POST /api/cams/spaces/{spaceId}/override.
///
/// New contract is ACK-first (`data` may be only `spaceId` string).
/// Legacy fields are still parsed for transition compatibility.
class OverrideResponse extends Equatable {
  final String spaceId;

  /// Legacy fields kept for parser compatibility.
  final String? playlistId;
  final String? playlistName;
  final String? hlsUrl;
  final String? moodName;
  final OverrideModeEnum? overrideMode;
  final bool isManualOverride;
  final DateTime? startedAtUtc;
  final DateTime? expectedEndAtUtc;
  final TransitionTypeEnum? transitionType;

  const OverrideResponse({
    required this.spaceId,
    this.playlistId,
    this.playlistName,
    this.hlsUrl,
    this.moodName,
    this.overrideMode,
    this.isManualOverride = true,
    this.startedAtUtc,
    this.expectedEndAtUtc,
    this.transitionType,
  });

  bool get isAckOnly =>
      playlistId == null &&
      playlistName == null &&
      hlsUrl == null &&
      moodName == null &&
      overrideMode == null &&
      startedAtUtc == null &&
      expectedEndAtUtc == null &&
      transitionType == null;

  /// Legacy helper used by some existing UI flows.
  bool get isStreamReady =>
      hlsUrl != null &&
      hlsUrl!.isNotEmpty &&
      transitionType != TransitionTypeEnum.pending;

  @override
  List<Object?> get props => [
        spaceId,
        playlistId,
        playlistName,
        hlsUrl,
        moodName,
        overrideMode,
        isManualOverride,
        startedAtUtc,
        expectedEndAtUtc,
        transitionType,
      ];
}

class OverrideResponseModel extends OverrideResponse {
  const OverrideResponseModel({
    required super.spaceId,
    super.playlistId,
    super.playlistName,
    super.hlsUrl,
    super.moodName,
    super.overrideMode,
    super.isManualOverride,
    super.startedAtUtc,
    super.expectedEndAtUtc,
    super.transitionType,
  });

  factory OverrideResponseModel.fromJson(Map<String, dynamic> json) {
    return OverrideResponseModel(
      spaceId: _readString(json, 'spaceId') ?? '',
      playlistId: _readString(json, 'playlistId'),
      playlistName: _readString(json, 'playlistName'),
      hlsUrl: _readString(json, 'hlsUrl'),
      moodName: _readString(json, 'moodName'),
      overrideMode: OverrideModeEnum.fromJson(_readValue(json, 'overrideMode')),
      isManualOverride: _readBool(json, 'isManualOverride') ?? true,
      startedAtUtc: _readDateTime(json, 'startedAtUtc'),
      expectedEndAtUtc: _readDateTime(json, 'expectedEndAtUtc'),
      transitionType:
          TransitionTypeEnum.fromJson(_readValue(json, 'transitionType')),
    );
  }

  /// Parse from API response wrapper.
  /// Supported payload shapes:
  /// 1) { data: { spaceId: "..." } } (new ACK-first contract)
  /// 2) { data: "uuid-space-id" }      (some handlers)
  /// 3) { data: { ...legacy fields... } }
  static OverrideResponseModel? fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is String) {
      return OverrideResponseModel(spaceId: data);
    }
    if (data is Map) {
      return OverrideResponseModel.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
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

  static bool? _readBool(Map<String, dynamic> json, String key) {
    final value = _readValue(json, key);
    if (value is bool) return value;
    if (value is String) {
      if (value.toLowerCase() == 'true') return true;
      if (value.toLowerCase() == 'false') return false;
    }
    return null;
  }

  static DateTime? _readDateTime(Map<String, dynamic> json, String key) {
    final value = _readValue(json, key);
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
