import '../models/settings_snapshot_model.dart';

abstract class SettingsDataSource {
  Future<SettingsSnapshotModel> getSettingsSnapshot();
}

class SettingsMockDataSource implements SettingsDataSource {
  @override
  Future<SettingsSnapshotModel> getSettingsSnapshot() async {
    await Future.delayed(const Duration(milliseconds: 200));

    return const SettingsSnapshotModel(
      companyName: 'Coplyp',
      businessType: 'Restaurant',
      planName: 'Active subscription',
      subscriptionId: 'mock-subscription',
      tokenBalance: 1250,
      explicitMusicAllowed: true,
      blockingSongsAllowed: true,
    );
  }
}
