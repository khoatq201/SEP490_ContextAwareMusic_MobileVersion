import '../enums/error_code_enum.dart';

class ApiErrorDetails {
  const ApiErrorDetails({
    this.message,
    this.errors = const [],
    this.backendCode,
    this.statusCode,
  });

  final String? message;
  final List<String> errors;
  final String? backendCode;
  final int? statusCode;

  ErrorCodeEnum get errorCode => ErrorCodeEnum.fromString(backendCode);

  String? get primaryMessage {
    for (final error in errors) {
      final normalized = error.trim();
      if (normalized.isNotEmpty) {
        return normalized;
      }
    }

    final normalizedMessage = message?.trim();
    if (normalizedMessage != null && normalizedMessage.isNotEmpty) {
      return normalizedMessage;
    }
    return null;
  }

  factory ApiErrorDetails.fromPayload(
    dynamic payload, {
    int? statusCode,
  }) {
    if (payload is Map) {
      final json = Map<String, dynamic>.from(payload);
      return ApiErrorDetails(
        message: json['message']?.toString(),
        errors: _collectErrors(json['errors']),
        backendCode: json['errorCode']?.toString(),
        statusCode: statusCode,
      );
    }

    if (payload is List) {
      return ApiErrorDetails(
        errors: _collectErrors(payload),
        statusCode: statusCode,
      );
    }

    final raw = payload?.toString().trim();
    return ApiErrorDetails(
      message: raw == null || raw.isEmpty ? null : raw,
      statusCode: statusCode,
    );
  }

  static List<String> _collectErrors(dynamic rawErrors) {
    if (rawErrors == null) {
      return const [];
    }

    if (rawErrors is List) {
      final collected = <String>[];
      for (final item in rawErrors) {
        final nested = _collectErrors(item);
        if (nested.isNotEmpty) {
          collected.addAll(nested);
          continue;
        }

        final value = item?.toString().trim();
        if (value != null && value.isNotEmpty) {
          collected.add(value);
        }
      }
      return collected;
    }

    if (rawErrors is Map) {
      final collected = <String>[];
      final map = Map<String, dynamic>.from(rawErrors);
      for (final value in map.values) {
        collected.addAll(_collectErrors(value));
      }
      return collected;
    }

    final value = rawErrors.toString().trim();
    return value.isEmpty ? const [] : <String>[value];
  }
}
