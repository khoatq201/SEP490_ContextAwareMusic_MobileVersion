import '../../domain/entities/forgot_password_metadata.dart';

class ForgotPasswordOtpInfoModel extends ForgotPasswordOtpInfo {
  const ForgotPasswordOtpInfoModel({
    required super.email,
    super.expiresAtUtc,
    super.expiresInSeconds,
    super.resendAvailableAtUtc,
    super.resendAfterSeconds,
    super.remainingAttempts,
    super.maxAttempts,
  });

  factory ForgotPasswordOtpInfoModel.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordOtpInfoModel(
      email: json['email']?.toString() ?? '',
      expiresAtUtc: _parseDateTime(json['expiresAtUtc']),
      expiresInSeconds: _parseInt(json['expiresInSeconds']),
      resendAvailableAtUtc: _parseDateTime(json['resendAvailableAtUtc']),
      resendAfterSeconds: _parseInt(json['resendAfterSeconds']),
      remainingAttempts: _parseInt(json['remainingAttempts']),
      maxAttempts: _parseInt(json['maxAttempts']),
    );
  }
}

class ForgotPasswordVerifyInfoModel extends ForgotPasswordVerifyInfo {
  const ForgotPasswordVerifyInfoModel({
    required super.email,
    super.resetSessionExpiresAtUtc,
    super.resetSessionExpiresInSeconds,
    super.remainingAttempts,
    super.maxAttempts,
  });

  factory ForgotPasswordVerifyInfoModel.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordVerifyInfoModel(
      email: json['email']?.toString() ?? '',
      resetSessionExpiresAtUtc: _parseDateTime(
        json['resetSessionExpiresAtUtc'],
      ),
      resetSessionExpiresInSeconds: _parseInt(
        json['resetSessionExpiresInSeconds'],
      ),
      remainingAttempts: _parseInt(json['remainingAttempts']),
      maxAttempts: _parseInt(json['maxAttempts']),
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toUtc();
}

int? _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
