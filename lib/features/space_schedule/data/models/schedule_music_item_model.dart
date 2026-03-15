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
    return ScheduleMusicItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      collection: json['collection'] as String?,
      artworkLabel: json['artworkLabel'] as String,
      primaryHex: json['primaryHex'] as String,
      secondaryHex: json['secondaryHex'] as String,
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
