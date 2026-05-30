import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/network/api_exception.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../../../tracking/presentation/state/driver_tracking_controller.dart';
import '../../../tracking/presentation/providers/tracking_providers.dart';
import '../../../tracking/presentation/state/driver_tracking_state.dart';
import '../../data/driver_portal_repository.dart';
import '../providers/driver_portal_providers.dart';
import 'ad_banner_widget.dart';

class DriverHomePage extends ConsumerWidget {
  const DriverHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(appSessionControllerProvider).session;

    if (session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go(AppRoutes.login);
      });
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Area do Motorista'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Clientes'),
              Tab(text: 'Rotas'),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Configuracoes',
              onPressed: () => context.push(AppRoutes.driverSettings),
              icon: const Icon(Icons.settings_outlined),
            ),
            IconButton(
              tooltip: 'Atualizar',
              onPressed: () {
                ref.invalidate(driverClientsProvider);
                ref.invalidate(driverRoutesProvider);
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'Sair',
              onPressed: () =>
                  ref.read(appSessionControllerProvider.notifier).clear(),
              icon: const Icon(Icons.logout_rounded),
            ),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            return AnimatedBuilder(
              animation: tabController,
              builder: (context, _) {
                if (tabController.index != 0) {
                  return const SizedBox.shrink();
                }
                return const SizedBox.shrink();
              },
            );
          },
        ),
        body: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE9E3CF)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFFFFF1BE),
                    child: Icon(
                      Icons.directions_bus_rounded,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Motorista: ${session?.user.name ?? ''}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
              child: AdBannerWidget(height: 108),
            ),
            const Expanded(
              child: TabBarView(
                children: [_DriverClientsTab(), _DriverRoutesTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatEta(int seconds) {
  if (seconds <= 0) return '0 min';
  final hours = seconds ~/ 3600;
  final minutes = ((seconds % 3600) / 60).ceil();
  if (hours <= 0) return '$minutes min';
  if (minutes <= 0) return '$hours h';
  return '$hours h ${minutes.toString().padLeft(2, '0')} min';
}

String _formatDistance(double meters) {
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
  return '${meters.toStringAsFixed(0)} m';
}

String _formatTime(DateTime value) {
  final local = value.toLocal();
  final hh = local.hour.toString().padLeft(2, '0');
  final mm = local.minute.toString().padLeft(2, '0');
  final ss = local.second.toString().padLeft(2, '0');
  return '$hh:$mm:$ss';
}

class _DriverClientsTab extends ConsumerStatefulWidget {
  const _DriverClientsTab();

  @override
  ConsumerState<_DriverClientsTab> createState() => _DriverClientsTabState();
}

class _DriverClientsTabState extends ConsumerState<_DriverClientsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(driverClientsProvider);
    return clientsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorPane(message: error.toString()),
      data: (page) {
        final filteredItems = page.items.where(_matchesClientSearch).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE6DFC8)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x10000000),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: InputDecoration(
                        hintText:
                            'Buscar responsavel, CPF, telefone ou dependente',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _query.trim().isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Limpar',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _driverClientMetricChip(
                        context,
                        icon: Icons.people_outline_rounded,
                        label: 'Responsaveis',
                        value: '${page.items.length}',
                      ),
                      const SizedBox(width: 8),
                      _driverClientMetricChip(
                        context,
                        icon: Icons.filter_alt_outlined,
                        label: 'Resultado',
                        value: '${filteredItems.length}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredItems.isEmpty
                  ? _EmptyPane(
                      message: _query.trim().isEmpty
                          ? 'Nenhum cliente encontrado.'
                          : 'Nenhum resultado para a busca informada.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final client = filteredItems[index];
                        final parent = (client['parent'] as Map?) ?? const {};
                        final children =
                            ((client['children'] as List?) ?? const []);
                        final address = (client['address'] as Map?) ?? const {};
                        final district =
                            (address['district'] as Map?) ?? const {};
                        final clientId = (client['id'] as num?)?.toInt() ?? 0;
                        final parentName =
                            (parent['name'] ?? 'Cliente #$clientId').toString();
                        final selectedDependent =
                            ((client['child'] as Map?) ??
                            const <String, dynamic>{});
                        final inadimplencyAlert =
                            client['inadimplency_alert'] == true;
                        final inadimplencyAmount =
                            (client['inadimplency_amount'] as num?)?.toDouble();
                        final cpf = (parent['cpf'] ?? '').toString();
                        final phone = (parent['cell_phone'] ?? '').toString();

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE7E0C9)),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D000000),
                                blurRadius: 14,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF1BE),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.person_outline_rounded,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            parentName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (cpf.isNotEmpty)
                                            Text(
                                              'CPF: $cpf',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: AppColors.slate,
                                                  ),
                                            ),
                                          if (phone.isNotEmpty)
                                            Text(
                                              phone,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: AppColors.slate,
                                                  ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF7F4EA),
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        border: Border.all(
                                          color: const Color(0xFFE8DFC4),
                                        ),
                                      ),
                                      child: Text(
                                        '${children.length} depend.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _driverInfoPill(
                                      context,
                                      icon: Icons.location_on_outlined,
                                      text:
                                          'Bairro: ${(district['name'] ?? 'Nao informado').toString()}',
                                    ),
                                    if ((selectedDependent['name'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      _driverInfoPill(
                                        context,
                                        icon: Icons.child_care_outlined,
                                        text:
                                            'Vinculado: ${selectedDependent['name']}',
                                      ),
                                  ],
                                ),
                                if (inadimplencyAlert) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF4D6),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(0xFFE3B23C),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            inadimplencyAmount != null &&
                                                    inadimplencyAmount > 0
                                                ? 'Debito em aberto: R\$ ${inadimplencyAmount.toStringAsFixed(2)}'
                                                : 'Responsavel/dependente com debitos.',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    FilledButton.tonalIcon(
                                      onPressed: clientId <= 0
                                          ? null
                                          : () => _showChildren(
                                              context,
                                              ref,
                                              clientId,
                                              parentName,
                                              children.cast<dynamic>(),
                                            ),
                                      icon: const Icon(Icons.groups_2_rounded),
                                      label: const Text('Dependentes'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: clientId <= 0
                                          ? null
                                          : () => _showInadimplencyDialog(
                                              context,
                                              ref,
                                              clientId,
                                              parentName,
                                              initialAmount: inadimplencyAmount,
                                            ),
                                      icon: const Icon(
                                        Icons.request_quote_outlined,
                                      ),
                                      label: const Text('Debito'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: clientId <= 0
                                          ? null
                                          : () => _confirmAndUnlinkClient(
                                              context,
                                              ref,
                                              clientId,
                                              parentName,
                                            ),
                                      icon: const Icon(Icons.link_off_rounded),
                                      label: const Text('Desvincular'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  bool _matchesClientSearch(Map<String, dynamic> client) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final parent = (client['parent'] as Map?) ?? const {};
    final child = (client['child'] as Map?) ?? const {};
    final children = ((client['children'] as List?) ?? const []);
    final haystack = [
      (parent['name'] ?? '').toString(),
      (parent['cpf'] ?? '').toString(),
      (parent['cell_phone'] ?? '').toString(),
      (parent['email'] ?? '').toString(),
      (child['name'] ?? '').toString(),
      ...children
          .whereType<Map>()
          .map((e) => (e['name'] ?? '').toString())
          .where((e) => e.isNotEmpty),
    ].join(' ').toLowerCase();
    return haystack.contains(q);
  }

  void _showChildren(
    BuildContext context,
    WidgetRef ref,
    int clientId,
    String parentName,
    List<dynamic> initialChildren,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _DriverClientDependentsSheet(
        clientId: clientId,
        parentName: parentName,
        initialChildren: initialChildren,
      ),
    );
  }

  Future<void> _confirmAndUnlinkClient(
    BuildContext context,
    WidgetRef ref,
    int clientId,
    String parentName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desvincular responsavel'),
        content: Text(
          'Deseja desvincular $parentName deste motorista? O cadastro do responsavel sera mantido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Desvincular'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final confirmWordController = TextEditingController();
    try {
      final secondConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmacao final'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para evitar erro acidental, digite DESVINCULAR para confirmar.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmWordController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Digite DESVINCULAR',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final ok =
                    confirmWordController.text.trim().toUpperCase() ==
                    'DESVINCULAR';
                if (!ok) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Digite DESVINCULAR para confirmar.'),
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      );

      if (secondConfirmed != true || !context.mounted) return;
    } finally {
      confirmWordController.dispose();
    }

    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessao expirada. Faca login novamente.')),
      );
      return;
    }

    try {
      await ref
          .read(driverPortalRepositoryProvider)
          .unlinkClient(session.authorizationHeader, clientId);
      ref.invalidate(driverClientsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Responsavel desvinculado com sucesso.')),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showInadimplencyDialog(
    BuildContext context,
    WidgetRef ref,
    int clientId,
    String parentName, {
    double? initialAmount,
  }) async {
    final draft = await showModalBottomSheet<_InadimplencyDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _InadimplencyEditorSheet(
        parentName: parentName,
        initialAmount: initialAmount,
      ),
    );

    if (draft == null || !context.mounted) return;

    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessao expirada. Faca login novamente.')),
      );
      return;
    }

    try {
      await ref
          .read(driverPortalRepositoryProvider)
          .updateClientInadimplency(
            session.authorizationHeader,
            clientId,
            amount: draft.amount,
            isInadimplent: draft.amount > 0,
            reason: draft.reason,
          );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.invalidate(driverClientsProvider);
      });
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            draft.amount > 0
                ? 'Debito atualizado com sucesso.'
                : 'Debito removido com sucesso.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

