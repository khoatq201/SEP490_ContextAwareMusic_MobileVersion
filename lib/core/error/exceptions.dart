import 'failure_kind.dart';

abstract class AppException implements Exception {
  const AppException(
    this.message, {
    required this.kind,
    this.backendCode,
    this.statusCode,
    this.debugMessage,
    required this.isRetryable,
  });

  final String message;
  final FailureKind kind;
  final String? backendCode;
  final int? statusCode;
  final String? debugMessage;
  final bool isRetryable;

  @override
  String toString() => message;
}

class ServerException extends AppException {
  const ServerException([
    super.message = 'Something went wrong on our side. Please try again.',
    FailureKind kind = FailureKind.server,
    String? backendCode,
    int? statusCode,
    String? debugMessage,
    bool isRetryable = true,
  ]) : super(
          kind: kind,
          backendCode: backendCode,
          statusCode: statusCode,
          debugMessage: debugMessage,
          isRetryable: isRetryable,
        );
}

class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Check your internet connection and try again.',
    FailureKind kind = FailureKind.network,
    String? backendCode,
    int? statusCode,
    String? debugMessage,
    bool isRetryable = true,
  ]) : super(
          kind: kind,
          backendCode: backendCode,
          statusCode: statusCode,
          debugMessage: debugMessage,
          isRetryable: isRetryable,
        );
}

class CacheException extends AppException {
  const CacheException([
    super.message = 'Stored data is unavailable right now.',
    String? backendCode,
    int? statusCode,
    String? debugMessage,
    bool isRetryable = true,
  ]) : super(
          kind: FailureKind.cache,
          backendCode: backendCode,
          statusCode: statusCode,
          debugMessage: debugMessage,
          isRetryable: isRetryable,
        );
}

class AuthenticationException extends AppException {
  const AuthenticationException([
    super.message = 'Your session has expired. Please sign in again.',
    String? backendCode,
    int? statusCode,
    String? debugMessage,
    bool isRetryable = false,
  ]) : super(
          kind: FailureKind.authentication,
          backendCode: backendCode,
          statusCode: statusCode,
          debugMessage: debugMessage,
          isRetryable: isRetryable,
        );
}

class ForbiddenException extends AppException {
  const ForbiddenException([
    super.message = 'You do not have permission to do that.',
    String? backendCode,
    int? statusCode,
    String? debugMessage,
    bool isRetryable = false,
  ]) : super(
          kind: FailureKind.forbidden,
          backendCode: backendCode,
          statusCode: statusCode,
          debugMessage: debugMessage,
          isRetryable: isRetryable,
        );
}

class ValidationException extends AppException {
  const ValidationException([
    super.message = 'Please review the information and try again.',
    FailureKind kind = FailureKind.validation,
    String? backendCode,
    int? statusCode,
    String? debugMessage,
    bool isRetryable = false,
  ]) : super(
          kind: kind,
          backendCode: backendCode,
          statusCode: statusCode,
          debugMessage: debugMessage,
          isRetryable: isRetryable,
        );
}

class NotFoundException extends AppException {
  const NotFoundException([
    super.message = 'We could not find what you were looking for.',
    String? backendCode,
    int? statusCode,
    String? debugMessage,
    bool isRetryable = false,
  ]) : super(
          kind: FailureKind.notFound,
          backendCode: backendCode,
          statusCode: statusCode,
          debugMessage: debugMessage,
          isRetryable: isRetryable,
        );
}

class ConflictException extends AppException {
  const ConflictException([
    super.message = 'This action conflicts with the current data.',
    FailureKind kind = FailureKind.conflict,
    String? backendCode,
    int? statusCode,
    String? debugMessage,
    bool isRetryable = false,
  ]) : super(
          kind: kind,
          backendCode: backendCode,
          statusCode: statusCode,
          debugMessage: debugMessage,
          isRetryable: isRetryable,
        );
}

class RateLimitException extends AppException {
  const RateLimitException([
    super.message = 'Too many requests. Please wait a moment and try again.',
    String? backendCode,
    int? statusCode,
    String? debugMessage,
    bool isRetryable = true,
  ]) : super(
          kind: FailureKind.rateLimited,
          backendCode: backendCode,
          statusCode: statusCode,
          debugMessage: debugMessage,
          isRetryable: isRetryable,
        );
}

class PermissionException extends AppException {
  const PermissionException([
    super.message = 'Permission is required to continue.',
    String? backendCode,
    int? statusCode,
    String? debugMessage,
    bool isRetryable = false,
  ]) : super(
          kind: FailureKind.permission,
          backendCode: backendCode,
          statusCode: statusCode,
          debugMessage: debugMessage,
          isRetryable: isRetryable,
        );
}

class CancelledException extends AppException {
  const CancelledException([
    super.message = 'This action was cancelled.',
    String? backendCode,
    int? statusCode,
    String? debugMessage,
    bool isRetryable = true,
  ]) : super(
          kind: FailureKind.cancelled,
          backendCode: backendCode,
          statusCode: statusCode,
          debugMessage: debugMessage,
          isRetryable: isRetryable,
        );
}

class UnexpectedException extends AppException {
  const UnexpectedException([
    super.message = 'Something unexpected happened. Please try again.',
    String? backendCode,
    int? statusCode,
    String? debugMessage,
    bool isRetryable = true,
  ]) : super(
          kind: FailureKind.unexpected,
          backendCode: backendCode,
          statusCode: statusCode,
          debugMessage: debugMessage,
          isRetryable: isRetryable,
        );
}

class MqttConnectionException extends AppException {
  const MqttConnectionException([
    super.message = 'Realtime connection is unavailable right now.',
    String? backendCode,
    int? statusCode,
    String? debugMessage,
    bool isRetryable = true,
  ]) : super(
          kind: FailureKind.mqtt,
          backendCode: backendCode,
          statusCode: statusCode,
          debugMessage: debugMessage,
          isRetryable: isRetryable,
        );
}
