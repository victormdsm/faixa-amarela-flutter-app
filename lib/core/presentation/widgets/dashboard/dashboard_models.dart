import 'package:flutter/material.dart';

/// Modelo de métrica para dashboards do portal.
class PortalHomeMetric {
  const PortalHomeMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.backgroundColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
}

/// Modelo de ação rápida para dashboards do portal.
class PortalHomeAction {
  const PortalHomeAction({
    this.key,
    required this.label,
    this.tooltip,
    required this.icon,
    required this.onTap,
    this.color,
  });

  final Key? key;
  final String label;

  /// Tooltip de acessibilidade. Quando informado, envolve o botao com
  /// [Tooltip], permitindo localizacao por `find.byTooltip` em testes.
  final String? tooltip;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
}
