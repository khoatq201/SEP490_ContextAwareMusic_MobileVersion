import 'package:equatable/equatable.dart';
import '../../../../core/enums/entity_status_enum.dart';

/// Represents a store item from the paginated store list (StoreListItem).
class StoreSummary extends Equatable {
  final String id;
  final String brandId;
  final String name;
  final String? contactNumber;
  final String? address;
  final String? city;
  final String? district;
  final EntityStatusEnum status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StoreSummary({
    required this.id,
    required this.brandId,
    required this.name,
    this.contactNumber,
    this.address,
    this.city,
    this.district,
    this.status = EntityStatusEnum.active,
    this.createdAt,
    this.updatedAt,
  });

  /// Combines address parts for display.
  String get fullAddress {
    final parts =
        [address, district, city].where((p) => p != null && p.isNotEmpty);
    return parts.join(', ');
  }

  @override
  List<Object?> get props => [
        id,
        brandId,
        name,
        contactNumber,
        address,
        city,
        district,
        status,
        createdAt,
        updatedAt,
      ];
}
