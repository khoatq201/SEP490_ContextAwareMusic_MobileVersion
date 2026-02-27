import 'package:equatable/equatable.dart';

/// Supported sensor condition types.
enum ConditionType { temperature, humidity, crowd, noiseLevel }

/// Comparison operators for a rule condition.
enum ConditionOperator { greaterThan, lessThan, equalTo }

/// A single context rule: IF [condition] THEN [action].
class ContextRuleEntity extends Equatable {
  final String id;
  final String name;
  final ConditionType conditionType;
  final ConditionOperator operator_;
  final double conditionValue;

  /// Human-readable action label, e.g. "Phát Chill Playlist"
  final String actionLabel;

  /// Optional playlist id to trigger
  final String? targetPlaylistId;

  /// Whether this rule is currently active
  final bool isEnabled;

  /// True when the sensor is currently crossing the threshold and this rule is controlling music
  final bool isTriggered;

  const ContextRuleEntity({
    required this.id,
    required this.name,
    required this.conditionType,
    required this.operator_,
    required this.conditionValue,
    required this.actionLabel,
    this.targetPlaylistId,
    this.isEnabled = true,
    this.isTriggered = false,
  });

  String get conditionTypeLabel {
    switch (conditionType) {
      case ConditionType.temperature:
        return 'Nhiệt độ';
      case ConditionType.humidity:
        return 'Độ ẩm';
      case ConditionType.crowd:
        return 'Lượng khách';
      case ConditionType.noiseLevel:
        return 'Tiếng ồn';
    }
  }

  String get operatorLabel {
    switch (operator_) {
      case ConditionOperator.greaterThan:
        return '>';
      case ConditionOperator.lessThan:
        return '<';
      case ConditionOperator.equalTo:
        return '=';
    }
  }

  String get conditionUnit {
    switch (conditionType) {
      case ConditionType.temperature:
        return '°C';
      case ConditionType.humidity:
        return '%';
      case ConditionType.noiseLevel:
        return 'dB';
      case ConditionType.crowd:
        return '';
    }
  }

  /// Full human-readable description, e.g. "Nếu Nhiệt độ > 30°C → Phát Chill Playlist"
  String get summary => 'Nếu $conditionTypeLabel $operatorLabel '
      '${conditionValue.toStringAsFixed(conditionValue == conditionValue.roundToDouble() ? 0 : 1)}$conditionUnit '
      '→ $actionLabel';

  ContextRuleEntity copyWith({bool? isEnabled, bool? isTriggered}) =>
      ContextRuleEntity(
        id: id,
        name: name,
        conditionType: conditionType,
        operator_: operator_,
        conditionValue: conditionValue,
        actionLabel: actionLabel,
        targetPlaylistId: targetPlaylistId,
        isEnabled: isEnabled ?? this.isEnabled,
        isTriggered: isTriggered ?? this.isTriggered,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        conditionType,
        operator_,
        conditionValue,
        actionLabel,
        targetPlaylistId,
        isEnabled,
        isTriggered,
      ];
}
