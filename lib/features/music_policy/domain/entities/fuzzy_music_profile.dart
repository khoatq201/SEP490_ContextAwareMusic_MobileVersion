import 'package:equatable/equatable.dart';

class FuzzyMusicProfile extends Equatable {
  final String id;
  final String brandId;
  final String? storeId;
  final String name;
  final String? templateKey;
  final int chillBpmMin;
  final int chillBpmMax;
  final int focusBpmMin;
  final int focusBpmMax;
  final int energeticBpmMin;
  final int energeticBpmMax;
  final double noiseQuietMaxDb;
  final double noiseLoudMinDb;
  final double defaultDecibelWhenNull;
  final bool autoVolumeEnabled;
  final int autoVolumeQuietPercent;
  final int autoVolumeModeratePercent;
  final int autoVolumeLoudPercent;
  final int autoVolumeMinPercent;
  final int autoVolumeMaxPercent;
  final int autoVolumeDeadbandPercent;

  const FuzzyMusicProfile({
    required this.id,
    required this.brandId,
    this.storeId,
    required this.name,
    this.templateKey,
    required this.chillBpmMin,
    required this.chillBpmMax,
    required this.focusBpmMin,
    required this.focusBpmMax,
    required this.energeticBpmMin,
    required this.energeticBpmMax,
    required this.noiseQuietMaxDb,
    required this.noiseLoudMinDb,
    required this.defaultDecibelWhenNull,
    required this.autoVolumeEnabled,
    required this.autoVolumeQuietPercent,
    required this.autoVolumeModeratePercent,
    required this.autoVolumeLoudPercent,
    required this.autoVolumeMinPercent,
    required this.autoVolumeMaxPercent,
    required this.autoVolumeDeadbandPercent,
  });

  FuzzyMusicProfile copyWith({
    bool? autoVolumeEnabled,
  }) {
    return FuzzyMusicProfile(
      id: id,
      brandId: brandId,
      storeId: storeId,
      name: name,
      templateKey: templateKey,
      chillBpmMin: chillBpmMin,
      chillBpmMax: chillBpmMax,
      focusBpmMin: focusBpmMin,
      focusBpmMax: focusBpmMax,
      energeticBpmMin: energeticBpmMin,
      energeticBpmMax: energeticBpmMax,
      noiseQuietMaxDb: noiseQuietMaxDb,
      noiseLoudMinDb: noiseLoudMinDb,
      defaultDecibelWhenNull: defaultDecibelWhenNull,
      autoVolumeEnabled: autoVolumeEnabled ?? this.autoVolumeEnabled,
      autoVolumeQuietPercent: autoVolumeQuietPercent,
      autoVolumeModeratePercent: autoVolumeModeratePercent,
      autoVolumeLoudPercent: autoVolumeLoudPercent,
      autoVolumeMinPercent: autoVolumeMinPercent,
      autoVolumeMaxPercent: autoVolumeMaxPercent,
      autoVolumeDeadbandPercent: autoVolumeDeadbandPercent,
    );
  }

  String get autoVolumeRangeLabel =>
      '$autoVolumeMinPercent-$autoVolumeMaxPercent%';

  String get autoVolumeStepsLabel =>
      '$autoVolumeQuietPercent/$autoVolumeModeratePercent/$autoVolumeLoudPercent%';

  @override
  List<Object?> get props => [
        id,
        brandId,
        storeId,
        name,
        templateKey,
        chillBpmMin,
        chillBpmMax,
        focusBpmMin,
        focusBpmMax,
        energeticBpmMin,
        energeticBpmMax,
        noiseQuietMaxDb,
        noiseLoudMinDb,
        defaultDecibelWhenNull,
        autoVolumeEnabled,
        autoVolumeQuietPercent,
        autoVolumeModeratePercent,
        autoVolumeLoudPercent,
        autoVolumeMinPercent,
        autoVolumeMaxPercent,
        autoVolumeDeadbandPercent,
      ];
}
