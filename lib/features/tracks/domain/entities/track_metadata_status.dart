enum TrackMetadataStatus {
  metadataPending,
  metadataReady,
  metadataUnknown;

  String get displayName {
    switch (this) {
      case TrackMetadataStatus.metadataPending:
        return 'Metadata Pending';
      case TrackMetadataStatus.metadataReady:
        return 'Metadata Ready';
      case TrackMetadataStatus.metadataUnknown:
        return 'Metadata Unknown';
    }
  }
}
