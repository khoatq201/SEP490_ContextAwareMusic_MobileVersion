import 'package:flutter/material.dart';

import '../error/error_mapper.dart';
import '../error/failures.dart';
import '../error/failure_kind.dart';

enum AppStatusTone { error, warning, info, success }

class AppErrorPresentation {
  const AppErrorPresentation({
    required this.title,
    required this.message,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String message;
  final IconData icon;
  final AppStatusTone tone;

  factory AppErrorPresentation.fromFailure(
    Failure? failure, {
    String? title,
    String? message,
  }) {
    final kind = failure?.kind ?? FailureKind.unexpected;
    return AppErrorPresentation(
      title: title ?? _titleFor(kind),
      message: failure != null
          ? ErrorMapper.displayMessageForFailure(
              failure,
              overrideMessage: message,
            )
          : (message ?? ErrorMapper.defaultMessageForFailure(kind)),
      icon: _iconFor(kind),
      tone: _toneFor(kind),
    );
  }

  factory AppErrorPresentation.custom({
    required String title,
    required String message,
    IconData icon = Icons.info_outline_rounded,
    AppStatusTone tone = AppStatusTone.info,
  }) {
    return AppErrorPresentation(
      title: title,
      message: message,
      icon: icon,
      tone: tone,
    );
  }

  static String _titleFor(FailureKind kind) {
    switch (kind) {
      case FailureKind.network:
        return 'No internet connection';
      case FailureKind.timeout:
        return 'Request timed out';
      case FailureKind.authentication:
        return 'Session expired';
      case FailureKind.forbidden:
        return 'Access denied';
      case FailureKind.validation:
        return 'Check your information';
      case FailureKind.business:
        return 'Action unavailable';
      case FailureKind.notFound:
        return 'Not found';
      case FailureKind.conflict:
        return 'Already changed';
      case FailureKind.rateLimited:
        return 'Please wait a moment';
      case FailureKind.serverUnavailable:
        return 'Service unavailable';
      case FailureKind.server:
        return 'Something went wrong';
      case FailureKind.cache:
        return 'Unavailable offline';
      case FailureKind.realtime:
        return 'Realtime unavailable';
      case FailureKind.permission:
        return 'Permission needed';
      case FailureKind.cancelled:
        return 'Action cancelled';
      case FailureKind.unexpected:
        return 'Something went wrong';
    }
  }

  static IconData _iconFor(FailureKind kind) {
    switch (kind) {
      case FailureKind.network:
        return Icons.wifi_off_rounded;
      case FailureKind.timeout:
        return Icons.timer_off_outlined;
      case FailureKind.authentication:
        return Icons.lock_clock_outlined;
      case FailureKind.forbidden:
        return Icons.no_accounts_outlined;
      case FailureKind.validation:
      case FailureKind.business:
        return Icons.rule_folder_outlined;
      case FailureKind.notFound:
        return Icons.search_off_rounded;
      case FailureKind.conflict:
        return Icons.sync_problem_rounded;
      case FailureKind.rateLimited:
        return Icons.hourglass_top_rounded;
      case FailureKind.serverUnavailable:
      case FailureKind.server:
        return Icons.cloud_off_rounded;
      case FailureKind.cache:
        return Icons.inventory_2_outlined;
      case FailureKind.realtime:
        return Icons.hub_outlined;
      case FailureKind.permission:
        return Icons.gpp_maybe_outlined;
      case FailureKind.cancelled:
        return Icons.do_not_disturb_alt_outlined;
      case FailureKind.unexpected:
        return Icons.error_outline_rounded;
    }
  }

  static AppStatusTone _toneFor(FailureKind kind) {
    switch (kind) {
      case FailureKind.validation:
      case FailureKind.business:
      case FailureKind.conflict:
      case FailureKind.rateLimited:
      case FailureKind.authentication:
      case FailureKind.forbidden:
      case FailureKind.permission:
        return AppStatusTone.warning;
      case FailureKind.notFound:
      case FailureKind.cancelled:
      case FailureKind.network:
      case FailureKind.timeout:
      case FailureKind.cache:
      case FailureKind.realtime:
        return AppStatusTone.info;
      case FailureKind.serverUnavailable:
      case FailureKind.server:
      case FailureKind.unexpected:
        return AppStatusTone.error;
    }
  }
}
