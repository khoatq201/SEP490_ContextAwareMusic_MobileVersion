import 'package:equatable/equatable.dart';
import 'playlist_entity.dart';

/// A horizontal-scroll section on the Home tab, e.g.
/// "Top categories for you" or "Popular today".
class CategoryEntity extends Equatable {
  final String id;

  /// Section heading displayed above the playlist row
  final String title;

  final List<PlaylistEntity> playlists;

  const CategoryEntity({
    required this.id,
    required this.title,
    this.playlists = const [],
  });

  @override
  List<Object?> get props => [id, title, playlists];
}
