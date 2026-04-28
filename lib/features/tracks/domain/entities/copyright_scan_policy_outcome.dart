enum CopyrightScanPolicyOutcome {
  clear,
  flagged,
  manual,
  unknown;

  static CopyrightScanPolicyOutcome? fromJson(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) {
      switch (raw) {
        case 0:
          return CopyrightScanPolicyOutcome.clear;
        case 1:
          return CopyrightScanPolicyOutcome.flagged;
        case 2:
          return CopyrightScanPolicyOutcome.manual;
        default:
          return CopyrightScanPolicyOutcome.unknown;
      }
    }
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    final parsedInt = int.tryParse(text);
    if (parsedInt != null) {
      return fromJson(parsedInt);
    }
    switch (text.toLowerCase()) {
      case 'clear':
        return CopyrightScanPolicyOutcome.clear;
      case 'flagged':
        return CopyrightScanPolicyOutcome.flagged;
      case 'manual':
        return CopyrightScanPolicyOutcome.manual;
      default:
        return CopyrightScanPolicyOutcome.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case CopyrightScanPolicyOutcome.clear:
        return 'Clear';
      case CopyrightScanPolicyOutcome.flagged:
        return 'Flagged';
      case CopyrightScanPolicyOutcome.manual:
        return 'Manual Review';
      case CopyrightScanPolicyOutcome.unknown:
        return 'Unknown';
    }
  }
}
