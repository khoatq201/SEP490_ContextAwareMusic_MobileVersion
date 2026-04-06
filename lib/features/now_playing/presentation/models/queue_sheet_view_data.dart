import '../../../../core/enums/queue_end_behavior_enum.dart';
import '../../../../core/player/player_state.dart' as ps;
import '../../../cams/domain/entities/space_playback_state.dart';
import '../../../cams/domain/entities/space_queue_state_item.dart';
import '../../../cams/presentation/bloc/cams_playback_state.dart';
import '../../../space_control/domain/entities/track.dart';

enum QueueSheetSectionKind {
  played,
  current,
  upNext,
}

class QueueSheetItem {
  const QueueSheetItem({
    required this.queueItemId,
    required this.trackId,
    required this.title,
    required this.artist,
    required this.section,
    required this.listIndex,
    this.artUrl,
    this.queuePosition,
    this.queueStatus,
    this.isPending = false,
    this.isHistoryOnly = false,
    this.metaLabel,
  });

  final String? queueItemId;
  final String trackId;
  final String title;
  final String artist;
  final String? artUrl;
  final QueueSheetSectionKind section;
  final int listIndex;
  final int? queuePosition;
  final int? queueStatus;
  final bool isPending;
  final bool isHistoryOnly;
  final String? metaLabel;

  bool get isPlayed => section == QueueSheetSectionKind.played;

  bool get isCurrent => section == QueueSheetSectionKind.current;

  bool get isUpNext => section == QueueSheetSectionKind.upNext;
}

class QueueSheetViewData {
  const QueueSheetViewData({
    required this.isFromCams,
    required this.items,
    required this.played,
    required this.current,
    required this.upNext,
    required this.currentIndex,
    required this.summaryLabel,
    required this.emptyMessage,
    required this.upNextEmptyMessage,
    this.pendingNotInQueueLabel,
  });

  final bool isFromCams;
  final List<QueueSheetItem> items;
  final List<QueueSheetItem> played;
  final List<QueueSheetItem> current;
  final List<QueueSheetItem> upNext;
  final int currentIndex;
  final String summaryLabel;
  final String emptyMessage;
  final String upNextEmptyMessage;
  final String? pendingNotInQueueLabel;

  QueueSheetItem? get currentItem {
    if (current.isNotEmpty) {
      return current.first;
    }
    return null;
  }

  bool get hasVisibleItems =>
      played.isNotEmpty || current.isNotEmpty || upNext.isNotEmpty;

  static QueueSheetViewData resolve({
    required ps.PlayerState playerState,
    required CamsPlaybackState camsState,
  }) {
    final playback = camsState.playbackState;
    final queueItems =
        playback?.spaceQueueItems ?? const <SpaceQueueStateItem>[];
    final hasCamsQueue = queueItems.isNotEmpty;
    final pendingQueueItemId = playback?.pendingQueueItemId;

    if (hasCamsQueue) {
      final sortedItems = [...queueItems]
        ..sort((a, b) => a.position.compareTo(b.position));
      final trackById = <String, Track>{
        for (final track in playerState.queue) track.id: track,
      };
      final currentIndex = _resolveCurrentIndex(
        sortedItems: sortedItems,
        playback: playback,
        playerState: playerState,
      );

      final items = <QueueSheetItem>[];
      final played = <QueueSheetItem>[];
      final current = <QueueSheetItem>[];
      final upNext = <QueueSheetItem>[];

      for (var index = 0; index < sortedItems.length; index += 1) {
        final item = sortedItems[index];
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
        final section = _resolveCamsSection(
          item: item,
          index: index,
          currentIndex: currentIndex,
          currentQueueItemId: playback?.currentQueueItemId,
        );
        final queueItem = QueueSheetItem(
          queueItemId: item.queueItemId,
          trackId: item.trackId,
          title: title,
          artist: artist,
          artUrl: matchedTrack?.albumArt,
          section: section,
          listIndex: index,
          queuePosition: item.position,
          queueStatus: item.queueStatus,
          isPending: isPending,
          isHistoryOnly: false,
          metaLabel: _buildCamsMetaLabel(
            item: item,
            section: section,
            isPending: isPending,
            isReady: isReady,
            playback: playback,
          ),
        );
        items.add(queueItem);
        if (section == QueueSheetSectionKind.played) {
          played.add(queueItem);
        } else if (section == QueueSheetSectionKind.current) {
          current.add(queueItem);
        } else {
          upNext.add(queueItem);
        }
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
        played: played,
        current: current,
        upNext: upNext,
        currentIndex: currentIndex,
        summaryLabel: summaryLabel,
        emptyMessage: 'Queue is empty. Add tracks from playlist/track actions.',
        upNextEmptyMessage: 'No upcoming tracks in queue.',
        pendingNotInQueueLabel: (!pendingInQueue &&
                pendingQueueItemId != null &&
                pendingQueueItemId.isNotEmpty)
            ? 'Preparing next queue item...'
            : null,
      );
    }

    final localItems = playerState.queue
        .map((track) => QueueSheetItem(
              queueItemId: track.queueItemId,
              trackId: track.id,
              title: track.title,
              artist: track.artist,
              artUrl: track.albumArt,
              section: QueueSheetSectionKind.upNext,
              listIndex: 0,
              isHistoryOnly: false,
            ))
        .toList();

    var currentIndex = -1;
    if (playerState.currentIndex >= 0 &&
        playerState.currentIndex < localItems.length) {
      currentIndex = playerState.currentIndex;
    } else if (playerState.currentTrack?.id != null) {
      currentIndex = localItems.indexWhere(
        (entry) => entry.trackId == playerState.currentTrack!.id,
      );
    }
    if (currentIndex < 0 && localItems.isNotEmpty) {
      currentIndex = 0;
    }

    final items = <QueueSheetItem>[];
    final played = <QueueSheetItem>[];
    final current = <QueueSheetItem>[];
    final upNext = <QueueSheetItem>[];

    for (var index = 0; index < localItems.length; index += 1) {
      final baseItem = localItems[index];
      final section = currentIndex < 0
          ? QueueSheetSectionKind.upNext
          : index < currentIndex
              ? QueueSheetSectionKind.played
              : index == currentIndex
                  ? QueueSheetSectionKind.current
                  : QueueSheetSectionKind.upNext;
      final item = QueueSheetItem(
        queueItemId: baseItem.queueItemId,
        trackId: baseItem.trackId,
        title: baseItem.title,
        artist: baseItem.artist,
        artUrl: baseItem.artUrl,
        section: section,
        listIndex: index,
        isHistoryOnly: false,
        metaLabel: section == QueueSheetSectionKind.played ? 'Played' : null,
      );
      items.add(item);
      if (section == QueueSheetSectionKind.played) {
        played.add(item);
      } else if (section == QueueSheetSectionKind.current) {
        current.add(item);
      } else {
        upNext.add(item);
      }
    }

    return QueueSheetViewData(
      isFromCams: false,
      items: items,
      played: played,
      current: current,
      upNext: upNext,
      currentIndex: currentIndex,
      summaryLabel: items.isEmpty
          ? 'No queue is currently available'
          : '${items.length} tracks in local queue',
      emptyMessage: 'No queue is available for this track yet.',
      upNextEmptyMessage: 'No upcoming tracks in queue.',
    );
  }

