import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../domain/repositories/routes_repository.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';
import '../../../tracking/presentation/state/driver_tracking_controller.dart';
import '../../../tracking/presentation/state/driver_tracking_state.dart';
import '../providers/driver_portal_providers.dart';
import 'driver_general_alert_section.dart';
import 'route_passenger_tile.dart';

/// Lista de passageiros/alunos da rota ativa.
///
/// Exibe os cards de embarque/desembarque, notificações e alerta geral.
class RoutePassengersList extends ConsumerStatefulWidget {
  const RoutePassengersList({
    super.key,
    required this.tracking,
    required this.scrollController,
    this.onAutoFinish,
  });

  final DriverTrackingState tracking;
  final ScrollController scrollController;
  final Future<void> Function(DriverTrackingState)? onAutoFinish;

  @override
  ConsumerState<RoutePassengersList> createState() =>
      _RoutePassengersListState();
}

class _RoutePassengersListState extends ConsumerState<RoutePassengersList> {
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final students = buildStudentRouteCards(widget.tracking);

    if (students.isEmpty) {
      return ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          FaixaEmptyState(
            message: 'Nenhum aluno na rota atual.',
            icon: Icons.groups_2_outlined,
          ),
        ],
      );
    }

    return ListView.separated(
      controller: widget.scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      itemCount: students.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index < students.length) {
          final s = students[index];
          return RoutePassengerTile(
            student: s,
            submitting: _submitting,
            routeActive: widget.tracking.routeActive,
            onBoard:
                s.childId != null &&
                    (s.status == StopStatus.onTheWay ||
                        s.status == StopStatus.pending)
                ? () => _markBoarded(s.childId!)
                : null,
            onDisembark: s.childId != null && s.status == StopStatus.boarded
                ? () => _markDisembarked(s.childId!)
                : null,
            onNotifyArrived: s.childId != null
                ? () => _notifyParent(s.childId!, 'arrived')
                : null,
            onNotifyDelayed: s.childId != null
                ? () => _notifyParent(s.childId!, 'delayed')
                : null,
            onRemove: s.childId != null && s.status != StopStatus.droppedOff
                ? () => _removeStudent(s.childId!, s.name)
                : null,
          );
        }
        return DriverGeneralAlertSection(tracking: widget.tracking);
      },
    );
  }

  Future<void> _markBoarded(int childId) async {
    await _runAction(
      childId: childId,
      apiCall: (repo, routeId) => repo.markBoarding(routeId, childId),
      onLocal: (ctrl) => ctrl.markClientBoardedLocal(childId),
      msg: 'Aluno embarcou.',
    );
  }

  Future<void> _markDisembarked(int childId) async {
    await _runAction(
      childId: childId,
      apiCall: (repo, routeId) => repo.markDisembarking(routeId, childId),
      onLocal: (ctrl) => ctrl.markClientDisembarkedLocal(childId),
      msg: 'Aluno desembarcou.',
    );

    final tracking = ref.read(driverTrackingControllerProvider);
    if (!tracking.routeActive) return;
    final students = buildStudentRouteCards(tracking);
    if (students.isNotEmpty &&
        students.every((s) => s.status == StopStatus.droppedOff)) {
      await widget.onAutoFinish?.call(tracking);
    }
  }

  Future<void> _notifyParent(int childId, String type) async {
    await _runAction(
      childId: childId,
      apiCall: (repo, routeId) => repo.notifyParent(routeId, childId, type),
      onLocal: (_) {},
      msg: type == 'arrived'
          ? 'Responsável notificado: cheguei!'
          : 'Responsável notificado: vou atrasar.',
    );
  }

  Future<void> _removeStudent(int childId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover aluno'),
        content: Text('Remover $name da rota? A rota será recalculada.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    if (_submitting) return;

    final routeId = widget.tracking.routeId;
    if (routeId == null || routeId <= 0) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(driverRoutesRepositoryProvider)
          .removeStudent(routeId, childId);
      ref
          .read(driverTrackingControllerProvider.notifier)
          .removeClientLocal(childId);
      await ref
          .read(driverTrackingControllerProvider.notifier)
          .refreshRoutePreviewNow();
      ref.invalidate(driverRoutesProvider);
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: '$name removido(a) da rota.',
        type: AppFeedbackType.success,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, type: AppFeedbackType.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _runAction({
    required int childId,
    required Future<void> Function(RoutesRepository, int) apiCall,
    required void Function(DriverTrackingController) onLocal,
    required String msg,
  }) async {
    if (_submitting) return;
    final routeId = widget.tracking.routeId;
    if (routeId == null || routeId <= 0) return;

    setState(() => _submitting = true);
    try {
      await apiCall(ref.read(driverRoutesRepositoryProvider), routeId);
      onLocal(ref.read(driverTrackingControllerProvider.notifier));
      await ref
          .read(driverTrackingControllerProvider.notifier)
          .refreshRoutePreviewNow();
      ref.invalidate(driverRoutesProvider);
      if (!mounted) return;
      showAppSnackBar(context, message: msg, type: AppFeedbackType.success);
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, type: AppFeedbackType.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

enum StopStatus { pending, onTheWay, boarded, droppedOff }

class StudentRouteCard {
  const StudentRouteCard({
    required this.clientId,
    required this.childId,
    required this.name,
    required this.sequence,
    required this.status,
    this.pickupLabel,
    this.dropoffLabel,
    this.nextAction,
  });

  final int? clientId;
  final int? childId;
  final String name;
  final int? sequence;
  final StopStatus status;
  final String? pickupLabel;
  final String? dropoffLabel;
  final String? nextAction;
}

List<StudentRouteCard> buildStudentRouteCards(DriverTrackingState tracking) {
  final planned = tracking.routePlannedStops;
  if (planned.isEmpty) return const [];

  final nextKey = tracking.routeRemainingStops.isNotEmpty
      ? _keyOf(tracking.routeRemainingStops.first)
      : null;

  final grouped = <String, List<DriverTrackingStopPoint>>{};
  for (final stop in planned) {
    if ((stop.childId ?? 0) <= 0) continue;
    grouped.putIfAbsent(_keyOf(stop), () => []).add(stop);
  }

  final result = <StudentRouteCard>[];
  for (final entry in grouped.entries) {
    final stops = [...entry.value]
      ..sort((a, b) => (a.sequence ?? 9999).compareTo(b.sequence ?? 9999));
    final pickup = stops
        .where((s) => _isPickupType(s.type))
        .cast<DriverTrackingStopPoint?>()
        .firstWhere((_) => true, orElse: () => null);
    final dropoff = stops
        .where((s) => _isDropoffType(s.type))
        .cast<DriverTrackingStopPoint?>()
        .firstWhere((_) => true, orElse: () => null);
    final anyDelivered = stops.any(
      (s) => s.status.toLowerCase() == 'delivered',
    );
    final anyPicked = stops.any((s) => s.status.toLowerCase() == 'picked_up');
    final status = anyDelivered
        ? StopStatus.droppedOff
        : anyPicked
        ? StopStatus.boarded
        : (entry.key == nextKey ? StopStatus.onTheWay : StopStatus.pending);
    result.add(
      StudentRouteCard(
        clientId: stops.first.clientId,
        childId: stops.first.childId,
        name: _formatStudentName(stops.first.name),
        sequence: stops.first.sequence,
        status: status,
        pickupLabel: pickup?.name,
        dropoffLabel: dropoff?.name,
        nextAction: switch (status) {
          StopStatus.onTheWay || StopStatus.pending => 'Coletar',
          StopStatus.boarded => 'Destino',
          StopStatus.droppedOff => 'Concluido',
        },
      ),
    );
  }
  result.sort((a, b) => (a.sequence ?? 9999).compareTo(b.sequence ?? 9999));
  return result;
}

String _keyOf(DriverTrackingStopPoint s) {
  if ((s.childId ?? 0) > 0) return 'ch:${s.childId}';
  if ((s.clientId ?? 0) > 0) return 'c:${s.clientId}';
  return 's:${s.id ?? s.name ?? s.sequence ?? ''}';
}

bool _isPickupType(String? type) {
  final t = (type ?? '').toLowerCase();
  return t == 'pickup' || t.startsWith('pickup_');
}

bool _isDropoffType(String? type) {
  final t = (type ?? '').toLowerCase();
  return t == 'dropoff' || t.startsWith('dropoff_');
}

String _formatStudentName(String? name) {
  final trimmed = name?.trim() ?? '';
  return trimmed.isEmpty ? 'Aluno' : trimmed;
}
