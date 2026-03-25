import '../../domain/entities/suno_config.dart';

class SunoConfigModel extends SunoConfig {
  const SunoConfigModel({
    super.brandId,
    super.sunoPromptTemplate,
    super.sunoDefaultPlaylistId,
  });

  factory SunoConfigModel.fromJson(Map<String, dynamic> json) {
    return SunoConfigModel(
      brandId: json['brandId']?.toString(),
      sunoPromptTemplate: json['sunoPromptTemplate']?.toString(),
      sunoDefaultPlaylistId: json['sunoDefaultPlaylistId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brandId': brandId,
      'sunoPromptTemplate': sunoPromptTemplate,
      'sunoDefaultPlaylistId': sunoDefaultPlaylistId,
    };
  }
}
