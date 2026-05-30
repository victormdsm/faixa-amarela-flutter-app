import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../auth/presentation/state/app_session_controller.dart';
import '../providers/driver_portal_providers.dart';

class DriverClientsPage extends ConsumerStatefulWidget {
  const DriverClientsPage({super.key});

  @override
  ConsumerState<DriverClientsPage> createState() => _DriverClientsPageState();
}

class _DriverClientsPageState extends ConsumerState<DriverClientsPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(driverClientsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes'),
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => ref.invalidate(driverClientsProvider),
            icon: const Icon(Icons.refresh_rounded, size: 20),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.driverAddClient),
        icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
        label: const Text('Novo cliente'),
      ),
      body: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(driverClientsProvider),
        ),
        data: (page) {
          final filteredItems = page.items
              .where(_matchesSearch)
              .toList(growable: false);

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Buscar responsavel, CPF ou dependente...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _query.trim().isNotEmpty
                        ? IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded, size: 18),
                          )
                        : null,
                  ),
                ),
              ),

              // Metrics row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppMetricCard(
                        label: 'Total',
                        value: '${page.items.length}',
                        icon: Icons.people_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppMetricCard(
                        label: 'Filtrado',
                        value: '${filteredItems.length}',
                        icon: Icons.filter_list_rounded,
                      ),
                    ),
                  ],
                ),
              ),

              // Client list
              Expanded(
                child: filteredItems.isEmpty
                    ? AppEmptyState(
                        message: _query.trim().isEmpty
                            ? 'Nenhum cliente encontrado'
                            : 'Sem resultados para "$_query"',
                        icon: Icons.people_outline_rounded,
                        subtitle: _query.trim().isEmpty
                            ? 'Adicione um cliente para comecar.'
                            : 'Tente buscar por outro termo.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.sm,
                          AppSpacing.lg,
                          100,
                        ),
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) => _ClientCard(
                          client: filteredItems[index],
                          onShowChildren: _showChildren,
                          onShowDebt: _showDebtDialog,
                          onUnlink: _confirmUnlink,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _matchesSearch(Map<String, dynamic> client) {
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

  void _showChildren(int clientId, String parentName, List<dynamic> children) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _DependentsSheet(
        clientId: clientId,
        parentName: parentName,
        initialChildren: children,
      ),
    );
  }

  Future<void> _confirmUnlink(int clientId, String parentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desvincular responsavel'),
        content: Text(
          'Deseja desvincular $parentName? O cadastro sera mantido.',
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

    if (confirmed != true || !mounted) return;

    final confirmController = TextEditingController();
    try {
      final secondConfirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmacao final'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Digite DESVINCULAR para confirmar.'),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: confirmController,
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
                if (confirmController.text.trim().toUpperCase() !=
                    'DESVINCULAR') {
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

      if (secondConfirmed != true || !mounted) return;
    } finally {
      confirmController.dispose();
    }

    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) return;

    try {
      await ref
          .read(driverPortalRepositoryProvider)
          .unlinkClient(session.authorizationHeader, clientId);
      ref.invalidate(driverClientsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Responsavel desvinculado com sucesso.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _showDebtDialog(
    int clientId,
    String parentName, {
    double? initialAmount,
  }) async {
    final draft = await showModalBottomSheet<_DebtDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _DebtEditorSheet(
        parentName: parentName,
        initialAmount: initialAmount,
      ),
    );

    if (draft == null || !context.mounted) return;

    final session = ref.read(appSessionControllerProvider).session;
    if (session == null) return;

    try {
      final response = await ref
          .read(driverPortalRepositoryProvider)
          .updateClientInadimplency(
            session.authorizationHeader,
            clientId,
            amount: draft.amount,
            isInadimplent: draft.amount > 0,
            reason: draft.reason,
          );
      ref.invalidate(driverClientsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (response['message'] ?? '').toString().trim().isNotEmpty
                ? (response['message'] as String)
                : 'Solicitacao de debito enviada para aprovacao.',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

// ─────────────────────────────────────────────
// Client Card
// ─────────────────────────────────────────────

class _ClientCard extends StatelessWidget {
  const _ClientCard({
    required this.client,
    required this.onShowChildren,
    required this.onShowDebt,
    required this.onUnlink,
  });

  final Map<String, dynamic> client;
  final void Function(int, String, List<dynamic>) onShowChildren;
  final Future<void> Function(int, String, {double? initialAmount}) onShowDebt;
  final Future<void> Function(int, String) onUnlink;

  @override
  Widget build(BuildContext context) {
    final parent = (client['parent'] as Map?) ?? const {};
    final children = ((client['children'] as List?) ?? const []);
    final address = (client['address'] as Map?) ?? const {};
    final district = (address['district'] as Map?) ?? const {};
    final clientId = (client['id'] as num?)?.toInt() ?? 0;
    final parentName = (parent['name'] ?? 'Cliente #$clientId').toString();
    final inadimplencyAlert = client['inadimplency_alert'] == true;
    final inadimplencyRequestStatus =
        (client['inadimplency_request_status'] ?? '').toString().toLowerCase();
    final inadimplencyAmount = (client['inadimplency_amount'] as num?)
        ?.toDouble();
    final cpf = (parent['cpf'] ?? '').toString();
    final phone = (parent['cell_phone'] ?? '').toString();
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.ink,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parentName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (cpf.isNotEmpty)
                        Text(
                          'CPF: $cpf',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.slate,
                          ),
                        ),
                      if (phone.isNotEmpty)
                        Text(
                          phone,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.slate,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${children.length} dep.',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            // Info pills
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppInfoPill(
                  icon: Icons.location_on_outlined,
                  text: (district['name'] ?? 'Nao informado').toString(),
                ),
              ],
            ),

            // Debt alert
            if (inadimplencyAlert) ...[
              const SizedBox(height: AppSpacing.md),
              AppInfoBanner(
                message: inadimplencyAmount != null && inadimplencyAmount > 0
                    ? 'Debito: R\$ ${inadimplencyAmount.toStringAsFixed(2)}'
                    : 'Responsavel com debitos.',
                icon: Icons.warning_amber_rounded,
                color: AppColors.yellowDark,
              ),
            ],
            if (inadimplencyRequestStatus == 'pending') ...[
              const SizedBox(height: AppSpacing.sm),
              const AppInfoBanner(
                message:
                    'Solicitacao de inadimplencia pendente de aprovacao do admin.',
                icon: Icons.hourglass_top_rounded,
                color: AppColors.ink,
              ),
            ],

            // Actions
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _ActionChip(
                    icon: Icons.groups_2_outlined,
                    label: 'Dependentes',
                    onTap: clientId > 0
                        ? () => onShowChildren(
                            clientId,
                            parentName,
                            children.cast<dynamic>(),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _ActionChip(
                    icon: Icons.receipt_long_outlined,
                    label: 'Debito',
                    onTap: clientId > 0
                        ? () => onShowDebt(
                            clientId,
                            parentName,
                            initialAmount: inadimplencyAmount,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _ActionChip(
                  icon: Icons.link_off_rounded,
                  label: '',
                  compact: true,
                  destructive: true,
                  onTap: clientId > 0
                      ? () => onUnlink(clientId, parentName)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    this.onTap,
    this.compact = false,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool compact;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final fg = destructive ? AppColors.danger : AppColors.ink;
    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 5),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: fg,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Dependents Sheet
// ─────────────────────────────────────────────

class _DependentsSheet extends ConsumerWidget {
  const _DependentsSheet({
    required this.clientId,
    required this.parentName,
    required this.initialChildren,
  });

  final int clientId;
  final String parentName;
  final List<dynamic> initialChildren;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncChildren = ref.watch(driverClientChildrenProvider(clientId));
    final initialItems = initialChildren
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Padding(
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
              'Dependentes de $parentName',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: asyncChildren.when(
                loading: () => initialItems.isNotEmpty
                    ? _DependentsList(items: initialItems)
                    : const Center(child: CircularProgressIndicator()),
                error: (e, _) => initialItems.isNotEmpty
                    ? _DependentsList(items: initialItems)
                    : Center(child: Text(e.toString())),
                data: (page) => page.items.isEmpty
                    ? const AppEmptyState(
                        message: 'Nenhum dependente encontrado',
                        icon: Icons.child_care_outlined,
                      )
                    : _DependentsList(items: page.items),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DependentsList extends StatelessWidget {
  const _DependentsList({required this.items});
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = items[index];
        final name = (item['name'] ?? 'Sem nome').toString();
        final school = (item['school'] as Map?)?['name']?.toString();
        final shift =
            ((item['shift'] as Map?)?['shift_name'] ??
                    (item['shift'] as Map?)?['name'])
                ?.toString();
        final avatarUrl = (item['avatar_url'] ?? item['avatar'])?.toString();

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surfaceSoft,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? const Icon(
                        Icons.child_care_rounded,
                        color: AppColors.ink,
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (school != null || shift != null)
                      Text(
                        [?school, ?shift].join(' · '),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
// Debt Editor Sheet
// ─────────────────────────────────────────────

class _DebtDraft {
  const _DebtDraft({required this.amount, this.reason});
  final double amount;
  final String? reason;
}

class _DebtEditorSheet extends StatefulWidget {
  const _DebtEditorSheet({required this.parentName, this.initialAmount});

  final String parentName;
  final double? initialAmount;

  @override
  State<_DebtEditorSheet> createState() => _DebtEditorSheetState();
}

class _DebtEditorSheetState extends State<_DebtEditorSheet> {
  late final TextEditingController _amountController;
  final _reasonController = TextEditingController();
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Debito de ${widget.parentName}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor (R\$)',
              prefixIcon: Icon(Icons.attach_money_rounded, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _reasonController,
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Observacao (opcional)',
              prefixIcon: Icon(Icons.notes_rounded, size: 20),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Confirmar'),
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
      setState(() => _error = 'Valor invalido.');
      return;
    }
    final reason = _reasonController.text.trim();
    Navigator.of(
      context,
    ).pop(_DebtDraft(amount: amount, reason: reason.isEmpty ? null : reason));
  }
}
