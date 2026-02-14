import 'package:equatable/equatable.dart';

enum DownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
}

class OfflinePlaylist extends Equatable {
  final String id;
  final String moodName;
  final String? coverUrl;
  final int trackCount;
  final double totalSizeMB;
  final DownloadStatus downloadStatus;
  final double? downloadProgress; // 0.0 to 1.0

  const OfflinePlaylist({
    required this.id,
    required this.moodName,
    this.coverUrl,
    required this.trackCount,
    required this.totalSizeMB,
    this.downloadStatus = DownloadStatus.notDownloaded,
    this.downloadProgress,
  });

  OfflinePlaylist copyWith({
    String? id,
    String? moodName,
    String? coverUrl,
    int? trackCount,
    double? totalSizeMB,
    DownloadStatus? downloadStatus,
    double? downloadProgress,
  }) {
    return OfflinePlaylist(
      id: id ?? this.id,
      moodName: moodName ?? this.moodName,
      coverUrl: coverUrl ?? this.coverUrl,
      trackCount: trackCount ?? this.trackCount,
      totalSizeMB: totalSizeMB ?? this.totalSizeMB,
      downloadStatus: downloadStatus ?? this.downloadStatus,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }

  @override
  List<Object?> get props => [
        id,
        moodName,
        coverUrl,
        trackCount,
        totalSizeMB,
        downloadStatus,
        downloadProgress,
      ];
}
