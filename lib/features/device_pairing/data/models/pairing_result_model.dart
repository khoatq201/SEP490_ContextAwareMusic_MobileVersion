import '../../domain/entities/pairing_result.dart';

/// Data model for the pairing API response.
class PairingResultModel extends PairingResult {
  const PairingResultModel({
    required super.deviceId,
    required super.storeId,
    required super.spaceId,
    required super.storeName,
    required super.spaceName,
  });

  factory PairingResultModel.fromJson(Map<String, dynamic> json) {
    return PairingResultModel(
      deviceId: json['deviceId'] as String? ?? 'device-mock-id',
      storeId: json['storeId'] as String? ?? 'store-mock-id',
      spaceId: json['spaceId'] as String? ?? 'space-mock-id',
      storeName: json['storeName'] as String? ?? 'Unknown Store',
      spaceName: json['spaceName'] as String? ?? 'Unknown Space',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'storeId': storeId,
      'spaceId': spaceId,
      'storeName': storeName,
      'spaceName': spaceName,
    };
  }
}
