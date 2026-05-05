enum TrackCopyrightClearanceStatus {
  notApplicable,
  pendingScan,
  pendingReview,
  cleared,
  rejected,
  unknown;

  int? get value {
    switch (this) {
      case TrackCopyrightClearanceStatus.notApplicable:
        return 0;
      case TrackCopyrightClearanceStatus.pendingScan:
        return 1;
      case TrackCopyrightClearanceStatus.pendingReview:
        return 2;
      case TrackCopyrightClearanceStatus.cleared:
        return 3;
      case TrackCopyrightClearanceStatus.rejected:
        return 4;
      case TrackCopyrightClearanceStatus.unknown:
        return null;
    }
  }

  static TrackCopyrightClearanceStatus? fromJson(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) {
      switch (raw) {
        case 0:
          return TrackCopyrightClearanceStatus.notApplicable;
        case 1:
          return TrackCopyrightClearanceStatus.pendingScan;
        case 2:
          return TrackCopyrightClearanceStatus.pendingReview;
        case 3:
          return TrackCopyrightClearanceStatus.cleared;
        case 4:
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
    switch (text.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '')) {
      case 'notapplicable':
      case 'na':
        return TrackCopyrightClearanceStatus.notApplicable;
      case 'pendingscan':
        return TrackCopyrightClearanceStatus.pendingScan;
      case 'pendingreview':
      case 'pending':
        return TrackCopyrightClearanceStatus.pendingReview;
      case 'cleared':
      case 'approved':
        return TrackCopyrightClearanceStatus.cleared;
      case 'rejected':
        return TrackCopyrightClearanceStatus.rejected;
      default:
        return TrackCopyrightClearanceStatus.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case TrackCopyrightClearanceStatus.notApplicable:
        return 'Not Applicable';
      case TrackCopyrightClearanceStatus.pendingScan:
        return 'Pending Scan';
      case TrackCopyrightClearanceStatus.pendingReview:
        return 'Pending Review';
      case TrackCopyrightClearanceStatus.cleared:
        return 'Cleared';
      case TrackCopyrightClearanceStatus.rejected:
        return 'Rejected';
      case TrackCopyrightClearanceStatus.unknown:
        return 'Unknown';
    }
  }

  bool get isPlayable =>
      this == TrackCopyrightClearanceStatus.notApplicable ||
      this == TrackCopyrightClearanceStatus.cleared;

  bool get requiresReview =>
      this == TrackCopyrightClearanceStatus.pendingReview;
}