Widget _driverClientMetricChip(
  BuildContext context, {
  required IconData icon,
  required String label,
  required String value,
}) {
  return Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5EA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9DFC2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.ink),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.slate),
                ),
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _driverInfoPill(
  BuildContext context, {
  required IconData icon,
  required String text,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F7F2),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0xFFE7E0CA)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.slate),
        const SizedBox(width: 6),
        Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _DriverClientDependentsSheet extends ConsumerStatefulWidget {
  const _DriverClientDependentsSheet({
    required this.clientId,
    required this.parentName,
    required this.initialChildren,
  });

  final int clientId;
  final String parentName;
  final List<dynamic> initialChildren;

  @override
  ConsumerState<_DriverClientDependentsSheet> createState() =>
      _DriverClientDependentsSheetState();
}

class _DriverClientDependentsSheetState
    extends ConsumerState<_DriverClientDependentsSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncChildren = ref.watch(
      driverClientChildrenProvider(widget.clientId),
    );
    final initialItems = widget.initialChildren
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);

    final height = (MediaQuery.of(context).size.height * 0.82).clamp(
      420.0,
      680.0,
    );

    return SizedBox(
      height: height,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dependentes de ${widget.parentName}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Lista de dependentes vinculados a este responsavel.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE6DFC8)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: 'Buscar dependente',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.trim().isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: asyncChildren.when(
                loading: () => initialItems.isNotEmpty
                    ? _DependentsListView(
                        items: _filterChildren(initialItems),
                        showLoadingBadge: true,
                      )
                    : const Center(child: CircularProgressIndicator()),
                error: (error, _) => initialItems.isNotEmpty
                    ? _DependentsListView(items: _filterChildren(initialItems))
                    : Center(child: Text(error.toString())),
                data: (page) {
                  final items = _filterChildren(page.items);
                  if (items.isEmpty) {
                    return _EmptyPane(
                      message: _query.trim().isEmpty
                          ? 'Nenhum dependente encontrado.'
                          : 'Nenhum dependente encontrado para essa busca.',
                    );
                  }
                  return _DependentsListView(items: items);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _filterChildren(List<Map<String, dynamic>> items) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items
        .where((item) {
          final school = ((item['school'] as Map?)?['name'] ?? '').toString();
          final relative =
              (((item['relative'] as Map?)?['name'] ??
                          (item['relative'] as Map?)?['relative']) ??
                      '')
                  .toString();
          final name = (item['name'] ?? '').toString();
          return '$name $school $relative'.toLowerCase().contains(q);
        })
        .toList(growable: false);
  }
}

class _DependentsListView extends StatelessWidget {
  const _DependentsListView({
    required this.items,
    this.showLoadingBadge = false,
  });

  final List<Map<String, dynamic>> items;
  final bool showLoadingBadge;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showLoadingBadge)
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Chip(label: Text('Atualizando lista...')),
            ),
          ),
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = items[index];
              final school = (item['school'] as Map?)?['name']?.toString();
              final relative =
                  ((item['relative'] as Map?)?['name'] ??
                          (item['relative'] as Map?)?['relative'])
                      ?.toString();
              final shift =
                  ((item['shift'] as Map?)?['shift_name'] ??
                          (item['shift'] as Map?)?['name'])
                      ?.toString();
              final addressesCount = (item['addresses_count'] as num?)?.toInt();
              final avatarUrl = (item['avatar_url'] ?? item['avatar'])
                  ?.toString();

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE7E0CA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFFFF1BE),
                      backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                          ? NetworkImage(avatarUrl)
                          : null,
                      child: avatarUrl == null || avatarUrl.isEmpty
                          ? const Icon(
                              Icons.child_friendly_rounded,
                              color: AppColors.ink,
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (item['name'] ?? 'Sem nome').toString(),
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              if (relative != null && relative.isNotEmpty)
                                _driverInfoPill(
                                  context,
                                  icon: Icons.family_restroom_rounded,
                                  text: relative,
                                ),
                              if (school != null && school.isNotEmpty)
                                _driverInfoPill(
                                  context,
                                  icon: Icons.school_outlined,
                                  text: school,
                                ),
                              if (shift != null && shift.isNotEmpty)
                                _driverInfoPill(
                                  context,
                                  icon: Icons.schedule_rounded,
                                  text: shift,
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            [
                              if ((item['age'] ?? '').toString().isNotEmpty)
                                'Idade: ${item['age']}',
                              if (addressesCount != null)
                                'Enderecos: $addressesCount',
                            ].join(' • '),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.slate),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InadimplencyDraft {
  const _InadimplencyDraft({required this.amount, this.reason});

  final double amount;
  final String? reason;
}

class _InadimplencyEditorSheet extends StatefulWidget {
  const _InadimplencyEditorSheet({
    required this.parentName,
    this.initialAmount,
  });

  final String parentName;
  final double? initialAmount;

  @override
  State<_InadimplencyEditorSheet> createState() =>
      _InadimplencyEditorSheetState();
}

class _InadimplencyEditorSheetState extends State<_InadimplencyEditorSheet> {
  late final TextEditingController _amountController;
  final TextEditingController _reasonController = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount != null && widget.initialAmount! > 0
          ? widget.initialAmount!.toStringAsFixed(2)
          : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Debito do responsavel',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            widget.parentName,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.slate),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5EA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE7DEC6)),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Valor do debito (R\$)',
                    prefixIcon: Icon(Icons.request_quote_outlined),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _reasonController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observacao (opcional)',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Confirmar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() {
    final raw = _amountController.text.trim().replaceAll(',', '.');
    final amount = raw.isEmpty ? 0.0 : double.tryParse(raw);
    if (amount == null || amount < 0) {
      setState(() => _error = 'Valor de debito invalido.');
      return;
    }
    final reason = _reasonController.text.trim();
    Navigator.of(context).pop(
      _InadimplencyDraft(
        amount: amount,
        reason: reason.isEmpty ? null : reason,
      ),
    );
  }
}

