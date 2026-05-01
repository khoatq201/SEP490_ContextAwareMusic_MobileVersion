import '../../domain/entities/settings_snapshot.dart';

class SettingsSnapshotModel extends SettingsSnapshot {
  const SettingsSnapshotModel({
    required super.companyName,
    required super.businessType,
    required super.planName,
    super.subscriptionId,
    super.tokenBalance,
    super.walletLocked,
    required super.explicitMusicAllowed,
    required super.blockingSongsAllowed,
  });

  factory SettingsSnapshotModel.fromJson(Map<String, dynamic> json) {
    return SettingsSnapshotModel(
      companyName: json['companyName'] as String,
      businessType: json['businessType'] as String,
      planName: json['planName'] as String,
      subscriptionId: json['subscriptionId'] as String?,
      tokenBalance: (json['tokenBalance'] as num?)?.round(),
      walletLocked: json['walletLocked'] as bool? ?? false,
      explicitMusicAllowed: json['explicitMusicAllowed'] as bool,
      blockingSongsAllowed: json['blockingSongsAllowed'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'businessType': businessType,
      'planName': planName,
      'subscriptionId': subscriptionId,
      'tokenBalance': tokenBalance,
      'walletLocked': walletLocked,
      'explicitMusicAllowed': explicitMusicAllowed,
      'blockingSongsAllowed': blockingSongsAllowed,
    };
  }
}
