import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final String role; // e.g., 'manager', 'staff'
  final List<String> storeIds; // List of stores this user manages
  final String? avatarUrl;
  final DateTime? lastLogin;

  const User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    required this.role,
    required this.storeIds,
    this.avatarUrl,
    this.lastLogin,
  });

  bool get isManager => role == 'manager';
  bool get isStaff => role == 'staff';

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        fullName,
        role,
        storeIds,
        avatarUrl,
        lastLogin,
      ];
}
