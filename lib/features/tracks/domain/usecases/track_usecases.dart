import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../data/datasources/track_remote_datasource.dart';
import '../../data/repositories/track_repository_impl.dart';
import '../entities/api_track.dart';
import '../entities/track_filter.dart';

class GetTracks {
  final TrackRepository repository;

  GetTracks(this.repository);

  Future<Either<Failure, TrackListResponse>> call({
    TrackFilter? filter,
    int page = 1,
    int pageSize = 10,
    String? search,
    String? moodId,
    String? genre,
  }) {
    return repository.getTracks(
      filter: filter,
      page: page,
      pageSize: pageSize,
      search: search,
      moodId: moodId,
      genre: genre,
    );
  }
}

class GetTrackById {
  final TrackRepository repository;

  GetTrackById(this.repository);

  Future<Either<Failure, ApiTrack>> call(String trackId) {
    return repository.getTrackById(trackId);
  }
}

class CreateTrack {
  final TrackRepository repository;

  CreateTrack(this.repository);

  Future<Either<Failure, TrackMutationResult>> call(
    CreateTrackRequest request,
  ) {
    return repository.createTrack(request);
  }
}

class UpdateTrack {
  final TrackRepository repository;

  UpdateTrack(this.repository);

  Future<Either<Failure, TrackMutationResult>> call(
    String trackId,
    UpdateTrackRequest request,
  ) {
    return repository.updateTrack(trackId, request);
  }
}

class DeleteTrack {
  final TrackRepository repository;

  DeleteTrack(this.repository);

  Future<Either<Failure, TrackMutationResult>> call(String trackId) {
    return repository.deleteTrack(trackId);
  }
}

class ToggleTrackStatus {
  final TrackRepository repository;

  ToggleTrackStatus(this.repository);

  Future<Either<Failure, TrackMutationResult>> call(String trackId) {
    return repository.toggleTrackStatus(trackId);
  }
}

class RetranscodeTrack {
  final TrackRepository repository;

  RetranscodeTrack(this.repository);

  Future<Either<Failure, TrackMutationResult>> call(String trackId) {
    return repository.retranscodeTrack(trackId);
  }
}
