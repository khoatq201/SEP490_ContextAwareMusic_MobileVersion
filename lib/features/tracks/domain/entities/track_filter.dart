import '../../../../core/enums/entity_status_enum.dart';
import '../../../../core/enums/music_provider_enum.dart';

class TrackFilter {
  final int page;
  final int pageSize;
  final String? search;
  final String? moodId;
  final String? genre;
  final MusicProviderEnum? provider;
  final bool? isAiGenerated;
  final EntityStatusEnum? status;
  final DateTime? createdFrom;
  final DateTime? createdTo;

  const TrackFilter({
    this.page = 1,
    this.pageSize = 10,
    this.search,
    this.moodId,
    this.genre,
    this.provider,
    this.isAiGenerated,
    this.status,
    this.createdFrom,
    this.createdTo,
  });

  Map<String, dynamic> toQueryParameters() {
    return {
      'page': page,
      'pageSize': pageSize,
      if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
      if (moodId != null && moodId!.trim().isNotEmpty) 'moodId': moodId!.trim(),
      if (genre != null && genre!.trim().isNotEmpty) 'genre': genre!.trim(),
      if (provider != null) 'provider': provider!.value,
      if (isAiGenerated != null) 'isAiGenerated': isAiGenerated,
      if (status != null) 'status': status!.value,
      if (createdFrom != null)
        'createdFrom': createdFrom!.toUtc().toIso8601String(),
      if (createdTo != null) 'createdTo': createdTo!.toUtc().toIso8601String(),
    };
  }

  TrackFilter copyWith({
    int? page,
    int? pageSize,
    String? search,
    String? moodId,
    String? genre,
    MusicProviderEnum? provider,
    bool? isAiGenerated,
    EntityStatusEnum? status,
    DateTime? createdFrom,
    DateTime? createdTo,
  }) {
    return TrackFilter(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      search: search ?? this.search,
      moodId: moodId ?? this.moodId,
      genre: genre ?? this.genre,
      provider: provider ?? this.provider,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      status: status ?? this.status,
      createdFrom: createdFrom ?? this.createdFrom,
      createdTo: createdTo ?? this.createdTo,
    );
  }
}
