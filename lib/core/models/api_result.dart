/// Generic wrapper cho mọi API response từ backend.
///
/// Backend luôn bọc response trong:
/// - `Result<T>` (có data) – dùng `ApiResult<T>`
/// - `Result` (không data) – dùng `ApiResult<void>`
///
/// Parse với [ApiResult.fromJson], truyền vào [fromData] để parse phần `data`.
class ApiResult<T> {
  final bool isSuccess;
  final String? message;
  final T? data;
  final List<String>? errors;
  final String? errorCode;

  const ApiResult({
    required this.isSuccess,
    this.message,
    this.data,
    this.errors,
    this.errorCode,
  });

  factory ApiResult.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic)? fromData,
  }) {
    return ApiResult<T>(
      isSuccess: json['isSuccess'] as bool? ?? false,
      message: json['message'] as String?,
      data: (json['data'] != null && fromData != null)
          ? fromData(json['data'])
          : null,
      errors: (json['errors'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      errorCode: json['errorCode'] as String?,
    );
  }

  /// Lấy thông báo lỗi thân thiện cho người dùng.
  String get userFriendlyError {
    if (errors != null && errors!.isNotEmpty) return errors!.first;
    return message ?? 'Đã có lỗi xảy ra.';
  }
}
