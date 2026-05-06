import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/presentation/app_feedback.dart';
import '../../domain/entities/forgot_password_metadata.dart';
import '../../domain/entities/user.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  paired,
  error,
  changePasswordSuccess,
  forgotPasswordOtpSent,
  forgotPasswordOtpVerified,
  forgotPasswordResetSuccess,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.failure,
    this.feedback,
    this.forgotPasswordOtpInfo,
    this.forgotPasswordVerifyInfo,
  });

  final AuthStatus status;
  final User? user;
  final Failure? failure;
  final AppFeedback? feedback;
  final ForgotPasswordOtpInfo? forgotPasswordOtpInfo;
  final ForgotPasswordVerifyInfo? forgotPasswordVerifyInfo;

  String? get errorMessage => failure?.message;
  String? get successMessage =>
      feedback?.type == AppFeedbackType.success ? feedback?.message : null;

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool clearUser = false,
    Failure? failure,
    bool clearFailure = false,
    AppFeedback? feedback,
    bool clearFeedback = false,
    ForgotPasswordOtpInfo? forgotPasswordOtpInfo,
    bool clearForgotPasswordOtpInfo = false,
    ForgotPasswordVerifyInfo? forgotPasswordVerifyInfo,
    bool clearForgotPasswordVerifyInfo = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      failure: clearFailure ? null : (failure ?? this.failure),
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
      forgotPasswordOtpInfo: clearForgotPasswordOtpInfo
          ? null
          : (forgotPasswordOtpInfo ?? this.forgotPasswordOtpInfo),
      forgotPasswordVerifyInfo: clearForgotPasswordVerifyInfo
          ? null
          : (forgotPasswordVerifyInfo ?? this.forgotPasswordVerifyInfo),
    );
  }

  @override
  List<Object?> get props => [
        status,
        user,
        failure,
        feedback,
        forgotPasswordOtpInfo,
        forgotPasswordVerifyInfo,
      ];
}
