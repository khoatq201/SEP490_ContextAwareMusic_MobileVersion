import '../../domain/entities/pair_code_snapshot.dart';

class PairCodeSnapshotModel extends PairCodeSnapshot {
  const PairCodeSnapshotModel({
    required super.code,
    required super.displayCode,
    required super.spaceId,
    super.spaceName,
    required super.expiresAt,
    required super.expiresInSeconds,
  });

  factory PairCodeSnapshotModel.fromJson(Map<String, dynamic> json) {
    return PairCodeSnapshotModel(
      code: json['code'] as String,
      displayCode: json['displayCode'] as String? ?? json['code'] as String,
      spaceId: json['spaceId'] as String,
      spaceName: json['spaceName'] as String?,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      expiresInSeconds: json['expiresInSeconds'] as int? ??
          DateTime.parse(json['expiresAt'] as String)
              .difference(DateTime.now().toUtc())
              .inSeconds,
    );
  }
}
