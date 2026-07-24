import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/entities/user_role.dart';

/// Seletor de perfil (Motorista / Responsável) para a tela de login.
///
/// Substitui o [SegmentedButton] por dois cards clicáveis, conforme o
/// design Stitch.
class LoginRoleSelector extends StatelessWidget {
  const LoginRoleSelector({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
    this.enabled = true,
  });

  final UserRole selectedRole;
  final ValueChanged<UserRole> onRoleChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: UserRole.values
          .map((role) {
            final isSelected = role == selectedRole;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: role == UserRole.driver ? 8 : 0,
                  left: role == UserRole.parent ? 8 : 0,
                ),
                child: _RoleCard(
                  role: role,
                  isSelected: isSelected,
                  enabled: enabled,
                  onTap: enabled ? () => onRoleChanged(role) : null,
                ),
              ),
            );
          })
          .toList(growable: false),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.enabled,
    this.onTap,
  });

  final UserRole role;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = role == UserRole.parent
        ? Icons.family_restroom_rounded
        : Icons.directions_bus_filled_rounded;

    return Material(
      color: isSelected ? AppColors.yellowLight : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.yellow : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected
                    ? AppColors.yellow
                    : AppColors.ink.withValues(alpha: 0.55),
              ),
              const SizedBox(height: 8),
              Text(
                role.label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.ink
                      : AppColors.ink.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
