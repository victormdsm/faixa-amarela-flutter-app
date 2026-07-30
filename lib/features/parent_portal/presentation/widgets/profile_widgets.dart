import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/app_shared_widgets.dart';

class ProfileErrorPane extends StatelessWidget {
  const ProfileErrorPane({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return FaixaErrorState(message: message, onRetry: onRetry);
  }
}
