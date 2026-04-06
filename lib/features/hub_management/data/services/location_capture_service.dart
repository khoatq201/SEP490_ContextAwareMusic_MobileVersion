import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

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
    Future<PermissionStatus> Function()? checkSystemPermission,
    Future<PermissionStatus> Function()? requestSystemPermission,
    Future<bool> Function()? isLocationServiceEnabled,
    Future<LocationPermission> Function()? checkPermission,
    Future<LocationPermission> Function()? requestPermission,
    Future<Position> Function()? getCurrentPosition,
    Future<List<Placemark>> Function(double latitude, double longitude)?
        placemarkFromCoordinatesFn,
  })  : _checkSystemPermission =
            checkSystemPermission ?? (() => Permission.location.status),
        _requestSystemPermission =
            requestSystemPermission ?? (() => Permission.location.request()),
        _isLocationServiceEnabled =
            isLocationServiceEnabled ?? Geolocator.isLocationServiceEnabled,
        _checkPermission = checkPermission ?? Geolocator.checkPermission,
        _requestPermission = requestPermission ?? Geolocator.requestPermission,
        _getCurrentPosition = getCurrentPosition ??
            (() => Geolocator.getCurrentPosition(
                  desiredAccuracy: LocationAccuracy.high,
                )),
        _placemarkFromCoordinatesFn =
            placemarkFromCoordinatesFn ?? placemarkFromCoordinates;

  final Future<PermissionStatus> Function() _checkSystemPermission;
  final Future<PermissionStatus> Function() _requestSystemPermission;
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

    var systemPermission = await _checkSystemPermission();
    if (!systemPermission.isGranted && !systemPermission.isLimited) {
      systemPermission = await _requestSystemPermission();
    }

    if (systemPermission.isPermanentlyDenied) {
      throw const LocationCaptureException(
        'Location permission is permanently denied. Open app settings to allow location access.',
      );
    }

    if (!systemPermission.isGranted && !systemPermission.isLimited) {
      throw const LocationCaptureException(
        'Location permission was denied. Try again, or open app settings if Android no longer shows the location prompt.',
      );
    }

    var permission = await _checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await _requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const LocationCaptureException(
        'Location permission was denied. Try again, or open app settings if Android no longer shows the location prompt.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationCaptureException(
        'Location permission is permanently denied. Open app settings to allow location access.',
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
    final parts = [
      primary.subLocality,
      primary.locality,
      primary.subAdministrativeArea,
      primary.administrativeArea,
    ]
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'Unknown';
    }

    final uniqueParts = <String>[];
    for (final part in parts) {
      if (!uniqueParts.contains(part)) {
        uniqueParts.add(part);
      }
    }
    return uniqueParts.take(3).join(', ');
  }
}

class LocationCaptureException implements Exception {
  const LocationCaptureException(this.message);

  final String message;

  @override
  String toString() => message;
}
