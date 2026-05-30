import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

enum AppFeedbackType { success, error, warning, info }

void showAppSnackBar(
  BuildContext context, {
  required String message,
  AppFeedbackType type = AppFeedbackType.info,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(_buildSnackBar(message: message, type: type));
}

SnackBar _buildSnackBar({
  required String message,
  required AppFeedbackType type,
}) {
  final style = switch (type) {
    AppFeedbackType.success => _FeedbackStyle(
      icon: Icons.check_circle_rounded,
      bg: AppColors.success,
    ),
    AppFeedbackType.error => _FeedbackStyle(
      icon: Icons.error_rounded,
      bg: AppColors.danger,
    ),
    AppFeedbackType.warning => _FeedbackStyle(
      icon: Icons.warning_amber_rounded,
      bg: const Color(0xFF9A5A00),
    ),
    AppFeedbackType.info => _FeedbackStyle(
      icon: Icons.info_rounded,
      bg: const Color(0xFF1F4B99),
    ),
  };

  return SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: style.bg,
    content: Row(
      children: [
        Icon(style.icon, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _FeedbackStyle {
  const _FeedbackStyle({required this.icon, required this.bg});

  final IconData icon;
  final Color bg;
}
