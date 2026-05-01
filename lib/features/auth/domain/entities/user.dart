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
  final String? brandId;
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
    this.brandId,
    this.avatarUrl,
    this.lastLogin,
  });

  Iterable<String> get _roleCandidates sync* {
    if (roles.isNotEmpty) {
      yield* roles;
    }
    if (role.trim().isNotEmpty) {
      yield role;
    }
  }

  String _normalizeRole(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return '';

    return normalized
        .replaceAll(RegExp(r'^role[_\s-]*'), '')
        .replaceAll(RegExp(r'[\s_-]+'), '');
  }

  bool _matchesRole(String roleName) {
    final target = _normalizeRole(roleName);
    if (target.isEmpty) return false;

    for (final candidate in _roleCandidates) {
      if (_normalizeRole(candidate) == target) {
        return true;
      }
    }
    return false;
  }

  /// Check if user has a specific role, regardless of source formatting.
  bool hasRole(String roleName) => _matchesRole(roleName);

  bool get isSystemAdmin => _matchesRole('SystemAdmin');
  bool get isBrandManager => _matchesRole('BrandManager');
  bool get isStoreManager => _matchesRole('StoreManager');

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
        brandId,
        avatarUrl,
        lastLogin,
      ];
}
