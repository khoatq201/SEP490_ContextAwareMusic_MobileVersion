import 'package:equatable/equatable.dart';

import '../../../../core/enums/entity_status_enum.dart';

class BrandDetail extends Equatable {
  const BrandDetail({
    required this.id,
    required this.name,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.logoUrl,
    this.industry,
    this.primaryContactName,
    this.contactEmail,
    this.contactPhone,
    this.primaryOwnerId,
    this.description,
    this.website,
    this.legalName,
    this.taxCode,
    this.billingAddress,
    this.technicalContactEmail,
    this.defaultTimeZone,
    this.currentSubscriptionId,
  });

  final String id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final EntityStatusEnum status;
  final String name;
  final String? logoUrl;
  final String? industry;
  final String? primaryContactName;
  final String? contactEmail;
  final String? contactPhone;
  final String? primaryOwnerId;
  final String? description;
  final String? website;
  final String? legalName;
  final String? taxCode;
  final String? billingAddress;
  final String? technicalContactEmail;
  final String? defaultTimeZone;
  final String? currentSubscriptionId;

  @override
  List<Object?> get props => [
        id,
        createdAt,
        updatedAt,
        createdBy,
        updatedBy,
        status,
        name,
        logoUrl,
        industry,
        primaryContactName,
        contactEmail,
        contactPhone,
        primaryOwnerId,
        description,
        website,
        legalName,
        taxCode,
        billingAddress,
        technicalContactEmail,
        defaultTimeZone,
        currentSubscriptionId,
      ];
}
