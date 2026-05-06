import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  final bool rememberMe;

  const LoginRequested({
    required this.email,
    required this.password,
    this.rememberMe = false,
  });

  @override
  List<Object?> get props => [email, password, rememberMe];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

class AuthUserLoaded extends AuthEvent {
  const AuthUserLoaded();
}

class ChangePasswordRequested extends AuthEvent {
  final String currentPassword;
  final String newPassword;
  final String confirmPassword;

  const ChangePasswordRequested({
    required this.currentPassword,
    required this.newPassword,
    required this.confirmPassword,
  });

  @override
  List<Object?> get props => [currentPassword, newPassword, confirmPassword];
}

class ForgotPasswordOtpRequested extends AuthEvent {
  const ForgotPasswordOtpRequested({
    required this.email,
  });

  final String email;

  @override
  List<Object?> get props => [email];
}

class ForgotPasswordOtpVerifyRequested extends AuthEvent {
  const ForgotPasswordOtpVerifyRequested({
    required this.email,
    required this.otp,
  });

  final String email;
  final String otp;

  @override
  List<Object?> get props => [email, otp];
}

class ForgotPasswordResetRequested extends AuthEvent {
  const ForgotPasswordResetRequested({
    required this.email,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String email;
  final String newPassword;
  final String confirmPassword;

  @override
  List<Object?> get props => [email, newPassword, confirmPassword];
}
