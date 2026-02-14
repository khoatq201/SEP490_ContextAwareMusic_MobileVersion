import 'package:equatable/equatable.dart';

class Store extends Equatable {
  final String id;
  final String name;
  final String brandId;
  final String address;
  final String? phone;
  final String? email;
  final int totalSpaces;
  final int activeSpaces;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Store({
    required this.id,
    required this.name,
    required this.brandId,
    required this.address,
    this.phone,
    this.email,
    required this.totalSpaces,
    required this.activeSpaces,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        brandId,
        address,
        phone,
        email,
        totalSpaces,
        activeSpaces,
        isActive,
        createdAt,
        updatedAt,
      ];
}
