import 'package:dartz/dartz.dart';

import '../../../../core/enums/queue_insert_mode_enum.dart';
import '../../../../core/error/failures.dart';
import '../../data/repositories/cams_repository_impl.dart';
import '../entities/space_queue_state_item.dart';

class QueueTracksParams {
  final String spaceId;
  final List<String> trackIds;
  final QueueInsertModeEnum mode;
  final bool isClearExistingQueue;
  final String? reason;
  final bool usePlaybackDeviceScope;

  const QueueTracksParams({
    required this.spaceId,
    required this.trackIds,
    required this.mode,
    this.isClearExistingQueue = false,
    this.reason,
    this.usePlaybackDeviceScope = false,
  });
}

class QueuePlaylistParams {
  final String spaceId;
  final String playlistId;
  final QueueInsertModeEnum mode;
  final bool isClearExistingQueue;
  final String? reason;
  final bool usePlaybackDeviceScope;

  const QueuePlaylistParams({
    required this.spaceId,
    required this.playlistId,
    required this.mode,
    this.isClearExistingQueue = false,
    this.reason,
    this.usePlaybackDeviceScope = false,
  });
}

class ReorderQueueParams {
  final String spaceId;
  final List<String> queueItemIds;
  final bool usePlaybackDeviceScope;

  const ReorderQueueParams({
    required this.spaceId,
    required this.queueItemIds,
    this.usePlaybackDeviceScope = false,
  });
}

class RemoveQueueItemsParams {
  final String spaceId;
  final List<String> queueItemIds;
  final bool usePlaybackDeviceScope;

  const RemoveQueueItemsParams({
    required this.spaceId,
    required this.queueItemIds,
    this.usePlaybackDeviceScope = false,
  });
}

class QueueScopeParams {
  final String spaceId;
  final bool usePlaybackDeviceScope;

  const QueueScopeParams({
    required this.spaceId,
    this.usePlaybackDeviceScope = false,
  });
}

class QueueTracks {
  final CamsRepository repository;

  QueueTracks(this.repository);

  Future<Either<Failure, void>> call(QueueTracksParams params) {
    return repository.queueTracks(
      spaceId: params.spaceId,
      trackIds: params.trackIds,
      mode: params.mode,
      isClearExistingQueue: params.isClearExistingQueue,
      reason: params.reason,
      usePlaybackDeviceScope: params.usePlaybackDeviceScope,
    );
  }
}

class QueuePlaylist {
  final CamsRepository repository;

  QueuePlaylist(this.repository);

  Future<Either<Failure, void>> call(QueuePlaylistParams params) {
    return repository.queuePlaylist(
      spaceId: params.spaceId,
      playlistId: params.playlistId,
      mode: params.mode,
      isClearExistingQueue: params.isClearExistingQueue,
      reason: params.reason,
      usePlaybackDeviceScope: params.usePlaybackDeviceScope,
    );
  }
}

class ReorderQueue {
  final CamsRepository repository;

  ReorderQueue(this.repository);

  Future<Either<Failure, void>> call(ReorderQueueParams params) {
    return repository.reorderQueue(
      spaceId: params.spaceId,
      queueItemIds: params.queueItemIds,
      usePlaybackDeviceScope: params.usePlaybackDeviceScope,
    );
  }
}

class RemoveQueueItems {
  final CamsRepository repository;

  RemoveQueueItems(this.repository);

  Future<Either<Failure, void>> call(RemoveQueueItemsParams params) {
    return repository.removeQueueItems(
      spaceId: params.spaceId,
      queueItemIds: params.queueItemIds,
      usePlaybackDeviceScope: params.usePlaybackDeviceScope,
    );
  }
}

class ClearQueue {
  final CamsRepository repository;

  ClearQueue(this.repository);

  Future<Either<Failure, void>> call(QueueScopeParams params) {
    return repository.clearQueue(
      spaceId: params.spaceId,
      usePlaybackDeviceScope: params.usePlaybackDeviceScope,
    );
  }
}

class GetSpaceQueue {
  final CamsRepository repository;

  GetSpaceQueue(this.repository);

  Future<Either<Failure, List<SpaceQueueStateItem>>> call(
      QueueScopeParams params) {
    return repository.getQueue(
      params.spaceId,
      usePlaybackDeviceScope: params.usePlaybackDeviceScope,
    );
  }
}
