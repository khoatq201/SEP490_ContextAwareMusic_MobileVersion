import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.username,
    required super.email,
    super.fullName,
    required super.role,
    required super.storeIds,
    super.avatarUrl,
    super.lastLogin,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      role: json['role'] as String,
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
      'role': role,
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
      role: role,
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
      role: user.role,
      storeIds: user.storeIds,
      avatarUrl: user.avatarUrl,
      lastLogin: user.lastLogin,
    );
  }
}
