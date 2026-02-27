/// Defines Role-based access levels in the CAMS application.
///
/// - [brandManager]: Has full access across all stores and spaces.
/// - [storeManager]: Can manage a single assigned store and its spaces.
/// - [playbackDevice]: Read-only / playback mode — cannot edit devices or switch spaces.
enum UserRole {
  brandManager('Brand Manager', 'brand_manager'),
  storeManager('Store Manager', 'store_manager'),
  playbackDevice('Playback Device', 'playback_device');

  const UserRole(this.label, this.value);

  /// Human-readable display label (e.g. "Brand Manager").
  final String label;

  /// Machine-friendly value used in API / persistence (e.g. "brand_manager").
  final String value;

  /// Construct a [UserRole] from its [value] string.
  /// Throws [ArgumentError] if the value is not recognised.
  static UserRole fromValue(String value) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => throw ArgumentError('Unknown UserRole value: $value'),
    );
  }
}
