import '../../../../core/enums/entity_status_enum.dart';
import '../../domain/entities/brand_detail.dart';

class BrandDetailModel extends BrandDetail {
  const BrandDetailModel({
    required super.id,
    required super.name,
    required super.status,
    super.createdAt,
    super.updatedAt,
    super.createdBy,
    super.updatedBy,
    super.logoUrl,
    super.industry,
    super.primaryContactName,
    super.contactEmail,
    super.contactPhone,
    super.primaryOwnerId,
    super.description,
    super.website,
    super.legalName,
    super.taxCode,
    super.billingAddress,
    super.technicalContactEmail,
    super.defaultTimeZone,
    super.currentSubscriptionId,
  });

  factory BrandDetailModel.fromJson(dynamic json) {
    final data = json as Map<String, dynamic>;
    return BrandDetailModel(
      id: data['id'] as String,
      name: data['name'] as String,
      status: EntityStatusEnum.fromJson(data['status']),
      createdAt: _tryParseDate(data['createdAt']),
      updatedAt: _tryParseDate(data['updatedAt']),
      createdBy: data['createdBy'] as String?,
      updatedBy: data['updatedBy'] as String?,
      logoUrl: data['logoUrl'] as String?,
      industry: data['industry'] as String?,
      primaryContactName: data['primaryContactName'] as String?,
      contactEmail: data['contactEmail'] as String?,
      contactPhone: data['contactPhone'] as String?,
      primaryOwnerId: data['primaryOwnerId'] as String?,
      description: data['description'] as String?,
      website: data['website'] as String?,
      legalName: data['legalName'] as String?,
      taxCode: data['taxCode'] as String?,
      billingAddress: data['billingAddress'] as String?,
      technicalContactEmail: data['technicalContactEmail'] as String?,
      defaultTimeZone: data['defaultTimeZone'] as String?,
      currentSubscriptionId: data['currentSubscriptionId'] as String?,
    );
  }

  static DateTime? _tryParseDate(dynamic value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
