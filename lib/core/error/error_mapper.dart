import 'dart:io';

import 'package:dio/dio.dart';

import '../enums/error_code_enum.dart';
import '../models/api_result.dart';
import 'api_error_details.dart';
import 'exceptions.dart';
import 'failure_kind.dart';
import 'failures.dart';

class ErrorMapper {
  const ErrorMapper._();

  static AppException fromDioException(
    DioException error, {
    required String fallbackMessage,
  }) {
    final response = error.response;
    final details = ApiErrorDetails.fromPayload(
      response?.data,
      statusCode: response?.statusCode,
    );
    final debugMessage = _debugMessageForDio(error);

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return _buildException(
          kind: FailureKind.timeout,
          message: 'The request took too long. Please try again.',
          backendCode: details.backendCode,
          statusCode: response?.statusCode,
          debugMessage: debugMessage,
          isRetryable: true,
        );
      case DioExceptionType.cancel:
        return _buildException(
          kind: FailureKind.cancelled,
          message: 'This action was cancelled.',
          backendCode: details.backendCode,
          statusCode: response?.statusCode,
          debugMessage: debugMessage,
          isRetryable: true,
        );
      case DioExceptionType.connectionError:
        return _buildException(
          kind: FailureKind.network,
          message: 'Check your internet connection and try again.',
          backendCode: details.backendCode,
          statusCode: response?.statusCode,
          debugMessage: debugMessage,
          isRetryable: true,
        );
      case DioExceptionType.badCertificate:
        return _buildException(
          kind: FailureKind.serverUnavailable,
          message: 'A secure connection could not be established.',
          backendCode: details.backendCode,
          statusCode: response?.statusCode,
          debugMessage: debugMessage,
          isRetryable: true,
        );
      case DioExceptionType.badResponse:
        return fromApiErrorDetails(
          details,
          fallbackMessage: fallbackMessage,
          debugMessage: debugMessage,
        );
      case DioExceptionType.unknown:
        if (error.error is SocketException) {
          return _buildException(
            kind: FailureKind.network,
            message: 'Check your internet connection and try again.',
            backendCode: details.backendCode,
            statusCode: response?.statusCode,
            debugMessage: debugMessage,
            isRetryable: true,
          );
        }

        if (error.error is HandshakeException) {
          return _buildException(
            kind: FailureKind.serverUnavailable,
            message: 'A secure connection could not be established.',
            backendCode: details.backendCode,
            statusCode: response?.statusCode,
            debugMessage: debugMessage,
            isRetryable: true,
          );
        }

        return _buildException(
          kind: FailureKind.unexpected,
          message: fallbackMessage,
          backendCode: details.backendCode,
          statusCode: response?.statusCode,
          debugMessage: debugMessage,
          isRetryable: true,
        );
    }
  }

  static AppException fromApiErrorDetails(
    ApiErrorDetails details, {
    required String fallbackMessage,
    String? debugMessage,
  }) {
    final message = _resolveFriendlyMessage(details, fallbackMessage);
    final statusCode = details.statusCode;
    final backendCode = details.backendCode;
    final errorCode = details.errorCode;

    if (errorCode == ErrorCodeEnum.invalidCredentials) {
      return _buildException(
        kind: FailureKind.validation,
        message: message,
        backendCode: backendCode,
        statusCode: statusCode,
        debugMessage: debugMessage,
        isRetryable: false,
      );
    }

    if (errorCode == ErrorCodeEnum.unauthorized ||
        errorCode == ErrorCodeEnum.invalidToken ||
        errorCode == ErrorCodeEnum.tokenExpired ||
        statusCode == 401) {
      return _buildException(
        kind: FailureKind.authentication,
        message: message,
        backendCode: backendCode,
        statusCode: statusCode,
        debugMessage: debugMessage,
        isRetryable: false,
      );
    }

    if (statusCode == 403 ||
        errorCode == ErrorCodeEnum.forbidden ||
        errorCode == ErrorCodeEnum.insufficientPermissions) {
      return _buildException(
        kind: FailureKind.forbidden,
        message: message,
        backendCode: backendCode,
        statusCode: statusCode,
        debugMessage: debugMessage,
        isRetryable: false,
      );
    }

    if (statusCode == 404 || errorCode == ErrorCodeEnum.notFound) {
      return _buildException(
        kind: FailureKind.notFound,
        message: message,
        backendCode: backendCode,
        statusCode: statusCode,
        debugMessage: debugMessage,
        isRetryable: false,
      );
    }

    if (statusCode == 409 ||
        errorCode == ErrorCodeEnum.resourceConflict ||
        errorCode == ErrorCodeEnum.duplicateEntry) {
      return _buildException(
        kind: FailureKind.conflict,
        message: message,
        backendCode: backendCode,
        statusCode: statusCode,
        debugMessage: debugMessage,
        isRetryable: false,
      );
    }

    if (statusCode == 429 || errorCode == ErrorCodeEnum.tooManyRequests) {
      return _buildException(
        kind: FailureKind.rateLimited,
        message: message,
        backendCode: backendCode,
        statusCode: statusCode,
        debugMessage: debugMessage,
        isRetryable: true,
      );
    }

    if (errorCode == ErrorCodeEnum.invalidOperation ||
        errorCode == ErrorCodeEnum.businessRuleViolation) {
      return _buildException(
        kind: FailureKind.business,
        message: message,
        backendCode: backendCode,
        statusCode: statusCode,
        debugMessage: debugMessage,
        isRetryable: false,
      );
    }

    if (statusCode == 422 ||
        errorCode == ErrorCodeEnum.validationFailed ||
        errorCode == ErrorCodeEnum.invalidInput) {
      return _buildException(
        kind: FailureKind.validation,
        message: message,
        backendCode: backendCode,
        statusCode: statusCode,
        debugMessage: debugMessage,
        isRetryable: false,
      );
    }

    if (statusCode != null && statusCode >= 500) {
      return _buildException(
        kind: statusCode == 503
            ? FailureKind.serverUnavailable
            : FailureKind.server,
        message: message,
        backendCode: backendCode,
        statusCode: statusCode,
        debugMessage: debugMessage,
        isRetryable: true,
      );
    }

    return _buildException(
      kind: FailureKind.server,
      message: message,
      backendCode: backendCode,
      statusCode: statusCode,
      debugMessage: debugMessage,
      isRetryable: true,
    );
  }

  static AppException fromApiResponsePayload(
    dynamic payload, {
    required String fallbackMessage,
    int? statusCode,
    String? debugMessage,
  }) {
    final details =
        ApiErrorDetails.fromPayload(payload, statusCode: statusCode);
    return fromApiErrorDetails(
      details,
      fallbackMessage: fallbackMessage,
      debugMessage: debugMessage,
    );
  }

  static Failure toFailure(
    Object error, {
    String? fallbackMessage,
    StackTrace? stackTrace,
  }) {
    if (error is Failure) {
      return error;
    }

    final exception = toException(
      error,
      fallbackMessage: fallbackMessage,
      stackTrace: stackTrace,
    );

    return _buildFailure(
      kind: exception.kind,
      message: exception.message,
      backendCode: exception.backendCode,
      statusCode: exception.statusCode,
      debugMessage: exception.debugMessage,
      isRetryable: exception.isRetryable,
    );
  }

  static AppException toException(
    Object error, {
    String? fallbackMessage,
    StackTrace? stackTrace,
  }) {
    if (error is AppException) {
      return _normalizeAppException(error);
    }

    if (error is Failure) {
      return _buildException(
        kind: error.kind,
        message: error.message,
        backendCode: error.backendCode,
        statusCode: error.statusCode,
        debugMessage: error.debugMessage,
        isRetryable: error.isRetryable,
      );
    }

    if (error is DioException) {
      return fromDioException(
        error,
        fallbackMessage: fallbackMessage ??
            'Something unexpected happened. Please try again.',
      );
    }

    if (error is SocketException) {
      return _buildException(
        kind: FailureKind.network,
        message: 'Check your internet connection and try again.',
        debugMessage: error.toString(),
        isRetryable: true,
      );
    }

    if (error is HandshakeException) {
      return _buildException(
        kind: FailureKind.serverUnavailable,
        message: 'A secure connection could not be established.',
        debugMessage: error.toString(),
        isRetryable: true,
      );
    }

    return _buildException(
      kind: FailureKind.unexpected,
      message:
          fallbackMessage ?? 'Something unexpected happened. Please try again.',
      debugMessage: _composeUnexpectedDebug(error, stackTrace),
      isRetryable: true,
    );
  }

  static Failure fromApiResultFailure<T>(
    ApiResult<T> result, {
    int? statusCode,
    String? fallbackMessage,
  }) {
    final exception = fromApiResponsePayload(
      {
        'message': result.message,
        'errors': result.errors,
        'errorCode': result.errorCode,
      },
      fallbackMessage:
          fallbackMessage ?? 'Something unexpected happened. Please try again.',
      statusCode: statusCode,
    );
    return toFailure(exception);
  }

  static String displayMessageForFailure(
    Failure failure, {
    String? overrideMessage,
  }) {
    return sanitizeMessageForDisplay(
      overrideMessage ?? failure.message,
      kind: failure.kind,
    );
  }

  static String sanitizeMessageForDisplay(
    String? message, {
    FailureKind kind = FailureKind.unexpected,
  }) {
    final candidate = message?.trim();
    if (candidate == null || candidate.isEmpty) {
      return defaultMessageForFailure(kind);
    }

    if (_looksTechnical(candidate)) {
      return defaultMessageForFailure(kind);
    }

    return candidate;
  }

  static String defaultMessageForFailure(FailureKind kind) {
    switch (kind) {
      case FailureKind.network:
        return 'Check your internet connection and try again.';
      case FailureKind.timeout:
        return 'The request took too long. Please try again.';
      case FailureKind.authentication:
        return 'Your session has expired. Please sign in again.';
      case FailureKind.forbidden:
        return 'You do not have permission to do that.';
      case FailureKind.validation:
        return 'Please review the information and try again.';
      case FailureKind.business:
        return 'This action is not allowed right now.';
      case FailureKind.notFound:
        return 'We could not find what you were looking for.';
      case FailureKind.conflict:
        return 'This action conflicts with the current data.';
      case FailureKind.rateLimited:
        return 'Too many requests. Please wait a moment and try again.';
      case FailureKind.serverUnavailable:
        return 'The service is temporarily unavailable. Please try again.';
      case FailureKind.server:
        return 'Something went wrong on our side. Please try again.';
      case FailureKind.cache:
        return 'Stored data is unavailable right now.';
      case FailureKind.realtime:
        return 'Realtime connection is unavailable right now.';
      case FailureKind.permission:
        return 'Permission is required to continue.';
      case FailureKind.cancelled:
        return 'This action was cancelled.';
      case FailureKind.unexpected:
        return 'Something unexpected happened. Please try again.';
    }
  }

  static String _resolveFriendlyMessage(
    ApiErrorDetails details,
    String fallbackMessage,
  ) {
    final candidate = details.primaryMessage;
    if (candidate == null || candidate.isEmpty) {
      return fallbackMessage;
    }

    if (_looksTechnical(candidate)) {
      return fallbackMessage;
    }

    return candidate;
  }

  static bool _looksTechnical(String value) {
    final normalized = value.toLowerCase();
    return normalized.contains('dioexception') ||
        normalized.contains('socketexception') ||
        normalized.contains('handshakeexception') ||
        normalized.contains('platformexception') ||
        normalized.contains('missingpluginexception') ||
        normalized.contains('xmlhttprequest') ||
        normalized.contains('http status error') ||
        normalized.contains('exception:') ||
        (normalized.startsWith('failed to ') && normalized.contains(':')) ||
        normalized.contains('type \'nul\'') ||
        normalized.contains('null is not a subtype') ||
        normalized.contains('stack trace');
  }

  static String _debugMessageForDio(DioException error) {
    final response = error.response;
    return [
      'type=${error.type.name}',
      'message=${error.message}',
      if (response != null) 'status=${response.statusCode}',
      if (response?.data != null) 'payload=${response!.data}',
    ].join(' | ');
  }

  static String _composeUnexpectedDebug(
    Object error,
    StackTrace? stackTrace,
  ) {
    if (stackTrace == null) {
      return error.toString();
    }

    return '$error\n$stackTrace';
  }

  static AppException _normalizeAppException(AppException exception) {
    final message = exception.message.trim();
    if (message.isNotEmpty && !_looksTechnical(message)) {
      return exception;
    }

    final resolvedMessage = defaultMessageForFailure(exception.kind);
    final normalizedDebugMessage = [
      if (exception.debugMessage != null && exception.debugMessage!.isNotEmpty)
        exception.debugMessage,
      if (message.isNotEmpty) 'message=$message',
    ].join(' | ');

    return _buildException(
      kind: exception.kind,
      message: resolvedMessage,
      backendCode: exception.backendCode,
      statusCode: exception.statusCode,
      debugMessage:
          normalizedDebugMessage.isEmpty ? null : normalizedDebugMessage,
      isRetryable: exception.isRetryable,
    );
  }

  static AppException _buildException({
    required FailureKind kind,
    String? message,
    String? backendCode,
    int? statusCode,
    String? debugMessage,
    bool? isRetryable,
  }) {
    final resolvedMessage = message ?? defaultMessageForFailure(kind);
    final retryable = isRetryable ?? _isRetryable(kind);

    switch (kind) {
      case FailureKind.network:
      case FailureKind.timeout:
        return NetworkException(
          resolvedMessage,
          kind,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.authentication:
        return AuthenticationException(
          resolvedMessage,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.forbidden:
        return ForbiddenException(
          resolvedMessage,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.validation:
      case FailureKind.business:
        return ValidationException(
          resolvedMessage,
          kind,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.notFound:
        return NotFoundException(
          resolvedMessage,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.conflict:
        return ConflictException(
          resolvedMessage,
          kind,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.rateLimited:
        return RateLimitException(
          resolvedMessage,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.serverUnavailable:
      case FailureKind.server:
        return ServerException(
          resolvedMessage,
          kind,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.cache:
        return CacheException(
          resolvedMessage,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.realtime:
        return RealtimeConnectionException(
          resolvedMessage,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.permission:
        return PermissionException(
          resolvedMessage,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.cancelled:
        return CancelledException(
          resolvedMessage,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.unexpected:
        return UnexpectedException(
          resolvedMessage,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
    }
  }

  static Failure _buildFailure({
    required FailureKind kind,
    String? message,
    String? backendCode,
    int? statusCode,
    String? debugMessage,
    bool? isRetryable,
  }) {
    final resolvedMessage = message ?? defaultMessageForFailure(kind);
    final retryable = isRetryable ?? _isRetryable(kind);

    switch (kind) {
      case FailureKind.network:
      case FailureKind.timeout:
        return NetworkFailure(
          resolvedMessage,
          kind,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.authentication:
        return AuthenticationFailure(
          resolvedMessage,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.forbidden:
        return ForbiddenFailure(
          resolvedMessage,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.validation:
      case FailureKind.business:
        return ValidationFailure(
          resolvedMessage,
          kind,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.notFound:
        return NotFoundFailure(
          resolvedMessage,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.conflict:
        return ConflictFailure(
          resolvedMessage,
          kind,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.rateLimited:
        return RateLimitFailure(
          resolvedMessage,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.serverUnavailable:
      case FailureKind.server:
        return ServerFailure(
          resolvedMessage,
          kind,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.cache:
        return CacheFailure(
          resolvedMessage,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.realtime:
        return RealtimeConnectionFailure(
          resolvedMessage,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.permission:
        return PermissionFailure(
          resolvedMessage,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.cancelled:
        return CancelledFailure(
          resolvedMessage,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
      case FailureKind.unexpected:
        return UnexpectedFailure(
          resolvedMessage,
          backendCode,
          statusCode,
          debugMessage,
          retryable,
        );
    }
  }

  static bool _isRetryable(FailureKind kind) {
    switch (kind) {
      case FailureKind.authentication:
      case FailureKind.forbidden:
      case FailureKind.validation:
      case FailureKind.business:
      case FailureKind.notFound:
      case FailureKind.conflict:
      case FailureKind.permission:
        return false;
      case FailureKind.network:
      case FailureKind.timeout:
      case FailureKind.rateLimited:
      case FailureKind.serverUnavailable:
      case FailureKind.server:
      case FailureKind.cache:
      case FailureKind.realtime:
      case FailureKind.cancelled:
      case FailureKind.unexpected:
        return true;
    }
  }
}
