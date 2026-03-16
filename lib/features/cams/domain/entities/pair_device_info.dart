import 'package:equatable/equatable.dart';

class PairDeviceInfo extends Equatable {
  final String spaceId;
  final String storeId;
  final String brandId;
  final String? deviceSessionId;
  final bool isPlaybackDeviceCaller;
  final String? manufacturer;
  final String? model;
  final String? osVersion;
  final String? appVersion;
  final String? deviceId;
  final DateTime? pairedAtUtc;
  final DateTime? lastActiveAtUtc;

  const PairDeviceInfo({
    required this.spaceId,
    required this.storeId,
    required this.brandId,
    this.deviceSessionId,
    this.isPlaybackDeviceCaller = false,
    this.manufacturer,
    this.model,
    this.osVersion,
    this.appVersion,
    this.deviceId,
    this.pairedAtUtc,
    this.lastActiveAtUtc,
  });

  bool get isPaired => deviceSessionId != null && deviceSessionId!.isNotEmpty;

  String? get deviceDisplayName {
    final parts = [
      if (manufacturer != null && manufacturer!.trim().isNotEmpty)
        manufacturer!.trim(),
      if (model != null && model!.trim().isNotEmpty) model!.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  String get managerStatusLabel => deviceDisplayName ?? 'Da paired';

  @override
  List<Object?> get props => [
        spaceId,
        storeId,
        brandId,
        deviceSessionId,
        isPlaybackDeviceCaller,
        manufacturer,
        model,
        osVersion,
        appVersion,
        deviceId,
        pairedAtUtc,
        lastActiveAtUtc,
      ];
}
