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
  final String? selectedStoreId;
  final List<String> busySpaceIds;

  const LocationState({
    this.status = LocationStatus.initial,
    this.errorMessage,
    this.pairedSpace,
    this.storeSpaces,
    this.brandSpaces,
    this.storeNamesById,
    this.selectedStoreId,
    this.busySpaceIds = const [],
  });

  LocationState copyWith({
    LocationStatus? status,
    String? errorMessage,
    LocationSpace? pairedSpace,
    PaginationResult<LocationSpace>? storeSpaces,
    Map<String, PaginationResult<LocationSpace>>? brandSpaces,
    Map<String, String>? storeNamesById,
    String? selectedStoreId,
    List<String>? busySpaceIds,
    bool clearError = false,
  }) {
    return LocationState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pairedSpace: pairedSpace ?? this.pairedSpace,
      storeSpaces: storeSpaces ?? this.storeSpaces,
      brandSpaces: brandSpaces ?? this.brandSpaces,
      storeNamesById: storeNamesById ?? this.storeNamesById,
      selectedStoreId: selectedStoreId ?? this.selectedStoreId,
      busySpaceIds: busySpaceIds ?? this.busySpaceIds,
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
        selectedStoreId,
        busySpaceIds,
      ];
}
