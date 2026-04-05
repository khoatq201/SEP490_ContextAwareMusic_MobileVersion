import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'package:cams_store_manager/features/hub_management/data/services/location_capture_service.dart';
import 'package:cams_store_manager/features/hub_management/domain/entities/hub_device_location.dart';

void main() {
  group('GeolocatorLocationCaptureService', () {
    test('captures GPS location and reverse geocodes the city', () async {
      final service = GeolocatorLocationCaptureService(
        isLocationServiceEnabled: () async => true,
        checkPermission: () async => LocationPermission.whileInUse,
        requestPermission: () async => LocationPermission.whileInUse,
        getCurrentPosition: () async => _position(
          latitude: 10.7769,
          longitude: 106.7009,
        ),
        placemarkFromCoordinatesFn: (_, __) async => const [
          Placemark(locality: 'Ho Chi Minh City'),
        ],
      );

      final location = await service.captureCurrentLocation();

      expect(location.city, 'Ho Chi Minh City');
      expect(location.latitude, 10.7769);
      expect(location.longitude, 106.7009);
      expect(location.source, HubDeviceLocationSource.phoneGps);
    });

    test('throws when location permission is denied', () async {
      final service = GeolocatorLocationCaptureService(
        isLocationServiceEnabled: () async => true,
        checkPermission: () async => LocationPermission.denied,
        requestPermission: () async => LocationPermission.denied,
        getCurrentPosition: () async => _position(),
      );

      await expectLater(
        service.captureCurrentLocation(),
        throwsA(
          isA<LocationCaptureException>().having(
            (error) => error.message,
            'message',
            contains('enter the location manually'),
          ),
        ),
      );
    });

    test('throws when location services are disabled', () async {
      final service = GeolocatorLocationCaptureService(
        isLocationServiceEnabled: () async => false,
        checkPermission: () async => LocationPermission.whileInUse,
        requestPermission: () async => LocationPermission.whileInUse,
        getCurrentPosition: () async => _position(),
      );

      await expectLater(
        service.captureCurrentLocation(),
        throwsA(
          isA<LocationCaptureException>().having(
            (error) => error.message,
            'message',
            contains('Location services are turned off'),
          ),
        ),
      );
    });

    test('falls back to Unknown city when reverse geocode fails', () async {
      final service = GeolocatorLocationCaptureService(
        isLocationServiceEnabled: () async => true,
        checkPermission: () async => LocationPermission.whileInUse,
        requestPermission: () async => LocationPermission.whileInUse,
        getCurrentPosition: () async => _position(
          latitude: 16.0471,
          longitude: 108.2062,
        ),
        placemarkFromCoordinatesFn: (_, __) async {
          throw Exception('geocoder unavailable');
        },
      );

      final location = await service.captureCurrentLocation();

      expect(location.city, 'Unknown');
      expect(location.source, HubDeviceLocationSource.phoneGps);
    });
  });
}

Position _position({
  double latitude = 10.7769,
  double longitude = 106.7009,
}) {
  return Position(
    longitude: longitude,
    latitude: latitude,
    timestamp: DateTime.parse('2026-04-04T10:05:00.000Z'),
    accuracy: 1,
    altitude: 2,
    altitudeAccuracy: 1,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 0,
  );
}
