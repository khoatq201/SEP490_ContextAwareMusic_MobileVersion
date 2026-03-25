import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/store_dashboard/data/datasources/store_remote_datasource.dart';

void main() {
  group('StoreMutationRequest', () {
    test('serializes only meaningful values', () {
      const request = StoreMutationRequest(
        name: '  Downtown Store ',
        contactNumber: ' 0909 999 999 ',
        address: ' 123 Main St ',
        city: 'HCM',
        district: '',
        latitude: 10.7769,
        longitude: 106.7009,
        mapUrl: ' ',
        timeZone: 'Asia/Ho_Chi_Minh',
        areaSquareMeters: 220.5,
        maxCapacity: 85,
        firestoreCollectionPath: 'stores/downtown',
      );

      expect(request.toJson(), {
        'name': 'Downtown Store',
        'contactNumber': '0909 999 999',
        'address': '123 Main St',
        'city': 'HCM',
        'latitude': 10.7769,
        'longitude': 106.7009,
        'timeZone': 'Asia/Ho_Chi_Minh',
        'areaSquareMeters': 220.5,
        'maxCapacity': 85,
        'firestoreCollectionPath': 'stores/downtown',
      });
    });
  });
}
