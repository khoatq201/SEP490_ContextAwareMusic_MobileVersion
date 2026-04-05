import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../../domain/entities/hub_device_location.dart';

abstract class LocationCaptureService {
  Future<HubDeviceLocation> captureCurrentLocation();

  Future<String> reverseGeocode({
    required double latitude,
    required double longitude,
  });
}

class GeolocatorLocationCaptureService implements LocationCaptureService {
  GeolocatorLocationCaptureService({
    Future<bool> Function()? isLocationServiceEnabled,
    Future<LocationPermission> Function()? checkPermission,
    Future<LocationPermission> Function()? requestPermission,
    Future<Position> Function()? getCurrentPosition,
    Future<List<Placemark>> Function(double latitude, double longitude)?
        placemarkFromCoordinatesFn,
  })  : _isLocationServiceEnabled =
            isLocationServiceEnabled ?? Geolocator.isLocationServiceEnabled,
        _checkPermission = checkPermission ?? Geolocator.checkPermission,
        _requestPermission = requestPermission ?? Geolocator.requestPermission,
        _getCurrentPosition = getCurrentPosition ??
            (() => Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                )),
        _placemarkFromCoordinatesFn =
            placemarkFromCoordinatesFn ?? placemarkFromCoordinates;

  final Future<bool> Function() _isLocationServiceEnabled;
  final Future<LocationPermission> Function() _checkPermission;
  final Future<LocationPermission> Function() _requestPermission;
  final Future<Position> Function() _getCurrentPosition;
  final Future<List<Placemark>> Function(double latitude, double longitude)
      _placemarkFromCoordinatesFn;

  @override
  Future<HubDeviceLocation> captureCurrentLocation() async {
    final isEnabled = await _isLocationServiceEnabled();
    if (!isEnabled) {
      throw const LocationCaptureException(
        'Location services are turned off. You can still enter the location manually.',
      );
    }

    var permission = await _checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationCaptureException(
        'Location permission was denied. You can still enter the location manually.',
      );
    }

    final position = await _getCurrentPosition();
    String city;
    try {
      city = await reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      city = 'Unknown';
    }

    return HubDeviceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      city: city,
      source: HubDeviceLocationSource.phoneGps,
      capturedAtUtc: DateTime.now().toUtc(),
    );
  }

  @override
  Future<String> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final placemarks = await _placemarkFromCoordinatesFn(latitude, longitude);
    if (placemarks.isEmpty) {
      return 'Unknown';
    }

    final primary = placemarks.first;
    final value = [
      primary.locality,
      primary.subAdministrativeArea,
      primary.administrativeArea,
    ].firstWhere(
      (item) => item != null && item.trim().isNotEmpty,
      orElse: () => 'Unknown',
    );
    return value ?? 'Unknown';
  }
}

class LocationCaptureException implements Exception {
  const LocationCaptureException(this.message);

  final String message;

  @override
  String toString() => message;
}
