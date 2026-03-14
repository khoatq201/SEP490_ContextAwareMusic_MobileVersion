import 'package:equatable/equatable.dart';
import '../../../../core/models/pagination_result.dart';
import '../../domain/entities/location_space.dart';

enum LocationStatus { initial, loading, success, failure }

class LocationState extends Equatable {
  final LocationStatus status;
  final String? errorMessage;

  // Depending on role, one of these will be populated
  final LocationSpace? pairedSpace; // For Playback Device
  final PaginationResult<LocationSpace>? storeSpaces; // For Store Manager
  final Map<String, PaginationResult<LocationSpace>>?
      brandSpaces; // For Brand Manager
  final Map<String, String>? storeNamesById;

  const LocationState({
    this.status = LocationStatus.initial,
    this.errorMessage,
    this.pairedSpace,
    this.storeSpaces,
    this.brandSpaces,
    this.storeNamesById,
  });

  LocationState copyWith({
    LocationStatus? status,
    String? errorMessage,
    LocationSpace? pairedSpace,
    PaginationResult<LocationSpace>? storeSpaces,
    Map<String, PaginationResult<LocationSpace>>? brandSpaces,
    Map<String, String>? storeNamesById,
  }) {
    return LocationState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      pairedSpace: pairedSpace ?? this.pairedSpace,
      storeSpaces: storeSpaces ?? this.storeSpaces,
      brandSpaces: brandSpaces ?? this.brandSpaces,
      storeNamesById: storeNamesById ?? this.storeNamesById,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        pairedSpace,
        storeSpaces,
        brandSpaces,
        storeNamesById,
      ];
}
