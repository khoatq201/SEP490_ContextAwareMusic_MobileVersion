import '../../../../core/models/api_result.dart';

/// Maps `AuthResponse` from backend (Login & RefreshToken).
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
      roles: (json['roles'] as List<dynamic>).map((e) => _mapRole(e)).toList(),
    );
  }

  /// Backend returns role as integer:
  ///   0 → SystemAdmin, 1 → BrandManager, 2 → StoreManager
  /// If backend returns string, keep as-is.
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
    // Case when backend returns string (future or other environments)
    return raw.toString();
  }

  /// Parse from `ApiResult<AuthResponse>` wrapper.
  static AuthResponseModel? fromApiResult(ApiResult<AuthResponseModel> result) {
    return result.data;
  }
}
