import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/error/app_error_reporter.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../domain/repositories/routes_repository.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';
import '../../../tracking/presentation/state/driver_tracking_state.dart';
import '../providers/driver_portal_providers.dart';
import '../widgets/route_bottom_sheet.dart';
import '../widgets/route_map_view.dart';
import '../widgets/route_top_overlay.dart';
import '../widgets/route_tracking_helpers.dart';

// ─────────────────────────────────────────────
// Page — full-screen map layout
// ─────────────────────────────────────────────

class DriverRoutesPage extends ConsumerStatefulWidget {
  const DriverRoutesPage({super.key});

  @override
  ConsumerState<DriverRoutesPage> createState() => _DriverRoutesPageState();
}

class _DriverRoutesPageState extends ConsumerState<DriverRoutesPage> {
  bool _isFinishing = false;

  @override
  Widget build(BuildContext context) {
    final routesAsync = ref.watch(driverRoutesProvider);

    DriverTrackingState tracking;
    try {
      tracking = ref.watch(driverTrackingControllerProvider);
    } catch (_) {
      tracking = const DriverTrackingState();
    }

    final routesLoading = routesAsync.isLoading && !routesAsync.hasValue;
    final routesError = routesAsync.hasValue ? null : routesAsync.error;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.mapBackground,
        body: Stack(
          children: [
            // ── Map fills entire body ─────────────────────────────
            Positioned.fill(child: RouteMapView(tracking: tracking)),

            // ── Top overlay: connection + speed + finish ──────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    0,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RouteTopOverlay(
                        tracking: tracking,
                        isFinishing: _isFinishing,
                        onFinish: _isFinishing
                            ? null
                            : () => _finishRoute(tracking),
                      ),
                      // ── Loading/erro das rotas no nível do mapa ──
                      if (routesLoading || routesError != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        _RoutesStatusBanner(
                          isLoading: routesLoading,
                          message: routesError != null
                              ? AppErrorReporter.messageFor(routesError)
                              : null,
                          onRetry: () =>
                              ref.invalidate(driverRoutesProvider),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── Bottom sheet: students / saved routes ─────────────
            RouteBottomSheet(
              tracking: tracking,
              routesAsync: routesAsync,
              onAutoFinish: _finishRoute,
              onRefresh: () => ref.invalidate(driverRoutesProvider),
            ),
          ],
        ),
        floatingActionButton: !tracking.routeActive
            ? FloatingActionButton.extended(
                onPressed: () => _openAdhocPlanner(context, ref),
                icon: const Icon(Icons.alt_route_rounded, size: 20),
                label: const Text('Gerar rota'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              )
            : null,
      ),
    );
  }

  Future<void> _finishRoute(DriverTrackingState tracking) async {
    if (_isFinishing) return;
    final routeId = tracking.routeId;
    if (routeId == null || routeId <= 0) return;

    setState(() => _isFinishing = true);
    try {
      await ref.read(driverRoutesRepositoryProvider).finishRoute(routeId);
      await ref
          .read(driverTrackingControllerProvider.notifier)
          .stopRouteTracking(silent: true);
      ref.invalidate(driverRoutesProvider);
      // APP-18: dashboard e execução também exibem a rota ativa.
      ref.invalidate(driverRouteControllerProvider);
      ref.invalidate(driverDashboardControllerProvider);
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: 'Rota finalizada com sucesso.',
        type: AppFeedbackType.success,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, message: e.message, type: AppFeedbackType.error);
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        message: AppErrorReporter.messageFor(e),
        type: AppFeedbackType.error,
      );
    } finally {
      if (mounted) setState(() => _isFinishing = false);
    }
  }
}

// ─────────────────────────────────────────────
// Floating banner — loading/error das rotas no nível da página/mapa
// ─────────────────────────────────────────────

/// O bottom sheet já trata seus próprios estados; este banner cobre o mapa
/// quando o [driverRoutesProvider] está carregando ou falhou.
class _RoutesStatusBanner extends StatelessWidget {
  const _RoutesStatusBanner({
    required this.isLoading,
    this.message,
    this.onRetry,
  });

