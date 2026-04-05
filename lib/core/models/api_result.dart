import '../enums/error_code_enum.dart';
import '../error/api_error_details.dart';

/// Generic wrapper for all API responses from the backend.
///
/// The backend always wraps responses in:
/// - `Result<T>` (with data) – use `ApiResult<T>`
/// - `Result` (no data) – use `ApiResult<void>`
///
/// Parse with [ApiResult.fromJson], passing [fromData] to parse the `data` field.
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
      errors:
          (json['errors'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      errorCode: json['errorCode'] as String?,
    );
  }

  ErrorCodeEnum get parsedErrorCode => ErrorCodeEnum.fromString(errorCode);

  ApiErrorDetails get errorDetails => ApiErrorDetails(
        message: message,
        errors: errors ?? const [],
        backendCode: errorCode,
      );

  String? get primaryError => errorDetails.primaryMessage;

  /// Returns a user-friendly error message.
  String get userFriendlyError {
    return primaryError ?? 'Something unexpected happened. Please try again.';
  }
}
