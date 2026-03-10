import '../../../../core/enums/entity_status_enum.dart';
import '../../domain/entities/store.dart';

class StoreModel {
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

  StoreModel({
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

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String,
      name: json['name'] as String,
      brandId: json['brandId'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
      contactNumber: json['contactNumber'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      mapUrl: json['mapUrl'] as String?,
      timeZone: json['timeZone'] as String?,
      areaSquareMeters: (json['areaSquareMeters'] as num?)?.toDouble(),
      maxCapacity: json['maxCapacity'] as int?,
      firestoreCollectionPath: json['firestoreCollectionPath'] as String?,
      currentMood: json['currentMood']?.toString(),
      lastMoodUpdateAt: json['lastMoodUpdateAt'] != null
          ? DateTime.parse(json['lastMoodUpdateAt'] as String)
          : null,
      status: EntityStatusEnum.fromJson(json['status']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      createdBy: json['createdBy'] as String?,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Store toEntity() {
    return Store(
      id: id,
      name: name,
      brandId: brandId,
      address: address,
      city: city,
      district: district,
      contactNumber: contactNumber,
      latitude: latitude,
      longitude: longitude,
      mapUrl: mapUrl,
      timeZone: timeZone,
      areaSquareMeters: areaSquareMeters,
      maxCapacity: maxCapacity,
      firestoreCollectionPath: firestoreCollectionPath,
      currentMood: currentMood,
      lastMoodUpdateAt: lastMoodUpdateAt,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
      updatedBy: updatedBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brandId': brandId,
      'address': address,
      'city': city,
      'district': district,
      'contactNumber': contactNumber,
      'latitude': latitude,
      'longitude': longitude,
      'mapUrl': mapUrl,
      'timeZone': timeZone,
      'areaSquareMeters': areaSquareMeters,
      'maxCapacity': maxCapacity,
      'firestoreCollectionPath': firestoreCollectionPath,
      'currentMood': currentMood,
      'lastMoodUpdateAt': lastMoodUpdateAt?.toIso8601String(),
      'status': status.value,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }
}
