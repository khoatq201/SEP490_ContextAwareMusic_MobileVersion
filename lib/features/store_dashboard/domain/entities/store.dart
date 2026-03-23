import 'package:equatable/equatable.dart';
import '../../../../core/enums/entity_status_enum.dart';

/// Domain entity matching backend StoreDetailResponse.
class Store extends Equatable {
  final String id;
  final String name;
  final String brandId;
  final String? address;
  final String? city;
  final String? district;
  final String? contactNumber;
  final double? latitude;
  final double? longitude;
  final String? mapUrl;
  final String? timeZone;
  final double? areaSquareMeters;
  final int? maxCapacity;
  final String? firestoreCollectionPath;
  final String? currentMood;
  final DateTime? lastMoodUpdateAt;
  final EntityStatusEnum status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;

  const Store({
    required this.id,
    required this.name,
    required this.brandId,
    this.address,
    this.city,
    this.district,
    this.contactNumber,
    this.latitude,
    this.longitude,
    this.mapUrl,
    this.timeZone,
    this.areaSquareMeters,
    this.maxCapacity,
    this.firestoreCollectionPath,
    this.currentMood,
    this.lastMoodUpdateAt,
    this.status = EntityStatusEnum.active,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  /// Combines address parts for display.
  String get fullAddress {
    final parts =
        [address, district, city].where((p) => p != null && p.isNotEmpty);
    return parts.join(', ');
  }

  bool get isActive => status.isActive;

  @override
  List<Object?> get props => [
        id,
        name,
        brandId,
        address,
        city,
        district,
        contactNumber,
        latitude,
        longitude,
        mapUrl,
        timeZone,
        areaSquareMeters,
        maxCapacity,
        firestoreCollectionPath,
        currentMood,
        lastMoodUpdateAt,
        status,
        createdAt,
        updatedAt,
        createdBy,
        updatedBy,
      ];
}
