import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String
      role; // Primary role (PascalCase from backend, e.g. "StoreManager")
  final List<String> roles; // All roles from backend
  final List<String> storeIds; // List of stores this user manages
  final String? avatarUrl;
  final DateTime? lastLogin;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    required this.role,
    this.roles = const [],
    required this.storeIds,
    this.avatarUrl,
    this.lastLogin,
  });

  /// Check if user has a specific role (PascalCase matching).
  bool hasRole(String roleName) => roles.contains(roleName);

  bool get isSystemAdmin => roles.contains('SystemAdmin');
  bool get isBrandManager => roles.contains('BrandManager');
  bool get isStoreManager => roles.contains('StoreManager');

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        fullName,
        firstName,
        lastName,
        phoneNumber,
        role,
        roles,
        storeIds,
        avatarUrl,
        lastLogin,
      ];
}
