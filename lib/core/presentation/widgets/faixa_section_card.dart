import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// Card de seção para agrupar campos de formulário.
///
/// Fundo branco, raio 16, padding 16, sombra sutil e borda leve.
/// Pode exibir um título com ícone opcional e um subtítulo.
class FaixaSectionCard extends StatelessWidget {
  const FaixaSectionCard({
    super.key,
    this.icon,
    this.title,
    this.subtitle,
    required this.child,
    this.trailing,
  });

  final IconData? icon;
  final String? title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasHeader = title != null || subtitle != null || trailing != null;
    final headerTrailing = trailing;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSubtle,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHeader)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 20, color: AppColors.yellow),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null)
                        Text(
                          title!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.slate,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // ignore: use_null_aware_elements
                if (headerTrailing != null) headerTrailing,
              ],
            ),
          if (hasHeader) const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}
