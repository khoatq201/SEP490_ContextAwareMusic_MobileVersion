import 'package:equatable/equatable.dart';
import '../../../../core/enums/override_mode_enum.dart';
import '../../../../core/enums/transition_type_enum.dart';

/// Response from POST /api/cams/spaces/{spaceId}/override.
class OverrideResponse extends Equatable {
  final String spaceId;
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

  /// Whether the HLS stream is ready (200) or pending transcode (202).
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
      spaceId: json['spaceId'] as String,
      playlistId: json['playlistId'] as String?,
      playlistName: json['playlistName'] as String?,
      hlsUrl: json['hlsUrl'] as String?,
      moodName: json['moodName'] as String?,
      overrideMode: OverrideModeEnum.fromJson(json['overrideMode']),
      isManualOverride: json['isManualOverride'] as bool? ?? true,
      startedAtUtc: json['startedAtUtc'] != null
          ? DateTime.tryParse(json['startedAtUtc'] as String)
          : null,
      expectedEndAtUtc: json['expectedEndAtUtc'] != null
          ? DateTime.tryParse(json['expectedEndAtUtc'] as String)
          : null,
      transitionType: TransitionTypeEnum.fromJson(json['transitionType']),
    );
  }

  /// Parse from API response wrapper.
  static OverrideResponseModel? fromApiResponse(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>?;
    if (data == null) return null;
    return OverrideResponseModel.fromJson(data);
  }
}
