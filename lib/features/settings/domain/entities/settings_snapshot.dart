import 'package:equatable/equatable.dart';

class SettingsSnapshot extends Equatable {
  final String companyName;
  final String businessType;
  final String planName;
  final String? subscriptionId;
  final int? tokenBalance;
  final bool walletLocked;
  final bool explicitMusicAllowed;
  final bool blockingSongsAllowed;

  const SettingsSnapshot({
    required this.companyName,
    required this.businessType,
    required this.planName,
    this.subscriptionId,
    this.tokenBalance,
    this.walletLocked = false,
    required this.explicitMusicAllowed,
    required this.blockingSongsAllowed,
  });

  String get explicitMusicLabel => explicitMusicAllowed ? 'Allowed' : 'Blocked';
  String get blockingSongsLabel => blockingSongsAllowed ? 'Allowed' : 'Blocked';
  String get tokenBalanceLabel => tokenBalance == null
      ? 'Unavailable'
      : '${_formatTokens(tokenBalance!)} tokens';
  String get subscriptionLabel =>
      subscriptionId == null || subscriptionId!.trim().isEmpty
          ? 'No active subscription'
          : planName;

  @override
  List<Object?> get props => [
        companyName,
        businessType,
        planName,
        subscriptionId,
        tokenBalance,
        walletLocked,
        explicitMusicAllowed,
        blockingSongsAllowed,
      ];
}

String _formatTokens(int value) {
  final text = value.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final remaining = text.length - i;
    buffer.write(text[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(',');
    }
  }
  return value < 0 ? '-$buffer' : buffer.toString();
}
