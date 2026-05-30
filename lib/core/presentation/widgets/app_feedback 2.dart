import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

enum AppFeedbackType { success, warning, error, info }

void showAppSnackBar(
  BuildContext context, {
  required String message,
  AppFeedbackType type = AppFeedbackType.info,
}) {
  final color = switch (type) {
    AppFeedbackType.success => AppColors.success,
    AppFeedbackType.warning => AppColors.yellowDark,
    AppFeedbackType.error => AppColors.danger,
    AppFeedbackType.info => AppColors.ink,
  };

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: color,
        content: Text(message),
      ),
    );
}
