import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../domain/models/enrollment.dart';
import '../../../ui/core/widgets/status_pill.dart';

/// Card de matrícula padronizado.
///
/// Exibe motorista, criança, escola, turno (quando informado) e status.
/// Pode ser usado tanto no portal do responsável (com ações Aceitar/Recusar)
/// quanto no portal do motorista (apenas exibindo o status).
///
/// O slot [actions] permite passar widgets customizados de ação. Quando
/// fornecido, ele sobrescreve os botões padrão Aceitar/Recusar.
class FaixaEnrollmentCard extends StatefulWidget {
  const FaixaEnrollmentCard({
    super.key,
    required this.enrollment,
    this.shift,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.showActions = false,
    this.actions,
  });

  final Enrollment enrollment;
  final String? shift;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool showActions;
  final List<Widget>? actions;

  @override
  State<FaixaEnrollmentCard> createState() => _FaixaEnrollmentCardState();
}

class _FaixaEnrollmentCardState extends State<FaixaEnrollmentCard> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enrollment = widget.enrollment;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.yellowLight,
                    child: Text(
                      _initials(enrollment.childName),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          enrollment.childName.isNotEmpty
                              ? enrollment.childName
                              : 'Dependente',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        if (enrollment.schoolName.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Icon(
                                Icons.school_rounded,
                                size: 14,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  enrollment.schoolName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.slate,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if ((widget.shift ?? '').isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 14,
                                color: AppColors.muted,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  widget.shift!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.slate,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  StatusPill.fromStatus(enrollment.status),
                ],
              ),
              if ((enrollment.driverName.isNotEmpty ||
                  enrollment.vanPlate.isNotEmpty)) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (enrollment.driverName.isNotEmpty)
                        _InfoRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Motorista',
                          value: enrollment.driverName,
                        ),
                      if (enrollment.driverName.isNotEmpty &&
                          enrollment.vanPlate.isNotEmpty)
                        const SizedBox(height: AppSpacing.xs),
                      if (enrollment.vanPlate.isNotEmpty)
                        _InfoRow(
                          icon: Icons.directions_car_rounded,
                          label: 'Van',
                          value: enrollment.vanPlate,
                        ),
                    ],
                  ),
                ),
              ],
              if (widget.actions != null && widget.actions!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Row(children: widget.actions!),
              ] else if (widget.showActions) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isProcessing || widget.onAccept == null
                            ? null
                            : () => _run(widget.onAccept!),
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: const Text('Aceitar'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isProcessing || widget.onReject == null
                            ? null
                            : () => _run(widget.onReject!),
                        icon: _isProcessing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.close_rounded, size: 18),
                        label: const Text('Recusar'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ').where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first.toUpperCase();
    final last = parts.length > 1
        ? parts.last.characters.first.toUpperCase()
        : '';
    return '$first$last';
  }

  Future<void> _run(VoidCallback action) async {
    setState(() => _isProcessing = true);
    try {
      action();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.muted),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