  final bool isLoading;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSubtle,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            const Icon(
              Icons.error_outline_rounded,
              size: 18,
              color: AppColors.danger,
            ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              isLoading
                  ? 'Carregando rotas...'
                  : (message ?? 'Não foi possível carregar as rotas.'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!isLoading && onRetry != null)
            IconButton(
              tooltip: 'Tentar novamente',
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Adhoc Route Planner
// ─────────────────────────────────────────────

/// F5 — períodos de viagem aceitos pelo backend (ver ROUTE_PERIODS no NestJS).
/// O período selecionado filtra as crianças no planning-options e é enviado
/// no start da rota.
const _routePeriodOptions = <(String, String)>[
  ('manha_ida', 'Manhã Ida'),
  ('manha_volta', 'Manhã Volta'),
  ('tarde_ida', 'Tarde Ida'),
  ('tarde_volta', 'Tarde Volta'),
  ('noite_ida', 'Noite Ida'),
  ('noite_volta', 'Noite Volta'),
];

Future<void> _openAdhocPlanner(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(driverRoutesRepositoryProvider);

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => AdhocPlannerContent(
      repo: repo,
      onStart: (period, childIds) async {
        final response = await repo.startRoute(
          period: period,
          childIds: childIds,
        );
        if (!context.mounted) return;
        await startTrackingFromResponse(context, ref, response);
        if (!context.mounted) return;
        ref.invalidate(driverRoutesProvider);
        // APP-17: rota iniciada — dashboard e execução refletem a nova rota.
        ref.invalidate(driverRouteControllerProvider);
        ref.invalidate(driverDashboardControllerProvider);
      },
    ),
  );
}

/// Conteúdo do bottom sheet de geração de rota: seletor de período e lista
/// de crianças elegíveis com seleção individual.
///
/// A seleção inicial vem de [PlanningChild.selectedByDefault] — o backend
/// desmarca apenas exceções (ex.: integrais em manhã_volta) e o motorista
/// pode marcá-las manualmente. A lista é exibida na ordem recebida, com
/// cabeçalho de escola sempre que a escola muda entre crianças
/// consecutivas (o backend ordena por escola + nome).
class AdhocPlannerContent extends StatefulWidget {
  const AdhocPlannerContent({
    super.key,
    required this.repo,
    required this.onStart,
  });

  final RoutesRepository repo;
  final Future<void> Function(String? period, List<int>? childIds) onStart;

  @override
  State<AdhocPlannerContent> createState() => _AdhocPlannerContentState();
}

class _AdhocPlannerContentState extends State<AdhocPlannerContent> {
  bool _busy = false;
  String? _error;
  String? _period;
  late Future<RoutePlanningOptions> _optionsFuture;

  /// Seleção atual de crianças. Nula até o primeiro carregamento — é
  /// inicializada a partir de [PlanningChild.selectedByDefault] e
  /// reinicializada sempre que o período (e a lista) muda.
  Set<int>? _selectedChildIds;
  List<PlanningChild> _lastChildren = const [];

  @override
  void initState() {
    super.initState();
    _optionsFuture = widget.repo.getPlanningOptions();
  }

  void _selectPeriod(String? period) {
    setState(() {
      _period = period;
      _optionsFuture = widget.repo.getPlanningOptions(period: period);
      _selectedChildIds = null;
      _error = null;
    });
  }

  void _toggleChild(PlanningChild child, bool selected) {
    setState(() {
      final current = _selectedChildIds ??= {
        for (final c in _lastChildren)
          if (c.selectedByDefault) c.id,
      };
      if (selected) {
        current.add(child.id);
      } else {
        current.remove(child.id);
      }
    });
  }

  bool _isSelected(PlanningChild child) {
    final selected = _selectedChildIds;
    if (selected == null) return child.selectedByDefault;
    return selected.contains(child.id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Iniciar rota',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'A rota será criada com base nos alunos ativos vinculados ao seu veículo.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Período',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final (value, label) in _routePeriodOptions)
                ChoiceChip(
                  label: Text(label),
                  selected: _period == value,
                  onSelected: _busy
                      ? null
                      : (selected) => _selectPeriod(selected ? value : null),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: FutureBuilder<RoutePlanningOptions>(
              future: _optionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return FaixaErrorState(
                    message: AppErrorReporter.messageFor(
                      snapshot.error ??
                          Exception('Falha ao carregar dados da rota.'),
                    ),
                    onRetry: () => _selectPeriod(_period),
                  );
                }
                final children =
                    snapshot.data?.children ?? const <PlanningChild>[];
                _lastChildren = children;
                // Inicializa a seleção a partir do contrato do backend.
                _selectedChildIds ??= {
                  for (final child in children)
                    if (child.selectedByDefault) child.id,
                };
                if (children.isEmpty) {
                  return FaixaEmptyState(
                    message: _period == null
                        ? 'Nenhum aluno ativo vinculado no momento.'
                        : 'Nenhum aluno ativo neste período.',
                    icon: Icons.child_care_rounded,
                    subtitle: _period == null
                        ? 'Vincule crianças ao seu veículo para iniciar uma rota.'
                        : 'Selecione outro período ou verifique o turno das crianças.',
                  );
                }
                return ListView(
                  children: [
                    Text(
                      '${_selectedChildIds!.length} de ${children.length} '
                      'alunos na rota',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ..._buildGroupedChildren(children),
                  ],
                );
              },
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: _canSubmit ? _submit : null,
            icon: _busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: Text(_busy ? 'Iniciando...' : 'Iniciar rota'),
          ),
        ],
      ),
    );
  }

