import '../../domain/entities/store.dart';

class StoreModel {
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

  StoreModel({
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

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    return StoreModel(
      id: json['id'] as String,
      name: json['name'] as String,
      brandId: json['brandId'] as String,
      address: json['address'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      totalSpaces: json['totalSpaces'] as int? ?? 0,
      activeSpaces: json['activeSpaces'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Store toEntity() {
    return Store(
      id: id,
      name: name,
      brandId: brandId,
      address: address,
      phone: phone,
      email: email,
      totalSpaces: totalSpaces,
      activeSpaces: activeSpaces,
      isActive: isActive,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'brandId': brandId,
      'address': address,
      'phone': phone,
      'email': email,
      'totalSpaces': totalSpaces,
      'activeSpaces': activeSpaces,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
