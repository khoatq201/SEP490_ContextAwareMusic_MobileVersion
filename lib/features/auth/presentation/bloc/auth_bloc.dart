import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/presentation/app_feedback.dart';
import '../../../../core/services/session_data_cache.dart';
import '../../../../core/session/session_cubit.dart';
import '../../domain/usecases/change_password.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/login.dart';
import '../../domain/usecases/logout.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required this.login,
    required this.logout,
    required this.getCurrentUser,
    required this.changePassword,
    required this.sessionCubit,
    this.sessionDataCache,
  }) : super(const AuthState()) {
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
    on<AuthUserLoaded>(_onAuthUserLoaded);
    on<ChangePasswordRequested>(_onChangePasswordRequested);
  }

  final Login login;
  final Logout logout;
  final GetCurrentUser getCurrentUser;
  final ChangePassword changePassword;
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
}
