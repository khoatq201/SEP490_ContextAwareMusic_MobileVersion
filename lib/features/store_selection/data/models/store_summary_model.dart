import '../../domain/entities/store_summary.dart';

class StoreSummaryModel extends StoreSummary {
  const StoreSummaryModel({
    required super.id,
    required super.name,
    required super.address,
    required super.spacesCount,
    super.imageUrl,
  });

  factory StoreSummaryModel.fromJson(Map<String, dynamic> json) {
    return StoreSummaryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      spacesCount: json['spacesCount'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'spacesCount': spacesCount,
      'imageUrl': imageUrl,
    };
  }
}
