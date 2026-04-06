import '../../../../core/enums/queue_end_behavior_enum.dart';
import '../../../../core/player/player_state.dart' as ps;
import '../../../cams/presentation/bloc/cams_playback_state.dart';
import '../../../space_control/domain/entities/track.dart';

class QueueSheetItem {
  const QueueSheetItem({
    required this.queueItemId,
    required this.trackId,
    required this.title,
    required this.artist,
    this.artUrl,
    this.isPending = false,
    this.metaLabel,
  });

  final String? queueItemId;
  final String trackId;
  final String title;
  final String artist;
  final String? artUrl;
  final bool isPending;
  final String? metaLabel;
}

class QueueSheetViewData {
  const QueueSheetViewData({
    required this.isFromCams,
    required this.items,
    required this.currentIndex,
    required this.summaryLabel,
    required this.emptyMessage,
    this.pendingNotInQueueLabel,
  });

  final bool isFromCams;
  final List<QueueSheetItem> items;
  final int currentIndex;
  final String summaryLabel;
  final String emptyMessage;
  final String? pendingNotInQueueLabel;

  QueueSheetItem? get currentItem {
    if (currentIndex >= 0 && currentIndex < items.length) {
      return items[currentIndex];
    }
    return items.isNotEmpty ? items.first : null;
  }

  List<QueueSheetItem> get upNext {
    if (items.isEmpty) return const <QueueSheetItem>[];
    if (currentIndex >= 0 && currentIndex + 1 < items.length) {
      return items.sublist(currentIndex + 1);
    }
    return currentIndex >= 0 ? const <QueueSheetItem>[] : items;
  }

  static QueueSheetViewData resolve({
    required ps.PlayerState playerState,
    required CamsPlaybackState camsState,
  }) {
    final playback = camsState.playbackState;
    final queueItems = playback?.spaceQueueItems ?? const [];
    final hasCamsQueue = queueItems.isNotEmpty;
    final pendingQueueItemId = playback?.pendingQueueItemId;

    if (hasCamsQueue) {
      final sortedItems = [...queueItems]
        ..sort((a, b) => a.position.compareTo(b.position));
      final trackById = <String, Track>{
        for (final track in playerState.queue) track.id: track,
      };

      final items = sortedItems.map((item) {
        final matchedTrack = trackById[item.trackId];
        final title =
            (item.trackName != null && item.trackName!.trim().isNotEmpty)
                ? item.trackName!
                : matchedTrack?.title ?? 'Unknown track';
        final artist = matchedTrack?.artist ?? 'Unknown artist';
        final isReady =
            item.isReadyToStream || (item.hlsUrl?.isNotEmpty ?? false);
        final isPending = pendingQueueItemId != null &&
            pendingQueueItemId.isNotEmpty &&
            pendingQueueItemId == item.queueItemId;

        return QueueSheetItem(
          queueItemId: item.queueItemId,
          trackId: item.trackId,
          title: title,
          artist: artist,
          artUrl: matchedTrack?.albumArt,
          isPending: isPending,
          metaLabel: isPending
              ? 'Preparing stream'
              : (isReady ? 'Ready to stream' : 'Waiting for stream'),
        );
      }).toList();

      var currentIndex = -1;
      final currentQueueItemId = playback?.currentQueueItemId;
      if (currentQueueItemId != null && currentQueueItemId.isNotEmpty) {
        currentIndex = items
            .indexWhere((entry) => entry.queueItemId == currentQueueItemId);
      }
      if (currentIndex < 0 &&
          playerState.currentTrackId != null &&
          playerState.currentTrackId!.isNotEmpty) {
        currentIndex = items
            .indexWhere((entry) => entry.trackId == playerState.currentTrackId);
      }
      if (currentIndex < 0 &&
          playback?.currentTrackName != null &&
          playback!.currentTrackName!.isNotEmpty) {
        final normalizedCurrentTrackName =
            playback.currentTrackName!.toLowerCase();
        currentIndex = items.indexWhere(
          (entry) => entry.title.toLowerCase() == normalizedCurrentTrackName,
        );
      }

      final pendingInQueue = pendingQueueItemId != null &&
          pendingQueueItemId.isNotEmpty &&
          items.any((entry) => entry.queueItemId == pendingQueueItemId);
      final endBehavior =
          QueueEndBehaviorEnum.fromValue(playback?.queueEndBehavior);
      final summaryLabel = playback == null
          ? 'Queue synchronized from CAMS'
          : '${items.length} tracks • ${endBehavior.label}';

      return QueueSheetViewData(
        isFromCams: true,
        items: items,
        currentIndex: currentIndex,
        summaryLabel: summaryLabel,
        emptyMessage: items.isEmpty
            ? 'Queue is empty. Add tracks from playlist/track actions.'
            : 'You have reached the end of the synchronized queue.',
        pendingNotInQueueLabel: (!pendingInQueue &&
                pendingQueueItemId != null &&
                pendingQueueItemId.isNotEmpty)
            ? 'Preparing next queue item...'
            : null,
      );
    }

    final items = playerState.queue
        .map((track) => QueueSheetItem(
              queueItemId: track.queueItemId,
              trackId: track.id,
              title: track.title,
              artist: track.artist,
              artUrl: track.albumArt,
              isPending: false,
            ))
        .toList();

    var currentIndex = -1;
    if (playerState.currentIndex >= 0 &&
        playerState.currentIndex < items.length) {
      currentIndex = playerState.currentIndex;
    } else if (playerState.currentTrack?.id != null) {
      currentIndex = items.indexWhere(
        (entry) => entry.trackId == playerState.currentTrack!.id,
      );
    }

    return QueueSheetViewData(
      isFromCams: false,
      items: items,
      currentIndex: currentIndex,
      summaryLabel: items.isEmpty
          ? 'No queue is currently available'
          : '${items.length} tracks in local queue',
      emptyMessage: items.isEmpty
          ? 'No queue is available for this track yet.'
          : 'You have reached the end of the current queue.',
    );
  }
}
