import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_theme.dart';
import 'driver_action_chip.dart';
import 'route_passengers_list.dart';

/// Tile expansível com as informações e ações de um aluno na rota ativa.
class RoutePassengerTile extends StatefulWidget {
  const RoutePassengerTile({
    super.key,
    required this.student,
    required this.submitting,
    required this.routeActive,
    this.onBoard,
    this.onDisembark,
    this.onNotifyArrived,
    this.onNotifyDelayed,
    this.onRemove,
  });

  final StudentRouteCard student;
  final bool submitting;
  final bool routeActive;
  final VoidCallback? onBoard;
  final VoidCallback? onDisembark;
  final VoidCallback? onNotifyArrived;
  final VoidCallback? onNotifyDelayed;
  final VoidCallback? onRemove;

  @override
  State<RoutePassengerTile> createState() => _RoutePassengerTileState();
}

class _RoutePassengerTileState extends State<RoutePassengerTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final student = widget.student;
    final (label, color) = switch (student.status) {
      StopStatus.onTheWay => ('A caminho', AppColors.statusOnTheWay),
      StopStatus.boarded => ('Embarcado', AppColors.statusBoarded),
      StopStatus.droppedOff => ('Desembarcado', AppColors.slate),
      StopStatus.pending => ('Pendente', AppColors.slate),
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (student.sequence != null) ...[
                        Container(
                          width: 28,
                          height: 28,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            '${student.sequence}',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: Text(
                          student.name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                            color: color.withValues(alpha: 0.3),
                          ),
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: ScaleTransition(
                                  scale: animation,
                                  child: child,
                                ),
                              ),
                          child: Row(
                            key: ValueKey(student.status),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (student.status == StopStatus.boarded ||
                                  student.status ==
                                      StopStatus.droppedOff) ...[
                                Icon(
                                  Icons.check_rounded,
                                  size: 13,
                                  color: color,
                                ),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                label,
                                style: Theme.of(context).textTheme.labelSmall
                                    ?.copyWith(
                                      color: color,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 20,
                        color: AppColors.slate,
                      ),
                    ],
                  ),
                  if (student.pickupLabel != null ||
                      student.dropoffLabel != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      [
                        if (student.pickupLabel != null)
                          'Embarque: ${student.pickupLabel}',
                        if (student.dropoffLabel != null)
                          'Destino: ${student.dropoffLabel}',
                      ].join(' · '),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      FilledButton.tonal(
                        // onBoard nulo = ação indisponível p/ o status atual —
                        // o botão fica visivelmente desabilitado em vez de
                        // parecer ativo e não fazer nada ao toque.
                        onPressed:
                            widget.submitting ||
                                !widget.routeActive ||
                                widget.onBoard == null
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                widget.onBoard!.call();
                              },
                        child: const Text('Embarcou'),
                      ),
                      OutlinedButton(
                        onPressed:
                            widget.submitting ||
                                !widget.routeActive ||
                                widget.onDisembark == null
                            ? null
                            : () {
                                HapticFeedback.lightImpact();
                                widget.onDisembark!.call();
                              },
                        child: const Text('Desembarcou'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Notificar responsável',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: DriverActionChip(
                          icon: Icons.location_on_rounded,
                          label: 'Cheguei',
                          color: AppColors.statusBoarded,
                          enabled: !widget.submitting && widget.routeActive,
                          onTap: widget.onNotifyArrived,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: DriverActionChip(
                          icon: Icons.schedule_rounded,
                          label: 'Vou atrasar',
                          color: AppColors.warningInk,
                          enabled: !widget.submitting && widget.routeActive,
                          onTap: widget.onNotifyDelayed,
                        ),
                      ),
                    ],
                  ),
                  if (widget.onRemove != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: widget.submitting ? null : widget.onRemove,
                        icon: const Icon(Icons.person_remove_rounded, size: 18),
                        label: const Text('Remover da rota'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(
                            color: AppColors.danger,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
