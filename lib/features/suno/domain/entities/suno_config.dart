import 'package:equatable/equatable.dart';

class SunoConfig extends Equatable {
  final String? brandId;
  final String? sunoPromptTemplate;
  final String? sunoDefaultPlaylistId;

  const SunoConfig({
    this.brandId,
    this.sunoPromptTemplate,
    this.sunoDefaultPlaylistId,
  });

  SunoConfig copyWith({
    String? brandId,
    String? sunoPromptTemplate,
    String? sunoDefaultPlaylistId,
  }) {
    return SunoConfig(
      brandId: brandId ?? this.brandId,
      sunoPromptTemplate: sunoPromptTemplate ?? this.sunoPromptTemplate,
      sunoDefaultPlaylistId:
          sunoDefaultPlaylistId ?? this.sunoDefaultPlaylistId,
    );
  }

  @override
  List<Object?> get props => [
        brandId,
        sunoPromptTemplate,
        sunoDefaultPlaylistId,
      ];
}
