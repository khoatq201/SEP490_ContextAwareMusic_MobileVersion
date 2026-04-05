import 'package:equatable/equatable.dart';

enum HubDeviceLocationSource {
  phoneGps,
  manual,
}

extension HubDeviceLocationSourceX on HubDeviceLocationSource {
  String get apiValue {
    switch (this) {
      case HubDeviceLocationSource.phoneGps:
        return 'phoneGps';
      case HubDeviceLocationSource.manual:
        return 'manual';
    }
  }

  String get displayLabel {
    switch (this) {
      case HubDeviceLocationSource.phoneGps:
        return 'Phone GPS';
      case HubDeviceLocationSource.manual:
        return 'Manual';
    }
  }

  static HubDeviceLocationSource fromApiValue(String? raw) {
    switch (raw) {
      case 'manual':
        return HubDeviceLocationSource.manual;
      case 'phoneGps':
      default:
        return HubDeviceLocationSource.phoneGps;
    }
  }
}

class HubDeviceLocation extends Equatable {
  const HubDeviceLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.source,
    required this.capturedAtUtc,
  });

  final double latitude;
  final double longitude;
  final String city;
  final HubDeviceLocationSource source;
  final DateTime capturedAtUtc;

  HubDeviceLocation copyWith({
    double? latitude,
    double? longitude,
    String? city,
    HubDeviceLocationSource? source,
    DateTime? capturedAtUtc,
  }) {
    return HubDeviceLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      source: source ?? this.source,
      capturedAtUtc: capturedAtUtc ?? this.capturedAtUtc,
    );
  }

  String get displayCity => city.trim().isEmpty ? 'Unknown' : city.trim();

  String get displayCoordinates =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';

  Map<String, dynamic> toJson() {
    return {
      'lat': latitude,
      'lon': longitude,
      'city': city,
      'source': source.apiValue,
      'capturedAtUtc': capturedAtUtc.toUtc().toIso8601String(),
    };
  }

  factory HubDeviceLocation.fromJson(Map<String, dynamic> json) {
    return HubDeviceLocation(
      latitude: (json['lat'] as num?)?.toDouble() ??
          (json['latitude'] as num?)?.toDouble() ??
          0,
      longitude: (json['lon'] as num?)?.toDouble() ??
          (json['longitude'] as num?)?.toDouble() ??
          0,
      city: json['city']?.toString() ?? '',
      source: HubDeviceLocationSourceX.fromApiValue(
        json['source']?.toString(),
      ),
      capturedAtUtc: DateTime.tryParse(
            json['capturedAtUtc']?.toString() ?? '',
          )?.toUtc() ??
          DateTime.now().toUtc(),
    );
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        city,
        source,
        capturedAtUtc,
      ];
}
