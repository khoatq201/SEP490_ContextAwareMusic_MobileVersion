import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/presentation/app_feedback.dart';
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
  });

  final AuthStatus status;
  final User? user;
  final Failure? failure;
  final AppFeedback? feedback;

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
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      failure: clearFailure ? null : (failure ?? this.failure),
      feedback: clearFeedback ? null : (feedback ?? this.feedback),
    );
  }

  @override
  List<Object?> get props => [status, user, failure, feedback];
}