  /// Só bloqueia quando a lista carregou e o motorista desmarcou todo mundo.
  bool get _canSubmit {
    if (_busy) return false;
    final selected = _selectedChildIds;
    if (selected == null) return true;
    return _lastChildren.isEmpty || selected.isNotEmpty;
  }

  /// Monta a lista na ordem recebida do backend, inserindo um cabeçalho de
  /// escola sempre que a escola muda entre crianças consecutivas.
  List<Widget> _buildGroupedChildren(List<PlanningChild> children) {
    final items = <Widget>[];
    String? lastGroup;
    for (final child in children) {
      final group = _schoolGroupKey(child);
      if (group != lastGroup) {
        lastGroup = group;
        if (items.isNotEmpty) {
          items.add(const SizedBox(height: AppSpacing.md));
        }
        items.add(
          _SchoolGroupHeader(
            name: child.schoolName.trim().isNotEmpty
                ? child.schoolName
                : 'Sem escola vinculada',
          ),
        );
        items.add(const SizedBox(height: AppSpacing.sm));
      } else {
        items.add(const SizedBox(height: AppSpacing.sm));
      }
      items.add(_buildChildItem(child, _isSelected(child)));
    }
    return items;
  }

  /// Chave de agrupamento: schoolId quando disponível; senão o nome
  /// normalizado (crianças sem escola caem no mesmo grupo).
  String _schoolGroupKey(PlanningChild child) {
    final schoolId = child.schoolId;
    if (schoolId != null && schoolId > 0) return 'id:$schoolId';
    return 'name:${child.schoolName.trim().toLowerCase()}';
  }

  Widget _buildChildItem(PlanningChild child, bool selected) {
    final shiftName = child.shiftName;
    return Opacity(
      opacity: selected ? 1 : 0.55,
      child: Container(
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: _busy ? null : () => _toggleChild(child, !selected),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.yellowLight,
                        child: Text(
                          child.name.trim().isNotEmpty
                              ? child.name.trim().characters.first.toUpperCase()
                              : '?',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          child.name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                        ),
                      ),
                      Checkbox(
                        value: selected,
                        onChanged: _busy
                            ? null
                            : (value) => _toggleChild(child, value ?? false),
                      ),
                    ],
                  ),
                  if (child.address.isNotEmpty ||
                      (shiftName != null && shiftName.isNotEmpty)) ...[
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
                          if (shiftName != null && shiftName.isNotEmpty)
                            AppIconTextRow(
                              icon: Icons.access_time_rounded,
                              text: 'Turno: $shiftName',
                            ),
                          if (child.address.isNotEmpty) ...[
                            if (shiftName != null && shiftName.isNotEmpty)
                              const SizedBox(height: AppSpacing.xs),
                            AppIconTextRow(
                              icon: Icons.location_on_rounded,
                              text: 'Endereço: ${child.address}',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final children = _lastChildren;
      final selected = _selectedChildIds ?? const <int>{};
      // Seleção completa equivale ao comportamento padrão do backend; só
      // enviamos childIds quando o motorista removeu alguém da rota
      // (backends anteriores ao contrato rejeitam o campo).
      final childIds = selected.length == children.length
          ? null
          : selected.toList(growable: false);
      await widget.onStart(_period, childIds);
      if (!mounted) return;
      Navigator.of(context).pop();
      showAppSnackBar(
        context,
        message: 'Rota iniciada.',
        type: AppFeedbackType.success,
      );
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }
}

/// Cabeçalho de grupo de escola na lista de planejamento.
class _SchoolGroupHeader extends StatelessWidget {
  const _SchoolGroupHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.school_rounded, size: 16, color: AppColors.ink),
        const SizedBox(width: AppSpacing.sm - 2),
        Expanded(
          child: Text(
            name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}
