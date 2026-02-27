import '../../domain/entities/settings_snapshot.dart';

class SettingsSnapshotModel extends SettingsSnapshot {
  const SettingsSnapshotModel({
    required super.companyName,
    required super.businessType,
    required super.planName,
    required super.explicitMusicAllowed,
    required super.blockingSongsAllowed,
  });

  factory SettingsSnapshotModel.fromJson(Map<String, dynamic> json) {
    return SettingsSnapshotModel(
      companyName: json['companyName'] as String,
      businessType: json['businessType'] as String,
      planName: json['planName'] as String,
      explicitMusicAllowed: json['explicitMusicAllowed'] as bool,
      blockingSongsAllowed: json['blockingSongsAllowed'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'businessType': businessType,
      'planName': planName,
      'explicitMusicAllowed': explicitMusicAllowed,
      'blockingSongsAllowed': blockingSongsAllowed,
    };
  }
}
