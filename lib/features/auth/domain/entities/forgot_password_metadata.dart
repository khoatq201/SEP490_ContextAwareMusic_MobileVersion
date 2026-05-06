import 'package:equatable/equatable.dart';

class ForgotPasswordOtpInfo extends Equatable {
  const ForgotPasswordOtpInfo({
    required this.email,
    this.expiresAtUtc,
    this.expiresInSeconds,
    this.resendAvailableAtUtc,
    this.resendAfterSeconds,
    this.remainingAttempts,
    this.maxAttempts,
  });

  final String email;
  final DateTime? expiresAtUtc;
  final int? expiresInSeconds;
  final DateTime? resendAvailableAtUtc;
  final int? resendAfterSeconds;
  final int? remainingAttempts;
  final int? maxAttempts;

  ForgotPasswordOtpInfo copyWith({
    String? email,
    DateTime? expiresAtUtc,
    int? expiresInSeconds,
    DateTime? resendAvailableAtUtc,
    int? resendAfterSeconds,
    int? remainingAttempts,
    int? maxAttempts,
  }) {
    return ForgotPasswordOtpInfo(
      email: email ?? this.email,
      expiresAtUtc: expiresAtUtc ?? this.expiresAtUtc,
      expiresInSeconds: expiresInSeconds ?? this.expiresInSeconds,
      resendAvailableAtUtc: resendAvailableAtUtc ?? this.resendAvailableAtUtc,
      resendAfterSeconds: resendAfterSeconds ?? this.resendAfterSeconds,
      remainingAttempts: remainingAttempts ?? this.remainingAttempts,
      maxAttempts: maxAttempts ?? this.maxAttempts,
    );
  }

  @override
  List<Object?> get props => [
        email,
        expiresAtUtc,
        expiresInSeconds,
        resendAvailableAtUtc,
        resendAfterSeconds,
        remainingAttempts,
        maxAttempts,
      ];
}

class ForgotPasswordVerifyInfo extends Equatable {
  const ForgotPasswordVerifyInfo({
    required this.email,
    this.resetSessionExpiresAtUtc,
    this.resetSessionExpiresInSeconds,
    this.remainingAttempts,
    this.maxAttempts,
  });

  final String email;
  final DateTime? resetSessionExpiresAtUtc;
  final int? resetSessionExpiresInSeconds;
  final int? remainingAttempts;
  final int? maxAttempts;

  @override
  List<Object?> get props => [
        email,
        resetSessionExpiresAtUtc,
        resetSessionExpiresInSeconds,
        remainingAttempts,
        maxAttempts,
      ];
}
