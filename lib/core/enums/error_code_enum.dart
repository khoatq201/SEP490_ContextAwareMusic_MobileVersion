/// Maps 1:1 with the backend `ErrorCodeEnum`.
///
/// The backend returns `errorCode` as a **PascalCase string** (e.g. `"InvalidCredentials"`).
/// Use [ErrorCodeEnum.fromString] to parse.
enum ErrorCodeEnum {
  success,
  unauthorized,
  forbidden,
  invalidCredentials,
  tokenExpired,
  invalidToken,
  validationFailed,
  invalidInput,
  duplicateEntry,
  invalidOperation,
  tooManyRequests,
  notFound,
  businessRuleViolation,
  insufficientPermissions,
  resourceConflict,
  internalError,
  databaseError,
  externalServiceError,
  unknown;

  /// Parses a PascalCase string returned by the backend.
  /// Returns [ErrorCodeEnum.unknown] if the value is not recognized.
  static ErrorCodeEnum fromString(String? value) {
    if (value == null) return ErrorCodeEnum.unknown;
    switch (value) {
      case 'Success':
        return ErrorCodeEnum.success;
      case 'Unauthorized':
        return ErrorCodeEnum.unauthorized;
      case 'Forbidden':
        return ErrorCodeEnum.forbidden;
      case 'InvalidCredentials':
        return ErrorCodeEnum.invalidCredentials;
      case 'TokenExpired':
        return ErrorCodeEnum.tokenExpired;
      case 'InvalidToken':
        return ErrorCodeEnum.invalidToken;
      case 'ValidationFailed':
        return ErrorCodeEnum.validationFailed;
      case 'InvalidInput':
        return ErrorCodeEnum.invalidInput;
      case 'DuplicateEntry':
        return ErrorCodeEnum.duplicateEntry;
      case 'InvalidOperation':
        return ErrorCodeEnum.invalidOperation;
      case 'TooManyRequests':
        return ErrorCodeEnum.tooManyRequests;
      case 'NotFound':
        return ErrorCodeEnum.notFound;
      case 'BusinessRuleViolation':
        return ErrorCodeEnum.businessRuleViolation;
      case 'InsufficientPermissions':
        return ErrorCodeEnum.insufficientPermissions;
      case 'ResourceConflict':
        return ErrorCodeEnum.resourceConflict;
      case 'InternalError':
        return ErrorCodeEnum.internalError;
      case 'DatabaseError':
        return ErrorCodeEnum.databaseError;
      case 'ExternalServiceError':
        return ErrorCodeEnum.externalServiceError;
      default:
        return ErrorCodeEnum.unknown;
    }
  }
}
