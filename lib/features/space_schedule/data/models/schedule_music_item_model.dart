import '../../domain/entities/schedule_music_item.dart';

class ScheduleMusicItemModel extends ScheduleMusicItem {
  const ScheduleMusicItemModel({
    required super.id,
    required super.title,
    required super.artist,
    super.collection,
    required super.artworkLabel,
    required super.primaryHex,
    required super.secondaryHex,
  });

  factory ScheduleMusicItemModel.fromJson(Map<String, dynamic> json) {
    final title = json['title']?.toString() ?? 'Untitled playlist';
    final artist =
        json['artist']?.toString() ?? json['collection']?.toString() ?? '';
    return ScheduleMusicItemModel(
      id: json['id']?.toString() ?? '',
      title: title,
      artist: artist,
      collection: json['collection']?.toString(),
      artworkLabel: json['artworkLabel']?.toString() ?? title,
      primaryHex: json['primaryHex']?.toString() ?? '#2E5BFF',
      secondaryHex: json['secondaryHex']?.toString() ?? '#00B8A9',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'collection': collection,
      'artworkLabel': artworkLabel,
      'primaryHex': primaryHex,
      'secondaryHex': secondaryHex,
    };
  }
}