class _DriverRoutesTab extends ConsumerWidget {
  const _DriverRoutesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routesAsync = ref.watch(driverRoutesProvider);
    final tracking = ref.watch(driverTrackingControllerProvider);
    return routesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorPane(message: error.toString()),
      data: (page) {
        final visibleRoutes = page.items
            .where((route) {
              final status = (route['status'] ?? '')
                  .toString()
                  .toLowerCase()
                  .trim();
              return status != 'finished' &&
                  status != 'finalized' &&
                  status != 'completed';
            })
            .toList(growable: false);
        return Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: _DriverRouteWorkspacePanel(
                  tracking: tracking,
                  onGenerateRoute: () => _openAdhocPlanner(context, ref),
                  onRoutesChanged: () => ref.invalidate(driverRoutesProvider),
                  expandMapStage: true,
                ),
              ),
            ),
            if (!tracking.routeActive) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: visibleRoutes.isEmpty ? 120 : 240,
                child: visibleRoutes.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const _EmptyPane(
                                message: 'Nenhuma rota encontrada.',
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () =>
                                    _openAdhocPlanner(context, ref),
                                icon: const Icon(Icons.route_rounded),
                                label: const Text('Gerar rota'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        itemCount: visibleRoutes.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final route = visibleRoutes[index];
                          final routeId = (route['id'] as num?)?.toInt() ?? 0;
                          final status = (route['status'] ?? 'N/A').toString();
                          final boardingsCount = (route['boardings_count'] ?? 0)
                              .toString();
                          final activeManifest =
                              (route['active_manifest'] as Map?) ?? const {};
                          final activeManifestId = activeManifest['id']
                              ?.toString();
                          final isTrackingThisRoute =
                              tracking.routeActive &&
                              tracking.routeId == routeId;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (route['name'] ?? 'Rota #$routeId')
                                        .toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: $status • Embarques: $boardingsCount',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.slate),
                                  ),
                                  const SizedBox(height: 10),
                                  if (activeManifestId != null &&
                                      activeManifestId.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(
                                        'Manifesto ativo: $activeManifestId',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: AppColors.slate),
                                      ),
                                    ),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      FilledButton.tonalIcon(
                                        onPressed: routeId <= 0
                                            ? null
                                            : () => _handleRouteAction(
                                                context,
                                                ref,
                                                route,
                                                true,
                                              ),
                                        icon: const Icon(
                                          Icons.play_arrow_rounded,
                                        ),
                                        label: const Text('Iniciar'),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed:
                                            routeId <= 0 ||
                                                !isTrackingThisRoute &&
                                                    status != 'in_progress'
                                            ? null
                                            : () => _handleRouteAction(
                                                context,
                                                ref,
                                                route,
                                                false,
                                              ),
                                        icon: const Icon(Icons.stop_rounded),
                                        label: const Text('Finalizar'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ],
        );
      },
    );
  }

  Future<void> _openAdhocPlanner(BuildContext context, WidgetRef ref) async {
    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessao expirada. Faca login novamente.')),
      );
      return;
    }

    final repo = ref.read(driverPortalRepositoryProvider);
    final optionsFuture = repo.routePlanningOptions(
      session.authorizationHeader,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => FutureBuilder<Map<String, dynamic>>(
        future: optionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                snapshot.error.toString(),
                textAlign: TextAlign.center,
              ),
            );
          }
          final data = snapshot.data ?? const <String, dynamic>{};
          return _AdhocRoutePlannerSheet(
            data: data,
            onStart: (payload) async {
              double? originLat;
              double? originLng;
              try {
                final position = await Geolocator.getCurrentPosition();
                originLat = position.latitude;
                originLng = position.longitude;
              } catch (_) {
                // Se não conseguir fix imediato, o tracking recalcula logo após iniciar.
              }

              final response = await repo.startAdhocRoute(
                session.authorizationHeader,
                shiftId: payload.shiftId,
                tripMode: payload.tripModeId,
                operationId: payload.operationId,
                routeName: payload.routeName,
                originLat: originLat,
                originLng: originLng,
                selections: payload.selections,
              );

              if (!context.mounted) return;
              await _startTrackingFromResponse(context, ref, response);
              if (!context.mounted) return;
              ref.invalidate(driverRoutesProvider);
            },
          );
        },
      ),
    );
  }

  Future<void> _handleRouteAction(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> route,
    bool start,
  ) async {
    try {
      final routeId = (route['id'] as num?)?.toInt() ?? 0;
      if (routeId <= 0) {
        throw ApiException(message: 'Rota invalida.');
      }
      final session = ref.read(appSessionControllerProvider).session;
      if (session == null) {
        throw ApiException(message: 'Sessao expirada. Faca login novamente.');
      }
      final auth = session.authorizationHeader;
      final repo = ref.read(driverPortalRepositoryProvider);
      final trackingController = ref.read(
        driverTrackingControllerProvider.notifier,
      );
      if (start) {
        final vanId = session.user.id;

        final response = await repo.startRoute(auth, routeId, vanId: vanId);
        if (!context.mounted) return;
        await _startTrackingFromResponse(
          context,
          ref,
          response,
          fallbackRouteId: routeId,
        );
        if (!context.mounted) return;
      } else {
        await repo.finishRoute(auth, routeId);
        await trackingController.stopRouteTracking(silent: true);
      }
      ref.invalidate(driverRoutesProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(start ? 'Rota iniciada.' : 'Rota finalizada.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _startTrackingFromResponse(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> response, {
    int? fallbackRouteId,
  }) async {
    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) {
      throw ApiException(message: 'Sessao expirada. Faca login novamente.');
    }
    final routeMap =
        (response['route'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final routeManifest =
        (response['route_manifest'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final routing =
        (response['routing'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};

    final routeId = (routeMap['id'] as num?)?.toInt() ?? fallbackRouteId ?? 0;
    final manifestId = routeManifest['id']?.toString();
    final manifestVanId = (routeManifest['van_id'] as num?)?.toInt();

    if (routeId <= 0 || manifestId == null || manifestId.isEmpty) {
      throw ApiException(
        message:
            'Backend nao retornou dados suficientes para iniciar o rastreamento.',
      );
    }

    if (manifestVanId == null || manifestVanId <= 0) {
      throw ApiException(message: 'Van ID invalido retornado pelo backend.');
    }

    final trackingController = ref.read(
      driverTrackingControllerProvider.notifier,
    );
    final trackingStarted = await trackingController.startRouteTracking(
      session: session,
      routeId: routeId,
      routeManifestId: manifestId,
      vanId: manifestVanId,
      deviationDistanceMeters:
          (routing['deviation_distance_meters'] as num?)?.toInt() ?? 100,
      deviationSustainSeconds:
          (routing['deviation_sustain_seconds'] as num?)?.toInt() ?? 10,
      deviationDebounceSeconds:
          (routing['deviation_debounce_seconds'] as num?)?.toInt() ?? 30,
    );
    if (!trackingStarted) {
      throw ApiException(
        message:
            'Nao foi possivel iniciar o rastreamento. Verifique as permissoes do aparelho.',
      );
    }

    final routePreview =
        (response['route_preview'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final manifestMeta =
        (routeManifest['meta'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final optimizedStops =
        ((manifestMeta['optimized_stops'] as List?) ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);

    trackingController.primeRoutePreview(
      remainingStops: optimizedStops,
      geometry: routePreview['geometry'] is Map
          ? Map<String, dynamic>.from(routePreview['geometry'] as Map)
          : null,
      distanceMeters: (routePreview['distance_meters'] as num?)?.toDouble(),
      durationSeconds: (routePreview['duration_seconds'] as num?)?.toInt(),
    );
  }
}

class _DriverLiveRouteMap extends StatefulWidget {
  const _DriverLiveRouteMap({required this.tracking, this.fillHeight = false});

  final DriverTrackingState tracking;
  final bool fillHeight;

  @override
  State<_DriverLiveRouteMap> createState() => _DriverLiveRouteMapState();
}

class _DriverLiveRouteMapState extends State<_DriverLiveRouteMap> {
  MapLibreMapController? _mapController;
  bool _mapReady = false;

  static const _styleUrl = 'https://tiles.openfreemap.org/styles/liberty';
  static const _defaultCenter = LatLng(-25.5401, -54.5854);

  @override
  void didUpdateWidget(covariant _DriverLiveRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_mapReady) _syncMap();
  }

  Future<void> _syncMap() async {
    final ctrl = _mapController;
    if (ctrl == null || !_mapReady) return;
    final t = widget.tracking;

    await ctrl.clearLines();
    await ctrl.clearCircles();

    final hasGps = t.lastLatitude != null && t.lastLongitude != null;
    final current = hasGps ? LatLng(t.lastLatitude!, t.lastLongitude!) : null;
    final poly = t.routePolyline.map((p) => LatLng(p.lat, p.lng)).toList();
    final stops = t.routeRemainingStops;
    final fallbackPoly = <LatLng>[
      ?current,
      ...stops.map((s) => LatLng(s.lat, s.lng)),
    ];
    final displayPoly = poly.length >= 2 ? poly : fallbackPoly;
    final usingApprox = poly.length < 2 && fallbackPoly.length >= 2;

    if (displayPoly.length >= 2) {
      await ctrl.addLine(
        LineOptions(
          geometry: displayPoly,
          lineColor: '#222222',
          lineWidth: 7.5,
          lineOpacity: 0.22,
          lineJoin: 'round',
        ),
      );
      await ctrl.addLine(
        LineOptions(
          geometry: displayPoly,
          lineColor: usingApprox ? '#64B5F6' : '#FFC107',
          lineWidth: 4.5,
          lineOpacity: 1.0,
          lineJoin: 'round',
        ),
      );
    }

    for (final s in stops) {
      await ctrl.addCircle(
        CircleOptions(
          geometry: LatLng(s.lat, s.lng),
          circleRadius: 8.0,
          circleColor: '#FFFFFF',
          circleStrokeColor: '#B00020',
          circleStrokeWidth: 2.5,
        ),
      );
    }

    if (current != null) {
      await ctrl.addCircle(
        CircleOptions(
          geometry: current,
          circleRadius: 13.0,
          circleColor: '#FFD54F',
          circleStrokeColor: '#111111',
          circleStrokeWidth: 2.5,
        ),
      );
    }

    _reframeCamera();
  }

  void _reframeCamera() {
    final ctrl = _mapController;
    if (ctrl == null || !_mapReady) return;
    final metrics = _RouteMapMetrics.fromTracking(widget.tracking);
    ctrl.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: metrics.center, zoom: metrics.zoom),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tracking;
    final hasGps = t.lastLatitude != null && t.lastLongitude != null;
    final poly = t.routePolyline.map((p) => LatLng(p.lat, p.lng)).toList();
    final hasPolyline = poly.length >= 2;
    final usingApprox = !hasPolyline && t.routeRemainingStops.isNotEmpty;
    final mapHeight = widget.fillHeight ? null : 320.0;
    final borderRadius = widget.fillHeight
        ? BorderRadius.zero
        : BorderRadius.circular(14);

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        height: mapHeight,
        child: Stack(
          children: [
            MapLibreMap(
              styleString: _styleUrl,
              initialCameraPosition: CameraPosition(
                target: hasGps
                    ? LatLng(t.lastLatitude!, t.lastLongitude!)
                    : _defaultCenter,
                zoom: 14.0,
              ),
              onMapCreated: (c) => _mapController = c,
              onStyleLoadedCallback: () {
                _mapReady = true;
                _syncMap();
              },
              compassEnabled: false,
              myLocationEnabled: false,
              tiltGesturesEnabled: false,
              scrollGesturesEnabled: true,
              zoomGesturesEnabled: true,
              rotateGesturesEnabled: true,
            ),
            Positioned(
              left: 10,
              top: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    hasPolyline
                        ? (usingApprox
                              ? 'Rota aproximada'
                              : 'Rota em tempo real')
                        : 'Aguardando GPS...',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: Column(
                children: [
                  _MapControlButton(
                    icon: Icons.add_rounded,
                    onPressed: !_mapReady
                        ? null
                        : () => _mapController?.animateCamera(
                            CameraUpdate.zoomIn(),
                          ),
                  ),
                  const SizedBox(height: 8),
                  _MapControlButton(
                    icon: Icons.remove_rounded,
                    onPressed: !_mapReady
                        ? null
                        : () => _mapController?.animateCamera(
                            CameraUpdate.zoomOut(),
                          ),
                  ),
                  const SizedBox(height: 8),
                  _MapControlButton(
                    icon: Icons.my_location_rounded,
                    onPressed: _mapReady ? _reframeCamera : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: AppColors.ink),
        ),
      ),
    );
  }
}

class _RouteMapMetrics {
  const _RouteMapMetrics({required this.center, required this.zoom});

  final LatLng center;
  final double zoom;

  factory _RouteMapMetrics.fromTracking(DriverTrackingState tracking) {
    final current =
        (tracking.lastLatitude != null && tracking.lastLongitude != null)
        ? LatLng(tracking.lastLatitude!, tracking.lastLongitude!)
        : null;
    final routePolyline = tracking.routePolyline
        .map((p) => LatLng(p.lat, p.lng))
        .toList(growable: false);
    final stops = tracking.routeRemainingStops;
    final fallbackPolyline = <LatLng>[
      ?current,
      ...stops.map((s) => LatLng(s.lat, s.lng)),
    ];
    final displayPolyline = routePolyline.length >= 2
        ? routePolyline
        : fallbackPolyline;
    final hasPolyline = displayPolyline.length >= 2;
    final allPoints = <LatLng>[
      ?current,
      ...displayPolyline,
      ...stops.map((s) => LatLng(s.lat, s.lng)),
    ];
    final center =
        _averageLatLng(allPoints) ??
        current ??
        const LatLng(-25.5401, -54.5854);
    final zoom = hasPolyline ? 13.4 : 16.2;
    return _RouteMapMetrics(center: center, zoom: zoom);
  }
}

class _DriverRouteWorkspacePanel extends ConsumerStatefulWidget {
  const _DriverRouteWorkspacePanel({
    required this.tracking,
    required this.onGenerateRoute,
    required this.onRoutesChanged,
    this.expandMapStage = false,
  });

  final DriverTrackingState tracking;
  final VoidCallback onGenerateRoute;
  final VoidCallback onRoutesChanged;
  final bool expandMapStage;

  @override
  ConsumerState<_DriverRouteWorkspacePanel> createState() =>
      _DriverRouteWorkspacePanelState();
}

class _DriverRouteWorkspacePanelState
    extends ConsumerState<_DriverRouteWorkspacePanel> {
  int _viewIndex = 1; // 0 resumo, 1 mapa, 2 alunos
  bool _submittingStopAction = false;

  @override
  Widget build(BuildContext context) {
    final tracking = widget.tracking;
    final hasGps =
        tracking.lastLatitude != null && tracking.lastLongitude != null;
    final hasRouteVisual =
        tracking.routePolyline.length >= 2 ||
        tracking.routeRemainingStops.isNotEmpty ||
        ((tracking.routeDistanceMeters ?? 0) > 0);
    final canShowMap = hasGps || hasRouteVisual;

    final mapWidget = canShowMap
        ? _DriverLiveRouteMap(
            tracking: tracking,
            fillHeight: widget.expandMapStage,
          )
        : Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6FB),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                tracking.routeActive
                    ? 'Aguardando primeiro GPS/rota...'
                    : 'Toque em "Gerar rota" para selecionar o momento da operacao e iniciar o rastreamento.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.slate),
              ),
            ),
          );

    final mapStage = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Positioned.fill(child: mapWidget),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Row(
              children: [
                Expanded(
                  child: _mapOverlayChip(
                    context,
                    tracking.routeActive
                        ? (tracking.foregroundStreaming
                              ? 'Rastreamento ativo'
                              : 'Rastreamento em fallback')
                        : 'Mapa do motorista',
                    icon: tracking.routeActive
                        ? Icons.gps_fixed_rounded
                        : Icons.map_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                _mapOverlayChip(
                  context,
                  tracking.socketConnected ? 'Socket ON' : 'Socket OFF',
                  icon: tracking.socketConnected
                      ? Icons.wifi_tethering_rounded
                      : Icons.portable_wifi_off_rounded,
                ),
              ],
            ),
          ),
          Positioned(
            top: 60,
            right: 10,
            child: Column(
              children: [
                _mapActionFab(
                  context,
                  icon: Icons.alt_route_rounded,
                  tooltip: tracking.routeActive
                      ? 'Gerar nova rota'
                      : 'Gerar rota',
                  onTap: widget.onGenerateRoute,
                  highlighted: true,
                ),
                const SizedBox(height: 8),
                _mapActionFab(
                  context,
                  icon: Icons.stop_circle_outlined,
                  tooltip: 'Finalizar rota',
                  onTap: tracking.routeActive
                      ? () => _finishActiveRoute(context)
                      : null,
                ),
              ],
            ),
          ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xF7FFFFFF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF0E6BF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1BE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tracking.routeActive
                              ? 'Manifesto: ${tracking.routeManifestId ?? '-'}'
                              : 'Sem rota ativa',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tracking.routeActive
                        ? 'Buffer: ${tracking.pendingBufferCount} ponto(s)'
                        : 'A rota será calculada usando sua localizacao atual como origem.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
                  ),
                  if (tracking.routeActive &&
                      (tracking.routeEtaSeconds != null ||
                          tracking.routeDistanceMeters != null ||
                          (tracking.routeNextStopName ?? '')
                              .trim()
                              .isNotEmpty)) ...[
                    const SizedBox(height: 6),
                    Text(
                      [
                        if (tracking.routeEtaSeconds != null)
                          'ETA ${_formatEta(tracking.routeEtaSeconds!)}',
                        if (tracking.routeDistanceMeters != null)
                          _formatDistance(tracking.routeDistanceMeters!),
                        if ((tracking.routeNextStopName ?? '')
                            .trim()
                            .isNotEmpty)
                          'Proxima: ${tracking.routeNextStopName}',
                      ].join(' • '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF0A5D52),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  if (tracking.routePreviewUpdatedAt != null)
                    Text(
                      'Atualizada: ${_formatTime(tracking.routePreviewUpdatedAt!)}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
                    ),
                  if (tracking.routeActive && !hasRouteVisual)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Aguardando rota calculada pela API.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
                      ),
                    ),
                  if (tracking.warning != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        tracking.warning!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  if (tracking.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        tracking.error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    // Full-screen Google Maps-like layout when on map tab in expanded mode
    if (_viewIndex == 1 && widget.expandMapStage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(child: mapWidget),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  Expanded(
                    child: _mapOverlayChip(
                      context,
                      tracking.routeActive
                          ? (tracking.foregroundStreaming
                                ? 'Rastreamento ativo'
                                : 'Rastreamento em fallback')
                          : 'Mapa do motorista',
                      icon: tracking.routeActive
                          ? Icons.gps_fixed_rounded
                          : Icons.map_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _mapOverlayChip(
                    context,
                    tracking.socketConnected ? 'Socket ON' : 'Socket OFF',
                    icon: tracking.socketConnected
                        ? Icons.wifi_tethering_rounded
                        : Icons.portable_wifi_off_rounded,
                  ),
                ],
              ),
            ),
            Positioned(
              top: 60,
              right: 10,
              child: Column(
                children: [
                  _mapActionFab(
                    context,
                    icon: Icons.alt_route_rounded,
                    tooltip: tracking.routeActive
                        ? 'Gerar nova rota'
                        : 'Gerar rota',
                    onTap: widget.onGenerateRoute,
                    highlighted: true,
                  ),
                  const SizedBox(height: 8),
                  _mapActionFab(
                    context,
                    icon: Icons.stop_circle_outlined,
                    tooltip: 'Finalizar rota',
                    onTap: tracking.routeActive
                        ? () => _finishActiveRoute(context)
                        : null,
                  ),
                ],
              ),
            ),
            Positioned(
              left: 10,
              right: 10,
              bottom: 76,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xF7FFFFFF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFF0E6BF)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: _buildRouteInfoPanelContent(context, tracking),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildWorkspaceFloatingDock(context, tracking),
            ),
          ],
        ),
      );
    }

    final summaryTab = _buildSummaryTab(context, tracking);
    final studentsTab = _buildStudentsTab(context, tracking);

    final body = switch (_viewIndex) {
      0 => summaryTab, // _buildSummaryTab already returns its own Expanded
      1 => Expanded(child: mapStage),
      2 => Expanded(child: studentsTab),
      _ => summaryTab,
    };

    final shell = Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EFE2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE6D8AB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            // Reserve the full floating-dock height (~76px) so tab content —
            // notably the board/disembark buttons — never sits under the dock.
            padding: const EdgeInsets.only(bottom: 78),
            child: Column(
              children: [
                _buildWorkspaceStatusHeader(context, tracking),
                const SizedBox(height: 8),
                body,
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildWorkspaceFloatingDock(context, tracking),
          ),
        ],
      ),
    );

    if (widget.expandMapStage) {
      return shell;
    }
    // Responsive height so the board/disembark (Students) list gets enough
    // room and its action buttons aren't clipped behind the floating dock.
    final panelHeight = (MediaQuery.sizeOf(context).height * 0.52).clamp(
      360.0,
      560.0,
    );
    return SizedBox(height: panelHeight, child: shell);
  }

  Widget _buildRouteInfoPanelContent(
    BuildContext context,
    DriverTrackingState tracking,
  ) {
    final hasRouteVisual =
        tracking.routePolyline.length >= 2 ||
        tracking.routeRemainingStops.isNotEmpty ||
        ((tracking.routeDistanceMeters ?? 0) > 0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1BE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tracking.routeActive
                    ? 'Manifesto: ${tracking.routeManifestId ?? '-'}'
                    : 'Sem rota ativa',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          tracking.routeActive
              ? 'Buffer: ${tracking.pendingBufferCount} ponto(s)'
              : 'A rota sera calculada usando sua localizacao atual como origem.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
        ),
        if (tracking.routeActive &&
            (tracking.routeEtaSeconds != null ||
                tracking.routeDistanceMeters != null ||
                (tracking.routeNextStopName ?? '').trim().isNotEmpty)) ...[
          const SizedBox(height: 6),
          Text(
            [
              if (tracking.routeEtaSeconds != null)
                'ETA ${_formatEta(tracking.routeEtaSeconds!)}',
              if (tracking.routeDistanceMeters != null)
                _formatDistance(tracking.routeDistanceMeters!),
              if ((tracking.routeNextStopName ?? '').trim().isNotEmpty)
                'Proxima: ${tracking.routeNextStopName}',
            ].join(' • '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF0A5D52),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        if (tracking.routePreviewUpdatedAt != null)
          Text(
            'Atualizada: ${_formatTime(tracking.routePreviewUpdatedAt!)}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
          ),
        if (tracking.routeActive && !hasRouteVisual)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Aguardando rota calculada pela API.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
            ),
          ),
        if (tracking.warning != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              tracking.warning!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.orange.shade900),
            ),
          ),
        if (tracking.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              tracking.error!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
            ),
          ),
      ],
    );
  }

  Widget _buildWorkspaceStatusHeader(
    BuildContext context,
    DriverTrackingState tracking,
  ) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8DFC4)),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1BE),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.directions_bus_filled_rounded,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tracking.routeActive
                            ? 'Operacao em andamento'
                            : 'Painel de rotas',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        tracking.routeActive
                            ? (tracking.routeNextStopName?.trim().isNotEmpty ==
                                      true
                                  ? 'Proxima parada: ${tracking.routeNextStopName}'
                                  : 'Acompanhando GPS e manifesto em tempo real')
                            : 'Gere uma rota para iniciar o rastreamento.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _mapOverlayChip(
          context,
          tracking.routeActive ? 'Ao vivo' : 'Pronto',
          icon: tracking.routeActive
              ? Icons.radio_button_checked_rounded
              : Icons.check_circle_outline_rounded,
        ),
      ],
    );
  }

  Widget _buildWorkspaceFloatingDock(
    BuildContext context,
    DriverTrackingState tracking,
  ) {
    final items = const [
      (label: 'Resumo', icon: Icons.summarize_outlined),
      (label: 'Mapa', icon: Icons.map_outlined),
      (label: 'Alunos', icon: Icons.groups_2_outlined),
      (label: 'Config', icon: Icons.tune_rounded),
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xF7FFFFFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFE6DFC7)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i == items.length - 1 ? 0 : 6,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () {
                      if (i == 3) {
                        widget.onGenerateRoute();
                        return;
                      }
                      setState(() => _viewIndex = i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: i == 3
                            ? const Color(0xFFF4EFE0)
                            : _viewIndex == i
                            ? const Color(0xFF103A66)
                            : const Color(0xFFF8F7F2),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: i == 3
                              ? const Color(0xFFE7DDC0)
                              : _viewIndex == i
                              ? const Color(0xFF103A66)
                              : const Color(0xFFE5DFC9),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            items[i].icon,
                            size: 18,
                            color: i == 3
                                ? AppColors.ink
                                : _viewIndex == i
                                ? Colors.white
                                : AppColors.slate,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            i == 3 ? 'Gerar' : items[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: i == 3
                                      ? AppColors.ink
                                      : _viewIndex == i
                                      ? Colors.white
                                      : AppColors.ink,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab(BuildContext context, DriverTrackingState tracking) {
    final plannedStudents = _studentRouteCards(tracking);
    final nextLabel = plannedStudents.firstWhere(
      (s) => s.status == _StudentRouteStatus.onTheWay,
      orElse: () => plannedStudents.firstWhere(
        (s) => s.status == _StudentRouteStatus.pending,
        orElse: () => plannedStudents.isNotEmpty
            ? plannedStudents.first
            : _StudentRouteCard.empty,
      ),
    );
    final activeCount = plannedStudents
        .where((s) => s.status != _StudentRouteStatus.droppedOff)
        .length;

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _summaryMetricsGrid(
              context,
              tracking: tracking,
              studentCount: plannedStudents.length,
              activeCount: activeCount,
              nextStopName: tracking.routeNextStopName ?? nextLabel.name,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: widget.onGenerateRoute,
                  icon: const Icon(Icons.alt_route_rounded),
                  label: Text(
                    tracking.routeActive ? 'Gerar nova rota' : 'Gerar rota',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: tracking.routeActive
                      ? () => _finishActiveRoute(context)
                      : null,
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: const Text('Finalizar rota'),
                ),
              ],
            ),
            if (tracking.warning != null) ...[
              const SizedBox(height: 8),
              Text(
                tracking.warning!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.orange.shade900),
              ),
            ],
            if (tracking.error != null) ...[
              const SizedBox(height: 4),
              Text(
                tracking.error!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.red.shade700),
              ),
            ],
            if (plannedStudents.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Sequencia da rota',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              ...plannedStudents.map(
                (student) => _studentSequenceTile(context, student),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsTab(BuildContext context, DriverTrackingState tracking) {
    final students = _studentRouteCards(tracking);
    if (students.isEmpty) {
      return const Center(child: Text('Nenhum aluno na rota atual.'));
    }

    return ListView.separated(
      // Reserve space for the floating dock so the last student's
      // Embarcou/Desembarcou buttons stay visible and tappable.
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      itemCount: students.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final student = students[index];
        final statusLabel = switch (student.status) {
          _StudentRouteStatus.onTheWay => 'A caminho',
          _StudentRouteStatus.boarded => 'Embarcado',
          _StudentRouteStatus.droppedOff => 'Desembarcado',
          _StudentRouteStatus.pending => 'Pendente',
        };
        final statusColor = switch (student.status) {
          _StudentRouteStatus.onTheWay => const Color(0xFF1565C0),
          _StudentRouteStatus.boarded => const Color(0xFF0A7E52),
          _StudentRouteStatus.droppedOff => const Color(0xFF616161),
          _StudentRouteStatus.pending => AppColors.slate,
        };

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE4DECA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      student.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      statusLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if ((student.nextActionLabel ?? '').isNotEmpty)
                Text(
                  'Proxima acao: ${student.nextActionLabel}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
                ),
              if (student.pickupAddressLabel != null ||
                  student.dropoffLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  [
                    if (student.pickupAddressLabel != null)
                      'Embarque: ${student.pickupAddressLabel}',
                    if (student.dropoffLabel != null)
                      'Destino: ${student.dropoffLabel}',
                  ].join(' • '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonal(
                    onPressed:
                        _submittingStopAction ||
                            !tracking.routeActive ||
                            student.clientId == null ||
                            student.status != _StudentRouteStatus.onTheWay &&
                                student.status != _StudentRouteStatus.pending
                        ? null
                        : () => _markStudentBoarded(context, student.clientId!),
                    child: const Text('Embarcou'),
                  ),
                  OutlinedButton(
                    onPressed:
                        _submittingStopAction ||
                            !tracking.routeActive ||
                            student.clientId == null ||
                            student.status != _StudentRouteStatus.boarded
                        ? null
                        : () => _markStudentDisembarked(
                            context,
                            student.clientId!,
                          ),
                    child: const Text('Desembarcou'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryMetricsGrid(
    BuildContext context, {
    required DriverTrackingState tracking,
    required int studentCount,
    required int activeCount,
    required String? nextStopName,
  }) {
    Widget card(String title, String value) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4DECA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.slate),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: card('Alunos', '$studentCount')),
            const SizedBox(width: 8),
            Expanded(child: card('Restantes', '$activeCount')),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: card(
                'ETA',
                tracking.routeEtaSeconds != null
                    ? _formatEta(tracking.routeEtaSeconds!)
                    : '--',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: card(
                'Distancia',
                tracking.routeDistanceMeters != null
                    ? _formatDistance(tracking.routeDistanceMeters!)
                    : '--',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        card(
          'Proxima parada',
          (nextStopName ?? '').trim().isEmpty ? '--' : nextStopName!,
        ),
      ],
    );
  }

  Widget _studentSequenceTile(BuildContext context, _StudentRouteCard student) {
    final prefix = student.sequence != null ? '${student.sequence}. ' : '';
    final color = switch (student.status) {
      _StudentRouteStatus.onTheWay => const Color(0xFF1565C0),
      _StudentRouteStatus.boarded => const Color(0xFF0A7E52),
      _StudentRouteStatus.droppedOff => AppColors.slate,
      _StudentRouteStatus.pending => AppColors.ink,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$prefix${student.name} • ${switch (student.status) {
          _StudentRouteStatus.onTheWay => 'a caminho',
          _StudentRouteStatus.boarded => 'embarcado',
          _StudentRouteStatus.droppedOff => 'desembarcado',
          _StudentRouteStatus.pending => 'pendente',
        }}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  List<_StudentRouteCard> _studentRouteCards(DriverTrackingState tracking) {
    final plannedStops = tracking.routePlannedStops;
    if (plannedStops.isEmpty) {
      return const [];
    }

    final nextPendingKey = tracking.routeRemainingStops.isNotEmpty
        ? _studentKeyFromStop(tracking.routeRemainingStops.first)
        : null;

    final grouped = <String, List<DriverTrackingStopPoint>>{};
    for (final stop in plannedStops) {
      final clientId = stop.clientId;
      if (clientId == null || clientId <= 0) continue;
      final key = _studentKeyFromStop(stop);
      grouped.putIfAbsent(key, () => <DriverTrackingStopPoint>[]).add(stop);
    }

    final result = <_StudentRouteCard>[];
    for (final entry in grouped.entries) {
      final stops = [
        ...entry.value,
      ]..sort((a, b) => (a.sequence ?? 999999).compareTo(b.sequence ?? 999999));
      final pickup = stops
          .where((s) => (s.type ?? '').startsWith('pickup'))
          .cast<DriverTrackingStopPoint?>()
          .firstWhere((_) => true, orElse: () => null);
      final dropoff = stops
          .where((s) => (s.type ?? '').startsWith('dropoff'))
          .cast<DriverTrackingStopPoint?>()
          .firstWhere((_) => true, orElse: () => null);
      final anyDelivered = stops.any(
        (s) => s.status.toLowerCase() == 'delivered',
      );
      final anyPickedUp = stops.any(
        (s) => s.status.toLowerCase() == 'picked_up',
      );
      final status = anyDelivered
          ? _StudentRouteStatus.droppedOff
          : anyPickedUp
          ? _StudentRouteStatus.boarded
          : (entry.key == nextPendingKey
                ? _StudentRouteStatus.onTheWay
                : _StudentRouteStatus.pending);

      result.add(
        _StudentRouteCard(
          clientId: stops.first.clientId,
          childId: stops.first.childId,
          name: stops.first.name ?? 'Aluno',
          sequence: stops.first.sequence,
          status: status,
          pickupAddressLabel: pickup?.name,
          dropoffLabel: dropoff?.name,
          nextActionLabel: switch (status) {
            _StudentRouteStatus.onTheWay ||
            _StudentRouteStatus.pending => 'Coletar aluno',
            _StudentRouteStatus.boarded => 'Levar ao destino',
            _StudentRouteStatus.droppedOff => 'Concluido',
          },
        ),
      );
    }

    result.sort(
      (a, b) => (a.sequence ?? 999999).compareTo(b.sequence ?? 999999),
    );
    return result;
  }

  String _studentKeyFromStop(DriverTrackingStopPoint stop) {
    if ((stop.clientId ?? 0) > 0) {
      return 'c:${stop.clientId}';
    }
    if ((stop.childId ?? 0) > 0) {
      return 'ch:${stop.childId}';
    }
    return 's:${stop.id ?? stop.name ?? stop.sequence ?? ''}';
  }

  Future<void> _finishActiveRoute(BuildContext context) async {
    final routeId = widget.tracking.routeId;
    if (routeId == null || routeId <= 0) return;
    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) return;
    final repo = ref.read(driverPortalRepositoryProvider);
    final trackingController = ref.read(
      driverTrackingControllerProvider.notifier,
    );
    try {
      await repo.finishRoute(session.authorizationHeader, routeId);
      await trackingController.stopRouteTracking(silent: true);
      widget.onRoutesChanged();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rota finalizada.')));
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _markStudentBoarded(BuildContext context, int clientId) async {
    await _runStopAction(
      context,
      clientId: clientId,
      apiCall: (repo, auth, routeId) =>
          repo.markBoarding(auth, routeId, clientId: clientId),
      onSuccessLocal: (trackingController) =>
          trackingController.markClientBoardedLocal(clientId),
      successMessage: 'Aluno marcado como embarcado.',
    );
  }

  Future<void> _markStudentDisembarked(
    BuildContext context,
    int clientId,
  ) async {
    await _runStopAction(
      context,
      clientId: clientId,
      apiCall: (repo, auth, routeId) =>
          repo.markDisembarking(auth, routeId, clientId: clientId),
      onSuccessLocal: (trackingController) =>
          trackingController.markClientDisembarkedLocal(clientId),
      successMessage: 'Aluno marcado como desembarcado.',
    );
  }

  Future<void> _runStopAction(
    BuildContext context, {
    required int clientId,
    required Future<Map<String, dynamic>> Function(
      DriverPortalRepository repo,
      String authHeader,
      int routeId,
    )
    apiCall,
    required void Function(DriverTrackingController trackingController)
    onSuccessLocal,
    required String successMessage,
  }) async {
    if (_submittingStopAction) return;
    final routeId = widget.tracking.routeId;
    final session = ref.read(appSessionControllerProvider).session;
    if (routeId == null || routeId <= 0 || session == null) return;
    final repo = ref.read(driverPortalRepositoryProvider);
    final trackingController = ref.read(
      driverTrackingControllerProvider.notifier,
    );

    setState(() => _submittingStopAction = true);
    try {
      await apiCall(repo, session.authorizationHeader, routeId);
      onSuccessLocal(trackingController);
      await trackingController.refreshRoutePreviewNow();
      widget.onRoutesChanged();
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (context.mounted) {
        setState(() => _submittingStopAction = false);
      }
    }
  }
}

enum _StudentRouteStatus { pending, onTheWay, boarded, droppedOff }

class _StudentRouteCard {
  const _StudentRouteCard({
    required this.clientId,
    required this.childId,
    required this.name,
    required this.sequence,
    required this.status,
    this.pickupAddressLabel,
    this.dropoffLabel,
    this.nextActionLabel,
  });

  final int? clientId;
  final int? childId;
  final String name;
  final int? sequence;
  final _StudentRouteStatus status;
  final String? pickupAddressLabel;
  final String? dropoffLabel;
  final String? nextActionLabel;

  static const empty = _StudentRouteCard(
    clientId: null,
    childId: null,
    name: '--',
    sequence: null,
    status: _StudentRouteStatus.pending,
  );
}

Widget _mapOverlayChip(BuildContext context, String text, {IconData? icon}) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(999),
      boxShadow: const [
        BoxShadow(
          color: Color(0x18000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.ink),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

Widget _mapActionFab(
  BuildContext context, {
  required IconData icon,
  required String tooltip,
  required VoidCallback? onTap,
  bool highlighted = false,
}) {
  final bg = highlighted ? const Color(0xFF103A66) : const Color(0xF7FFFFFF);
  final fg = highlighted ? Colors.white : AppColors.ink;

  return Tooltip(
    message: tooltip,
    child: Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      elevation: highlighted ? 3 : 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(width: 46, height: 46, child: Icon(icon, color: fg)),
      ),
    ),
  );
}

LatLng? _averageLatLng(List<LatLng> points) {
  if (points.isEmpty) return null;
  var lat = 0.0;
  var lng = 0.0;
  for (final p in points) {
    lat += p.latitude;
    lng += p.longitude;
  }
  return LatLng(lat / points.length, lng / points.length);
}

class _AdhocRoutePlannerSheet extends StatefulWidget {
  const _AdhocRoutePlannerSheet({required this.data, required this.onStart});

  final Map<String, dynamic> data;
  final Future<void> Function(_RoutePlannerSubmitPayload payload) onStart;

  @override
  State<_AdhocRoutePlannerSheet> createState() =>
      _AdhocRoutePlannerSheetState();
}

class _AdhocRoutePlannerSheetState extends State<_AdhocRoutePlannerSheet> {
  final _routeNameController = TextEditingController();
  bool _submitting = false;
  String? _error;
  String? _selectedOperationId;
  final Map<int, bool> _selectedByChild = {};
  final Map<int, int> _addressByChild = {};

  @override
  void dispose() {
    _routeNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final operationWindows =
        ((widget.data['operation_windows'] as List?) ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList(growable: false);
    final tripModes = ((widget.data['trip_modes'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
    final students = ((widget.data['students'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);

    if (_selectedOperationId == null ||
        !operationWindows.any(
          (item) => (item['id']?.toString() ?? '') == _selectedOperationId,
        )) {
      _selectedOperationId = operationWindows.isNotEmpty
          ? operationWindows.first['id']?.toString()
          : null;
    }

    final selectedOperationId = _selectedOperationId;
    final selectedOperation = operationWindows
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (item) => (item?['id']?.toString() ?? '') == selectedOperationId,
          orElse: () => null,
        );

    final filteredStudents = students
        .where((item) {
          if (selectedOperationId == null || selectedOperationId.isEmpty) {
            return true;
          }
          final ids = ((item['operation_window_ids'] as List?) ?? const [])
              .map((e) => e.toString())
              .toSet();
          return ids.contains(selectedOperationId);
        })
        .toList(growable: false);

    filteredStudents.sort((a, b) {
      final aShift = (a['shift_name'] ?? '').toString();
      final bShift = (b['shift_name'] ?? '').toString();
      if (aShift != bShift) return aShift.compareTo(bShift);
      final aBoard = (a['boarding_time'] ?? '99:99:99').toString();
      final bBoard = (b['boarding_time'] ?? '99:99:99').toString();
      if (aBoard != bBoard) return aBoard.compareTo(bBoard);
      return (a['child_name'] ?? '').toString().compareTo(
        (b['child_name'] ?? '').toString(),
      );
    });

    for (final student in filteredStudents) {
      final childId = (student['child_id'] as num?)?.toInt() ?? 0;
      final addresses = ((student['addresses'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
      if (childId > 0 &&
          !_addressByChild.containsKey(childId) &&
          addresses.isNotEmpty) {
        final defaultAddress = addresses.firstWhere(
          (e) => e['is_default'] == true,
          orElse: () => addresses.first,
        );
        final addressId = (defaultAddress['id'] as num?)?.toInt();
        if (addressId != null && addressId > 0) {
          _addressByChild[childId] = addressId;
        }
      }
      if (childId > 0 && !_selectedByChild.containsKey(childId)) {
        _selectedByChild[childId] = true;
      }
    }

    final tripModeId = _resolveTripModeIdForOperation(
      selectedOperationId,
      tripModes,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Planejar rota',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Escolha o momento da operacao (entrada/saida/transicao), confirme os alunos e o endereco de cada um.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _selectedOperationId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Momento da rota'),
            items: operationWindows
                .map(
                  (op) => DropdownMenuItem<String?>(
                    value: (op['id'] ?? '').toString(),
                    child: Text(
                      (op['label'] ?? '').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: _submitting
                ? null
                : (value) => setState(() => _selectedOperationId = value),
          ),
          if (selectedOperation != null &&
              (selectedOperation['description'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                (selectedOperation['description'] ?? '').toString(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
              ),
            ),
          const SizedBox(height: 10),
          TextField(
            controller: _routeNameController,
            enabled: !_submitting,
            decoration: const InputDecoration(
              labelText: 'Nome da rota (opcional)',
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filteredStudents.isEmpty
                ? const Center(child: Text('Nenhum aluno para este momento.'))
                : ListView.separated(
                    itemCount: filteredStudents.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      final childId =
                          (student['child_id'] as num?)?.toInt() ?? 0;
                      final clientId =
                          (student['client_id'] as num?)?.toInt() ?? 0;
                      final addresses =
                          ((student['addresses'] as List?) ?? const [])
                              .whereType<Map>()
                              .map((e) => Map<String, dynamic>.from(e))
                              .toList(growable: false);
                      final selected = _selectedByChild[childId] ?? false;
                      final selectedAddressId = _addressByChild[childId];
                      final parentName = (student['parent_name'] ?? '')
                          .toString();
                      final childName = (student['child_name'] ?? '')
                          .toString();
                      final shiftName = (student['shift_name'] ?? '')
                          .toString();
                      final schoolName = (student['school_name'] ?? '')
                          .toString();

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE4DECA)),
                          color: Colors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CheckboxListTile(
                              value: selected,
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                childName.isEmpty
                                    ? 'Aluno #$childId'
                                    : childName,
                              ),
                              subtitle: Text(
                                [
                                  if (parentName.isNotEmpty)
                                    'Resp.: $parentName',
                                  if (schoolName.isNotEmpty)
                                    'Escola: $schoolName',
                                  if (shiftName.isNotEmpty) 'Turno: $shiftName',
                                ].join(' • '),
                              ),
                              onChanged: _submitting
                                  ? null
                                  : (value) => setState(() {
                                      _selectedByChild[childId] =
                                          value ?? false;
                                      if ((value ?? false) &&
                                          !_addressByChild.containsKey(
                                            childId,
                                          ) &&
                                          addresses.isNotEmpty) {
                                        final id =
                                            (addresses.first['id'] as num?)
                                                ?.toInt();
                                        if (id != null && id > 0) {
                                          _addressByChild[childId] = id;
                                        }
                                      }
                                    }),
                            ),
                            if (selected && addresses.isNotEmpty)
                              DropdownButtonFormField<int>(
                                initialValue: selectedAddressId,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Endereco de embarque',
                                ),
                                items: addresses
                                    .map((addr) {
                                      final id =
                                          (addr['id'] as num?)?.toInt() ?? 0;
                                      return DropdownMenuItem<int>(
                                        value: id,
                                        child: Text(
                                          (addr['label'] ?? 'Endereco #$id')
                                              .toString(),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    })
                                    .toList(growable: false),
                                onChanged: _submitting
                                    ? null
                                    : (value) {
                                        if (value == null) return;
                                        setState(
                                          () =>
                                              _addressByChild[childId] = value,
                                        );
                                      },
                              ),
                            if (selected && addresses.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(
                                  'Aluno sem endereco cadastrado.',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            if (clientId <= 0) const SizedBox.shrink(),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _submitting
                ? null
                : () async {
                    if (tripModeId == null || tripModeId.isEmpty) {
                      setState(
                        () => _error =
                            'Nao foi possivel determinar a operacao tecnica da rota para este momento.',
                      );
                      return;
                    }

                    final selections = <Map<String, int>>[];
                    for (final student in filteredStudents) {
                      final childId =
                          (student['child_id'] as num?)?.toInt() ?? 0;
                      final clientId =
                          (student['client_id'] as num?)?.toInt() ?? 0;
                      if (!(_selectedByChild[childId] ?? false)) continue;
                      final addressId = _addressByChild[childId];
                      if (childId <= 0 ||
                          clientId <= 0 ||
                          addressId == null ||
                          addressId <= 0) {
                        setState(
                          () => _error =
                              'Selecione o endereco dos alunos marcados.',
                        );
                        return;
                      }
                      selections.add({
                        'client_id': clientId,
                        'child_id': childId,
                        'address_id': addressId,
                      });
                    }

                    if (selections.isEmpty) {
                      setState(() => _error = 'Selecione pelo menos um aluno.');
                      return;
                    }

                    setState(() {
                      _submitting = true;
                      _error = null;
                    });
                    try {
                      await widget.onStart(
                        _RoutePlannerSubmitPayload(
                          shiftId: null,
                          operationId: selectedOperationId,
                          tripModeId: tripModeId,
                          routeName: _routeNameController.text.trim().isEmpty
                              ? null
                              : _routeNameController.text.trim(),
                          selections: selections,
                        ),
                      );
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Rota planejada e iniciada.'),
                        ),
                      );
                    } catch (e) {
                      setState(() {
                        _submitting = false;
                        _error = e.toString();
                      });
                    }
                  },
            icon: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow_rounded),
            label: Text(
              _submitting ? 'Iniciando...' : 'Iniciar rota selecionada',
            ),
          ),
        ],
      ),
    );
  }

  String? _resolveTripModeIdForOperation(
    String? operationId,
    List<Map<String, dynamic>> tripModes,
  ) {
    if (operationId == null || operationId.isEmpty) return null;

    final preferred = switch (operationId) {
      'morning_entry' => 'morning_home_to_school',
      'morning_afternoon_transition' => 'afternoon_school_to_home_lunch',
      'afternoon_night_transition' => 'afternoon_school_to_home_end',
      'night_exit' => 'night_school_to_home',
      _ => 'adhoc',
    };

    final ids = tripModes
        .map((m) => (m['id'] ?? '').toString())
        .toList(growable: false);
    if (ids.contains(preferred)) return preferred;
    if (ids.isNotEmpty) return ids.first;
    return preferred;
  }
}

class _RoutePlannerSubmitPayload {
  const _RoutePlannerSubmitPayload({
    required this.shiftId,
    required this.operationId,
    required this.tripModeId,
    required this.routeName,
    required this.selections,
  });

  final int? shiftId;
  final String? operationId;
  final String tripModeId;
  final String? routeName;
  final List<Map<String, int>> selections;
}

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _EmptyPane extends StatelessWidget {
  const _EmptyPane({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.slate),
      ),
    );
  }
}
