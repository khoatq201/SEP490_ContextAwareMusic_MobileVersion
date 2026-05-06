import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/presentation/app_feedback.dart';
import '../../../../core/services/session_data_cache.dart';
import '../../../../core/session/session_cubit.dart';
import '../../domain/entities/forgot_password_metadata.dart';
import '../../domain/usecases/change_password.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import '../../domain/usecases/request_forgot_password_otp.dart';
import '../../domain/usecases/reset_forgot_password.dart';
import '../../domain/usecases/verify_forgot_password_otp.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this.login,
    required this.logout,
    required this.getCurrentUser,
    required this.changePassword,
    required this.requestForgotPasswordOtp,
    required this.verifyForgotPasswordOtp,
    required this.resetForgotPassword,
    required this.sessionCubit,
    this.sessionDataCache,
  }) : super(const AuthState()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<AuthUserLoaded>(_onAuthUserLoaded);
    on<ChangePasswordRequested>(_onChangePasswordRequested);
    on<ForgotPasswordOtpRequested>(_onForgotPasswordOtpRequested);
    on<ForgotPasswordOtpVerifyRequested>(_onForgotPasswordOtpVerifyRequested);
    on<ForgotPasswordResetRequested>(_onForgotPasswordResetRequested);
  }

  final Login login;
  final Logout logout;
  final GetCurrentUser getCurrentUser;
  final ChangePassword changePassword;
  final RequestForgotPasswordOtp requestForgotPasswordOtp;
  final VerifyForgotPasswordOtp verifyForgotPasswordOtp;
  final ResetForgotPassword resetForgotPassword;
  final SessionCubit sessionCubit;
  final SessionDataCache? sessionDataCache;

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      clearFailure: true,
      clearFeedback: true,
      clearForgotPasswordVerifyInfo: true,
    ));

    final result = await login(
      email: event.email,
      password: event.password,
      rememberMe: event.rememberMe,
    );

    await result.fold<Future<void>>(
      (failure) async {
        emit(
          state.copyWith(
            status: AuthStatus.error,
            failure: failure,
            clearFeedback: true,
          ),
        );
      },
      (user) async {
        sessionDataCache?.clear();
        sessionCubit.setRoleFromString(user.role);
        await sessionCubit.restoreSelectionFromStorage();
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            clearFailure: true,
            clearFeedback: true,
          ),
        );
      },
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      clearFailure: true,
      clearFeedback: true,
    ));

    final result = await logout();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.error,
          failure: failure,
          clearFeedback: true,
        ),
      ),
      (_) {
        sessionDataCache?.clear();
        sessionCubit.reset();
        emit(const AuthState(status: AuthStatus.unauthenticated));
      },
    );
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      clearFailure: true,
      clearFeedback: true,
    ));

    final result = await getCurrentUser();

    result.fold(
      (failure) {
        if (failure.isRetryable) {
          emit(
            state.copyWith(
              status: AuthStatus.error,
              failure: failure,
              clearFeedback: true,
            ),
          );
          return;
        }

        sessionDataCache?.clear();
        sessionCubit.reset();
        emit(
          const AuthState(status: AuthStatus.unauthenticated),
        );
      },
      (user) {
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            clearFailure: true,
            clearFeedback: true,
          ),
        );
      },
    );
  }

  Future<void> _onAuthUserLoaded(
    AuthUserLoaded event,
    Emitter<AuthState> emit,
  ) async {
    final result = await getCurrentUser();

    result.fold(
      (_) {},
      (user) {
        emit(
          state.copyWith(
            user: user,
            clearFailure: true,
          ),
        );
      },
    );
  }

  Future<void> _onChangePasswordRequested(
    ChangePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      clearFailure: true,
      clearFeedback: true,
    ));

    final result = await changePassword(
      currentPassword: event.currentPassword,
      newPassword: event.newPassword,
      confirmPassword: event.confirmPassword,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.error,
          failure: failure,
          clearFeedback: true,
        ),
      ),
      (_) {
        emit(
          state.copyWith(
            status: AuthStatus.changePasswordSuccess,
            feedback: AppFeedback.success('Password changed successfully'),
            clearFailure: true,
          ),
        );
      },
    );
  }

  Future<void> _onForgotPasswordOtpRequested(
    ForgotPasswordOtpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      clearFailure: true,
      clearFeedback: true,
    ));

    final result = await requestForgotPasswordOtp(email: event.email);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.error,
          failure: failure,
          clearFeedback: true,
        ),
      ),
      (info) => emit(
        state.copyWith(
          status: AuthStatus.forgotPasswordOtpSent,
          feedback: AppFeedback.success('Verification code sent to your email'),
          forgotPasswordOtpInfo: info,
          clearForgotPasswordVerifyInfo: true,
          clearFailure: true,
        ),
      ),
    );
  }

  Future<void> _onForgotPasswordOtpVerifyRequested(
    ForgotPasswordOtpVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      clearFailure: true,
      clearFeedback: true,
    ));

    final result = await verifyForgotPasswordOtp(
      email: event.email,
      otp: event.otp,
    );

    result.fold(
      (failure) {
        final updatedOtpInfo = _applyOtpAttemptMetadataFromFailure(failure);
        emit(
          state.copyWith(
            status: AuthStatus.error,
            failure: failure,
            clearFeedback: true,
            forgotPasswordOtpInfo: updatedOtpInfo,
          ),
        );
      },
      (info) => emit(
        state.copyWith(
          status: AuthStatus.forgotPasswordOtpVerified,
          feedback: AppFeedback.success('Verification code confirmed'),
          forgotPasswordVerifyInfo: info,
          clearFailure: true,
        ),
      ),
    );
  }

  Future<void> _onForgotPasswordResetRequested(
    ForgotPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      clearFailure: true,
      clearFeedback: true,
    ));

    final result = await resetForgotPassword(
      email: event.email,
      newPassword: event.newPassword,
      confirmPassword: event.confirmPassword,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: AuthStatus.error,
          failure: failure,
          clearFeedback: true,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: AuthStatus.forgotPasswordResetSuccess,
          feedback: AppFeedback.success(
            'Password reset successfully. Please sign in again.',
          ),
          clearFailure: true,
          clearForgotPasswordOtpInfo: true,
          clearForgotPasswordVerifyInfo: true,
        ),
      ),
    );
  }

  ForgotPasswordOtpInfo? _applyOtpAttemptMetadataFromFailure(Failure failure) {
    final current = state.forgotPasswordOtpInfo;
    final debugMessage = failure.debugMessage;
    if (debugMessage is! String || debugMessage.isEmpty) {
      return current;
    }

    final remainingAttempts = _extractMetadataInt(
      debugMessage,
      'remainingAttempts',
    );
    final maxAttempts = _extractMetadataInt(debugMessage, 'maxAttempts');
    if (remainingAttempts == null && maxAttempts == null) {
      return current;
    }

    return (current ??
            ForgotPasswordOtpInfo(
              email: '',
              remainingAttempts: remainingAttempts,
              maxAttempts: maxAttempts,
            ))
        .copyWith(
      remainingAttempts: remainingAttempts,
      maxAttempts: maxAttempts,
    );
  }

  int? _extractMetadataInt(String source, String key) {
    final match = RegExp('$key\\s*=\\s*(\\d+)').firstMatch(source);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }
}
