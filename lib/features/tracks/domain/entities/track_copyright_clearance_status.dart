enum TrackCopyrightClearanceStatus {
  pending,
  approved,
  rejected,
  unknown;

  static TrackCopyrightClearanceStatus? fromJson(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) {
      switch (raw) {
        case 0:
          return TrackCopyrightClearanceStatus.pending;
        case 1:
          return TrackCopyrightClearanceStatus.approved;
        case 2:
          return TrackCopyrightClearanceStatus.rejected;
        default:
          return TrackCopyrightClearanceStatus.unknown;
      }
    }
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    final parsedInt = int.tryParse(text);
    if (parsedInt != null) {
      return fromJson(parsedInt);
    }
    switch (text.toLowerCase()) {
      case 'pending':
        return TrackCopyrightClearanceStatus.pending;
      case 'approved':
        return TrackCopyrightClearanceStatus.approved;
      case 'rejected':
        return TrackCopyrightClearanceStatus.rejected;
      default:
        return TrackCopyrightClearanceStatus.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case TrackCopyrightClearanceStatus.pending:
        return 'Review Pending';
      case TrackCopyrightClearanceStatus.approved:
        return 'Approved';
      case TrackCopyrightClearanceStatus.rejected:
        return 'Rejected';
      case TrackCopyrightClearanceStatus.unknown:
        return 'Unknown';
    }
  }

  bool get requiresReview => this == TrackCopyrightClearanceStatus.pending;
}
