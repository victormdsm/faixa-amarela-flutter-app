import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Titulo de secao usado nas dashboards.
class DashboardSectionTitle extends StatelessWidget {
  const DashboardSectionTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    );
  }
}
