enum AiGenerationModeEnum {
  suno(1),
  brandModel(2),
  unknown(-1);

  const AiGenerationModeEnum(this.value);

  final int value;

  static AiGenerationModeEnum fromJson(dynamic raw) {
    if (raw == null) return AiGenerationModeEnum.unknown;
    if (raw is int) {
      return AiGenerationModeEnum.values.firstWhere(
        (mode) => mode.value == raw,
        orElse: () => AiGenerationModeEnum.unknown,
      );
    }
    final text = raw.toString().trim();
    if (text.isEmpty) return AiGenerationModeEnum.unknown;
    final parsedInt = int.tryParse(text);
    if (parsedInt != null) {
      return fromJson(parsedInt);
    }

    final normalized = text
        .replaceAll('-', '')
        .replaceAll('_', '')
        .replaceAll(' ', '')
        .toLowerCase();
    switch (normalized) {
      case 'suno':
        return AiGenerationModeEnum.suno;
      case 'brandmodel':
        return AiGenerationModeEnum.brandModel;
      default:
        return AiGenerationModeEnum.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case AiGenerationModeEnum.suno:
        return 'Suno';
      case AiGenerationModeEnum.brandModel:
        return 'Brand Model';
      case AiGenerationModeEnum.unknown:
        return 'Unknown';
    }
  }
}
