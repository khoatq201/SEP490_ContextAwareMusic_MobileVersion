import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cams_store_manager/core/enums/error_code_enum.dart';
import 'package:cams_store_manager/core/error/error_mapper.dart';
import 'package:cams_store_manager/core/error/exceptions.dart';
import 'package:cams_store_manager/core/error/failure_kind.dart';
import 'package:cams_store_manager/core/error/failures.dart';
import 'package:cams_store_manager/core/models/api_result.dart';

void main() {
  group('ErrorMapper', () {
    test('maps timeouts to timeout failures with friendly copy', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/spaces'),
        type: DioExceptionType.connectionTimeout,
      );

      final exception = ErrorMapper.fromDioException(
        error,
        fallbackMessage: 'Fallback',
      );

      expect(exception, isA<NetworkException>());
      expect(exception.kind, FailureKind.timeout);
      expect(
        exception.message,
        'The request took too long. Please try again.',
      );
    });

    test('maps 401 payloads to authentication failures', () {
      final exception = ErrorMapper.fromApiResponsePayload(
        {
          'message': 'Token expired.',
          'errorCode': ErrorCodeEnum.tokenExpired.name,
        },
        fallbackMessage: 'Fallback',
        statusCode: 401,
      );

      expect(exception, isA<AuthenticationException>());
      expect(exception.kind, FailureKind.authentication);
      expect(exception.message, 'Token expired.');
    });

    test('maps invalid credentials 401 to validation failure', () {
      final exception = ErrorMapper.fromApiResponsePayload(
        {
          'message': 'Invalid username or password',
          'errorCode': 'InvalidCredentials',
        },
        fallbackMessage: 'Fallback',
        statusCode: 401,
      );

      expect(exception, isA<ValidationException>());
      expect(exception.kind, FailureKind.validation);
      expect(exception.message, 'Invalid username or password');
    });

    test('reads validation errors from errors[] payloads', () {
      final exception = ErrorMapper.fromApiResponsePayload(
        {
          'errors': [
            {'message': 'Email is required.'},
          ],
          'errorCode': ErrorCodeEnum.validationFailed.name,
        },
        fallbackMessage: 'Fallback',
        statusCode: 422,
      );

      expect(exception, isA<ValidationException>());
      expect(exception.kind, FailureKind.validation);
      expect(exception.message, 'Email is required.');
    });

    test('sanitizes technical exception messages when converting to failure',
        () {
      final failure = ErrorMapper.toFailure(
        const ServerException(
          'Failed to load playlists: DioException [bad response]: 500',
        ),
      );

      expect(failure, isA<ServerFailure>());
      expect(failure.kind, FailureKind.server);
      expect(
        failure.message,
        'Something went wrong on our side. Please try again.',
      );
      expect(failure.debugMessage, contains('DioException'));
    });

    test('keeps business-friendly API messages from ApiResult', () {
      final failure = ErrorMapper.fromApiResultFailure<void>(
        const ApiResult<void>(
          isSuccess: false,
          message: 'Room is already assigned.',
          errorCode: 'RESOURCE_CONFLICT',
        ),
        statusCode: 409,
      );

      expect(failure.kind, FailureKind.conflict);
      expect(failure.message, 'Room is already assigned.');
    });
  });
}
