import 'package:equatable/equatable.dart';

class ScheduleMusicItem extends Equatable {
  final String id;
  final String title;
  final String artist;
  final String? collection;
  final String artworkLabel;
  final String primaryHex;
  final String secondaryHex;

  const ScheduleMusicItem({
    required this.id,
    required this.title,
    required this.artist,
    this.collection,
    required this.artworkLabel,
    required this.primaryHex,
    required this.secondaryHex,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        collection,
        artworkLabel,
        primaryHex,
        secondaryHex,
      ];
}
