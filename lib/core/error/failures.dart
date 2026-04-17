import 'package:equatable/equatable.dart';

import 'failure_kind.dart';

abstract class Failure extends Equatable {
  const Failure(
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
  List<Object?> get props => [
        message,
        kind,
        backendCode,
        statusCode,
        debugMessage,
        isRetryable,
      ];
}

class ServerFailure extends Failure {
  const ServerFailure([
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

class NetworkFailure extends Failure {
  const NetworkFailure([
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

class CacheFailure extends Failure {
  const CacheFailure([
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

class AuthenticationFailure extends Failure {
  const AuthenticationFailure([
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

class ForbiddenFailure extends Failure {
  const ForbiddenFailure([
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

class MqttConnectionFailure extends Failure {
  const MqttConnectionFailure([
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

class ValidationFailure extends Failure {
  const ValidationFailure([
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

class NotFoundFailure extends Failure {
  const NotFoundFailure([
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

class ConflictFailure extends Failure {
  const ConflictFailure([
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

class RateLimitFailure extends Failure {
  const RateLimitFailure([
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

class PermissionFailure extends Failure {
  const PermissionFailure([
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

class CancelledFailure extends Failure {
  const CancelledFailure([
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

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([
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