  static int _resolveCurrentIndex({
    required List<SpaceQueueStateItem> sortedItems,
    required SpacePlaybackState? playback,
    required ps.PlayerState playerState,
  }) {
    var currentIndex = -1;
    final currentQueueItemId = playback?.currentQueueItemId;
    if (currentQueueItemId != null && currentQueueItemId.isNotEmpty) {
      currentIndex = sortedItems
          .indexWhere((entry) => entry.queueItemId == currentQueueItemId);
    }
    if (currentIndex < 0) {
      currentIndex = sortedItems.indexWhere(
        (entry) => entry.queueStatus == SpacePlaybackState.queueStatusPlaying,
      );
    }
    if (currentIndex < 0 &&
        playerState.currentTrackId != null &&
        playerState.currentTrackId!.isNotEmpty) {
      currentIndex = sortedItems
          .indexWhere((entry) => entry.trackId == playerState.currentTrackId);
    }
    if (currentIndex < 0 &&
        playback?.currentTrackName != null &&
        playback!.currentTrackName!.isNotEmpty) {
      final normalizedCurrentTrackName =
          playback.currentTrackName!.trim().toLowerCase();
      currentIndex = sortedItems.indexWhere((entry) {
        final trackName = entry.trackName?.trim().toLowerCase();
        return trackName != null && trackName == normalizedCurrentTrackName;
      });
    }
    return currentIndex;
  }

  static QueueSheetSectionKind _resolveCamsSection({
    required SpaceQueueStateItem item,
    required int index,
    required int currentIndex,
    required String? currentQueueItemId,
  }) {
    if (item.queueItemId == currentQueueItemId ||
        item.queueStatus == SpacePlaybackState.queueStatusPlaying ||
        (currentIndex >= 0 && index == currentIndex)) {
      return QueueSheetSectionKind.current;
    }
    if (item.queueStatus == SpacePlaybackState.queueStatusPlayed ||
        item.queueStatus == SpacePlaybackState.queueStatusSkipped) {
      return QueueSheetSectionKind.played;
    }
    if (currentIndex >= 0 && index < currentIndex) {
      return QueueSheetSectionKind.played;
    }
    return QueueSheetSectionKind.upNext;
  }

  static String _buildCamsMetaLabel({
    required SpaceQueueStateItem item,
    required QueueSheetSectionKind section,
    required bool isPending,
    required bool isReady,
    required SpacePlaybackState? playback,
  }) {
    if (section == QueueSheetSectionKind.current) {
      return playback?.isPaused == true ? 'Paused' : 'Now playing';
    }
    if (section == QueueSheetSectionKind.played) {
      if (item.queueStatus == SpacePlaybackState.queueStatusSkipped) {
        return 'Skipped';
      }
      return 'Played';
    }
    if (isPending) {
      return 'Preparing stream';
    }
    return isReady ? 'Ready to stream' : 'Waiting for stream';
  }
}
