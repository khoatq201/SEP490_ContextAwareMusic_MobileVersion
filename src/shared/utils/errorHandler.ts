/* eslint-disable @typescript-eslint/no-explicit-any */
import { message } from 'antd';
import { ErrorCodeEnum, ERROR_MESSAGES } from '@/shared/types';

/**
 * API Error Response Type
 */
export type ApiErrorResponse = {
  isSuccess: boolean;
  message?: string;
  errorCode?: string;
  errors?: Array<{ field: string; message: string }> | string[];
};

/**
 * Extract error data from axios error
 */
export const getErrorData = (error: any): ApiErrorResponse | null => {
  return error?.response?.data || null;
};

/**
 * Get user-friendly error message
 */
export const getErrorMessage = (
  error: any,
  defaultMessage: string = 'An error occurred. Please try again.',
): string => {
  const errorData = getErrorData(error);

  if (!errorData) return defaultMessage;

  // 1. Use backend message if available
  if (errorData.message) {
    return errorData.message;
  }

  // 2. Check if errorCode exists and map to friendly message
  if (errorData.errorCode) {
    const errorCode = errorData.errorCode as ErrorCodeEnum;
    const friendlyMessage = ERROR_MESSAGES[errorCode];
    if (friendlyMessage) return friendlyMessage;
  }

  // 3. Format validation errors
  if (errorData.errors && Array.isArray(errorData.errors)) {
    if (errorData.errors.length > 0) {
      // Check if errors are objects with field/message
      const firstError = errorData.errors[0];
      if (typeof firstError === 'object' && 'message' in firstError) {
        return firstError.message;
      }
      // If errors are just strings
      if (typeof firstError === 'string') {
        return firstError;
      }
    }
  }

  return defaultMessage;
};

/**
 * Display error message using Ant Design message
 */
export const showErrorMessage = (error: any, defaultMessage?: string): void => {
  const errorMessage = getErrorMessage(error, defaultMessage);
  message.error(errorMessage);
};

/**
 * Get validation errors as array
 */
export const getValidationErrors = (
  error: any,
): Array<{ field: string; message: string }> => {
  const errorData = getErrorData(error);

  if (!errorData?.errors || !Array.isArray(errorData.errors)) {
    return [];
  }

  return errorData.errors.filter(
    (err): err is { field: string; message: string } =>
      typeof err === 'object' && 'field' in err && 'message' in err,
  );
};

/**
 * Check if error is specific type
 */
export const isErrorCode = (error: any, code: ErrorCodeEnum): boolean => {
  const errorData = getErrorData(error);
  return errorData?.errorCode === code;
};

/**
 * Check if error requires re-authentication
 */
export const isAuthError = (error: any): boolean => {
  return (
    isErrorCode(error, ErrorCodeEnum.Unauthorized) ||
    isErrorCode(error, ErrorCodeEnum.TokenExpired) ||
    isErrorCode(error, ErrorCodeEnum.InvalidToken)
  );
};

/**
 * Check if error is permission-related
 */
export const isPermissionError = (error: any): boolean => {
  return isErrorCode(error, ErrorCodeEnum.Forbidden);
};

/**
 * Handle error with custom logic based on error code
 */
export const handleApiError = (
  error: any,
  handlers?: Partial<Record<ErrorCodeEnum, (error: any) => void>>,
  defaultMessage?: string,
): void => {
  const errorData = getErrorData(error);

  if (!errorData) {
    showErrorMessage(error, defaultMessage);
    return;
  }

  const errorCode = errorData.errorCode as ErrorCodeEnum;

  // Execute custom handler if provided
  if (errorCode && handlers?.[errorCode]) {
    handlers[errorCode]!(error);
    return;
  }

  // Default: show error message
  showErrorMessage(error, defaultMessage);
};
