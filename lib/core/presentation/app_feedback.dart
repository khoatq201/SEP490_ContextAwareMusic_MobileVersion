import 'package:equatable/equatable.dart';

import '../error/error_mapper.dart';
import '../error/failures.dart';

enum AppFeedbackType { error, success, warning, info }

class AppFeedback extends Equatable {
  const AppFeedback({
    required this.type,
    required this.message,
    this.title,
    this.failure,
    this.isDismissible = true,
  });

  final AppFeedbackType type;
  final String message;
  final String? title;
  final Failure? failure;
  final bool isDismissible;

  factory AppFeedback.error(
    String message, {
    String? title,
    Failure? failure,
    bool isDismissible = true,
  }) {
    return AppFeedback(
      type: AppFeedbackType.error,
      message: message,
      title: title,
      failure: failure,
      isDismissible: isDismissible,
    );
  }

  factory AppFeedback.success(
    String message, {
    String? title,
    bool isDismissible = true,
  }) {
    return AppFeedback(
      type: AppFeedbackType.success,
      message: message,
      title: title,
      isDismissible: isDismissible,
    );
  }

  factory AppFeedback.warning(
    String message, {
    String? title,
    bool isDismissible = true,
  }) {
    return AppFeedback(
      type: AppFeedbackType.warning,
      message: message,
      title: title,
      isDismissible: isDismissible,
    );
  }

  factory AppFeedback.info(
    String message, {
    String? title,
    bool isDismissible = true,
  }) {
    return AppFeedback(
      type: AppFeedbackType.info,
      message: message,
      title: title,
      isDismissible: isDismissible,
    );
  }

  factory AppFeedback.fromFailure(
    Failure failure, {
    String? title,
    String? message,
    bool isDismissible = true,
  }) {
    return AppFeedback(
      type: AppFeedbackType.error,
      title: title,
      message: ErrorMapper.displayMessageForFailure(
        failure,
        overrideMessage: message,
      ),
      failure: failure,
      isDismissible: isDismissible,
    );
  }

  @override
  List<Object?> get props => [type, message, title, failure, isDismissible];
}
