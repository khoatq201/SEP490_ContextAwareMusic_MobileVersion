enum SunoGenerationStatus {
  queued,
  generating,
  completed,
  failed,
  cancelled,
  unknown;

  static SunoGenerationStatus fromJson(dynamic raw) {
    if (raw == null) return SunoGenerationStatus.unknown;
    final numericValue = switch (raw) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value.trim()),
      _ => null,
    };
    switch (numericValue) {
      case 0:
        return SunoGenerationStatus.queued;
      case 1:
        return SunoGenerationStatus.generating;
      case 2:
        return SunoGenerationStatus.completed;
      case 3:
        return SunoGenerationStatus.failed;
      case 4:
        return SunoGenerationStatus.cancelled;
    }

    final normalized = raw.toString().trim().toLowerCase();
    return SunoGenerationStatus.values.firstWhere(
      (status) => status.name.toLowerCase() == normalized,
      orElse: () => SunoGenerationStatus.unknown,
    );
  }

  String get displayName {
    switch (this) {
      case SunoGenerationStatus.queued:
        return 'Queued';
      case SunoGenerationStatus.generating:
        return 'Generating';
      case SunoGenerationStatus.completed:
        return 'Completed';
      case SunoGenerationStatus.failed:
        return 'Failed';
      case SunoGenerationStatus.cancelled:
        return 'Cancelled';
      case SunoGenerationStatus.unknown:
        return 'Unknown';
    }
  }

  bool get isTerminal =>
      this == SunoGenerationStatus.completed ||
      this == SunoGenerationStatus.failed ||
      this == SunoGenerationStatus.cancelled;
}
