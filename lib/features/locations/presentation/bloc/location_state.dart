import 'package:equatable/equatable.dart';
import '../../domain/entities/location_space.dart';

enum LocationStatus { initial, loading, success, failure }

class LocationState extends Equatable {
  final LocationStatus status;
  final String? errorMessage;
  
  // Depending on role, one of these will be populated
  final LocationSpace? pairedSpace; // For Playback Device
  final List<LocationSpace>? storeSpaces; // For Store Manager
  final Map<String, List<LocationSpace>>? brandSpaces; // For Brand Manager

  const LocationState({
    this.status = LocationStatus.initial,
    this.errorMessage,
    this.pairedSpace,
    this.storeSpaces,
    this.brandSpaces,
  });

  LocationState copyWith({
    LocationStatus? status,
    String? errorMessage,
    LocationSpace? pairedSpace,
    List<LocationSpace>? storeSpaces,
    Map<String, List<LocationSpace>>? brandSpaces,
  }) {
    return LocationState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      pairedSpace: pairedSpace ?? this.pairedSpace,
      storeSpaces: storeSpaces ?? this.storeSpaces,
      brandSpaces: brandSpaces ?? this.brandSpaces,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        pairedSpace,
        storeSpaces,
        brandSpaces,
      ];
}
