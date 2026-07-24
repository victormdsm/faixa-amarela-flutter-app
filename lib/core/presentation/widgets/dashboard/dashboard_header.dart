import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Cabeçalho de dashboard.
///
/// Sem saudações vazias ("Olá, nome!"): o título identifica a pessoa e o
/// subtítulo, quando presente, carrega informação real do estado da tela.
class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.userName,
    this.greeting,
    this.subtitle,
  });

  final String userName;
  final String? greeting;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting ?? userName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        if ((subtitle ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.slate),
          ),
        ],
      ],
    );
  }
}
