import 'package:equatable/equatable.dart';

class PairCodeSnapshot extends Equatable {
  final String code;
  final String displayCode;
  final String spaceId;
  final String? spaceName;
  final DateTime expiresAt;
  final int expiresInSeconds;

  const PairCodeSnapshot({
    required this.code,
    required this.displayCode,
    required this.spaceId,
    this.spaceName,
    required this.expiresAt,
    required this.expiresInSeconds,
  });

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);

  int get remainingSeconds {
    final remaining = expiresAt.difference(DateTime.now().toUtc()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  @override
  List<Object?> get props => [
        code,
        displayCode,
        spaceId,
        spaceName,
        expiresAt,
        expiresInSeconds,
      ];
}
