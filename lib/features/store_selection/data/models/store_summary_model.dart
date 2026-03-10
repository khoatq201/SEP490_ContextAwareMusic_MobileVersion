import '../../../../core/enums/entity_status_enum.dart';
import '../../domain/entities/store_summary.dart';

class StoreSummaryModel extends StoreSummary {
  const StoreSummaryModel({
    required super.id,
    required super.brandId,
    required super.name,
    super.contactNumber,
    super.address,
    super.city,
    super.district,
    super.status,
    super.createdAt,
    super.updatedAt,
  });

  factory StoreSummaryModel.fromJson(Map<String, dynamic> json) {
    return StoreSummaryModel(
      id: json['id'] as String,
      brandId: json['brandId'] as String,
      name: json['name'] as String,
      contactNumber: json['contactNumber'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      district: json['district'] as String?,
      status: EntityStatusEnum.fromJson(json['status']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brandId': brandId,
      'name': name,
      'contactNumber': contactNumber,
      'address': address,
      'city': city,
      'district': district,
      'status': status.value,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
