import 'package:equatable/equatable.dart';

/// Queue item snapshot returned by CAMS state/queue APIs.
class SpaceQueueStateItem extends Equatable {
  final String queueItemId;
  final String trackId;
  final String? brandId;
  final String? trackName;
  final int position;
  final int queueStatus;
  final int source;
  final String? hlsUrl;
  final String? coverImageUrl;
  final bool isReadyToStream;

  const SpaceQueueStateItem({
    required this.queueItemId,
    required this.trackId,
    this.brandId,
    this.trackName,
    required this.position,
    required this.queueStatus,
    required this.source,
    this.hlsUrl,
    this.coverImageUrl,
    this.isReadyToStream = false,
  });

  @override
  List<Object?> get props => [
        queueItemId,
        trackId,
        brandId,
        trackName,
        position,
        queueStatus,
        source,
        hlsUrl,
        coverImageUrl,
        isReadyToStream,
      ];
}
