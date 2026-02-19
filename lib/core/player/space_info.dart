import 'package:equatable/equatable.dart';

/// Lightweight snapshot of a space used by [PlayerBloc] to carry
/// the list of available spaces the user can switch between.
///
/// Intentionally lives in `core/player/` so that the PlayerBloc
/// (core layer) does NOT depend on any feature-specific entity.
class SpaceInfo extends Equatable {
  const SpaceInfo({
    required this.id,
    required this.storeId,
    required this.name,
    required this.isOnline,
    this.currentMood,
  });

  final String id;
  final String storeId;
  final String name;
  final bool isOnline;
  final String? currentMood;

  @override
  List<Object?> get props => [id, storeId, name, isOnline, currentMood];
}
