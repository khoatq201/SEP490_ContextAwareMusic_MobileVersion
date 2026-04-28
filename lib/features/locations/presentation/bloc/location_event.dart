import 'package:equatable/equatable.dart';
import '../../../cams/domain/entities/space_playback_state.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object> get props => [];
}

class LoadLocationsRequested extends LocationEvent {
  const LoadLocationsRequested();
}

class LocationSelectedStoreChanged extends LocationEvent {
  final String storeId;

  const LocationSelectedStoreChanged(this.storeId);

  @override
  List<Object> get props => [storeId];
}

class LocationGeneratePairCodeRequested extends LocationEvent {
  final String spaceId;

  const LocationGeneratePairCodeRequested(this.spaceId);

  @override
  List<Object> get props => [spaceId];
}

class LocationRevokePairCodeRequested extends LocationEvent {
  final String spaceId;

  const LocationRevokePairCodeRequested(this.spaceId);

  @override
  List<Object> get props => [spaceId];
}

class LocationUnpairDeviceRequested extends LocationEvent {
  final String spaceId;

  const LocationUnpairDeviceRequested(this.spaceId);

  @override
  List<Object> get props => [spaceId];
}

class LocationPlaybackStateSynced extends LocationEvent {
  final SpacePlaybackState playbackState;

  const LocationPlaybackStateSynced(this.playbackState);

  @override
  List<Object> get props => [playbackState];
}
