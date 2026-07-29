import 'package:flutter/material.dart';

/// Visual padronizado por tipo de notificação: ícone contextual e rótulo
/// em pt-BR. Usado pelo tile da lista e pelo sheet de detalhe.
({IconData icon, String label, bool isAlert}) notificationTypeVisual(
  String type,
) {
  return switch (type) {
    'boarded' => (
      icon: Icons.directions_bus_rounded,
      label: 'Embarque',
      isAlert: false,
    ),
    'disembarked' => (
      icon: Icons.home_rounded,
      label: 'Desembarque',
      isAlert: false,
    ),
    'arrived' => (
      icon: Icons.location_on_rounded,
      label: 'Chegada',
      isAlert: false,
    ),
    'delayed' => (
      icon: Icons.schedule_rounded,
      label: 'Atraso',
      isAlert: true,
    ),
    'breakdown' || 'flat_tire' || 'accident' => (
      icon: Icons.warning_rounded,
      label: 'Ocorrência',
      isAlert: true,
    ),
    'driver_profile_change_reviewed' => (
      icon: Icons.verified_user_rounded,
      label: 'Perfil do motorista',
      isAlert: false,
    ),
    'payment' || 'billing' || 'invoice' => (
      icon: Icons.receipt_long_rounded,
      label: 'Financeiro',
      isAlert: false,
    ),
    'system' => (
      icon: Icons.info_outline_rounded,
      label: 'Sistema',
      isAlert: false,
    ),
    _ => (
      icon: Icons.notifications_rounded,
      label: 'Aviso',
      isAlert: false,
    ),
  };
}
