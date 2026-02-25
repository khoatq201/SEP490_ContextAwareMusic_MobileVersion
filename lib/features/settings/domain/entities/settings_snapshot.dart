import 'package:equatable/equatable.dart';

class SettingsSnapshot extends Equatable {
  final String companyName;
  final String businessType;
  final String planName;
  final bool explicitMusicAllowed;
  final bool blockingSongsAllowed;

  const SettingsSnapshot({
    required this.companyName,
    required this.businessType,
    required this.planName,
    required this.explicitMusicAllowed,
    required this.blockingSongsAllowed,
  });

  String get explicitMusicLabel => explicitMusicAllowed ? 'Allowed' : 'Blocked';
  String get blockingSongsLabel => blockingSongsAllowed ? 'Allowed' : 'Blocked';

  @override
  List<Object?> get props => [
        companyName,
        businessType,
        planName,
        explicitMusicAllowed,
        blockingSongsAllowed,
      ];
}
