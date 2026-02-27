import '../../domain/entities/user.dart';

/// Maps `ProfileResponse` từ backend (GET /api/auth/profile).
///
/// ```json
/// { "email": "...", "userId": "...", "firstName": "...", "lastName": "...",
///   "phoneNumber": null, "avatarPath": null, "roles": ["StoreManager"] }
/// ```
class ProfileResponseModel {
  final String email;
  final String userId;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final String? avatarPath;
  final List<String> roles;

  const ProfileResponseModel({
    required this.email,
    required this.userId,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
    this.avatarPath,
    required this.roles,
  });

  factory ProfileResponseModel.fromJson(Map<String, dynamic> json) {
    return ProfileResponseModel(
      email: json['email'] as String,
      userId: json['userId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      avatarPath: (json['avatarUrl'] ?? json['avatarPath']) as String?,
      roles: (json['roles'] as List<dynamic>).map((e) => _mapRole(e)).toList(),
    );
  }

  /// Backend trả role là integer:
  ///   0 → SystemAdmin, 1 → BrandManager, 2 → StoreManager
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

  /// Convert sang `User` entity để dùng trong domain layer.
  /// - `userId` → `id`
  /// - `firstName + lastName` → `fullName`
  /// - `roles[0]` → `role` (PascalCase, giữ nguyên để SessionCubit xử lý)
  /// - `roles` → `roles` (full list)
  User toUser() {
    return User(
      id: userId,
      username:
          email, // dùng email làm username vì backend không có field username riêng
      email: email,
      fullName: '$firstName $lastName'.trim(),
      firstName: firstName,
      lastName: lastName,
      phoneNumber: phoneNumber,
      role: roles.isNotEmpty ? roles.first : '',
      roles: roles,
      storeIds: const [],
      avatarUrl: avatarPath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'avatarPath': avatarPath,
      'roles': roles,
    };
  }
}
