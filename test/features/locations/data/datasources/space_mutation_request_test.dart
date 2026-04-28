import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/features/locations/data/datasources/location_remote_datasource.dart';

void main() {
  group('SpaceMutationRequest', () {
    test('serializes only non-empty optional fields', () {
      const request = SpaceMutationRequest(
        storeId: 'store-1',
        name: '  Hall A  ',
        type: 2,
        description: 'Main hall',
        cameraId: '   ',
        roiCoordinates: 'x1,y1,x2,y2',
        maxOccupancy: 120,
        criticalQueueThreshold: 15,
        wiFiSensorId: '',
      );

      expect(request.toJson(), {
        'storeId': 'store-1',
        'name': 'Hall A',
        'type': 2,
        'description': 'Main hall',
        'roiCoordinates': 'x1,y1,x2,y2',
        'maxOccupancy': 120,
        'criticalQueueThreshold': 15,
      });
    });
  });
}
