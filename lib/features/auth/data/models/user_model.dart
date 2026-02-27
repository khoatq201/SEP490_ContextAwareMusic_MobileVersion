import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.email,
    super.fullName,
    super.firstName,
    super.lastName,
    super.phoneNumber,
    required super.role,
    super.roles = const [],
    required super.storeIds,
    super.avatarUrl,
    super.lastLogin,
  });

  /// Backend trả role là integer:
  ///   0 → SystemAdmin, 1 → BrandManager, 2 → StoreManager
  /// Nếu backend trả string thì giữ nguyên.
  static String _mapRole(dynamic raw) {
    if (raw is int) {
      switch (raw) {
        case 0:
          return 'SystemAdmin';
        case 1:
          return 'BrandManager';
        case 2:
          return 'StoreManager';
        default:
          return 'Unknown';
      }
    }
    return raw.toString();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rolesList =
        (json['roles'] as List<dynamic>?)?.map((e) => _mapRole(e)).toList() ??
            [];
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      role: json['role'] is int
          ? _mapRole(json['role'])
          : (json['role'] as String? ??
              (rolesList.isNotEmpty ? rolesList.first : '')),
      roles: rolesList,
      storeIds: (json['storeIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      avatarUrl: json['avatarUrl'] as String?,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'role': role,
      'roles': roles,
      'storeIds': storeIds,
      'avatarUrl': avatarUrl,
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  User toEntity() {
    return User(
      id: id,
      username: username,
      email: email,
      fullName: fullName,
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      role: role,
      roles: roles,
      storeIds: storeIds,
      avatarUrl: avatarUrl,
      lastLogin: lastLogin,
    );
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      username: user.username,
      email: user.email,
      fullName: user.fullName,
      firstName: user.firstName,
      lastName: user.lastName,
      phoneNumber: user.phoneNumber,
      role: user.role,
      roles: user.roles,
      storeIds: user.storeIds,
      avatarUrl: user.avatarUrl,
      lastLogin: user.lastLogin,
    );
  }
}
