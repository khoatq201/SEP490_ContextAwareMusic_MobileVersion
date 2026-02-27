import '../../../../core/models/api_result.dart';

/// Maps `AuthResponse` từ backend (Login & RefreshToken).
///
/// ```json
/// { "accessToken": "...", "expiresAt": "2025-02-21T10:00:00Z", "roles": ["StoreManager"] }
/// ```
class AuthResponseModel {
  final String accessToken;
  final DateTime expiresAt;
  final List<String> roles;

  const AuthResponseModel({
    required this.accessToken,
    required this.expiresAt,
    required this.roles,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      accessToken: json['accessToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      roles: (json['roles'] as List<dynamic>)
          .map((e) => _mapRole(e))
          .toList(),
    );
  }

  /// Backend trả role là integer:
  ///   0 → SystemAdmin, 1 → BrandManager, 2 → StoreManager
  /// Nếu backend trả string thì giữ nguyên.
  static String _mapRole(dynamic raw) {
    if (raw is int) {
      switch (raw) {
        case 0: return 'SystemAdmin';
        case 1: return 'BrandManager';
        case 2: return 'StoreManager';
        default: return 'Unknown';
      }
    }
    // Trường hợp backend trả string (tương lai hoặc môi trường khác)
    return raw.toString();
  }

  /// Parse từ `ApiResult<AuthResponse>` wrapper.
  static AuthResponseModel? fromApiResult(ApiResult<AuthResponseModel> result) {
    return result.data;
  }
}
