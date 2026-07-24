import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/models/catalog_option.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/faixa_app_bar.dart';
import '../../../../core/presentation/widgets/faixa_section_card.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../domain/models/driver_profile_change_request.dart';
import '../../../../ui/core/widgets/status_pill.dart';
import '../../../catalog/data/catalog_repository.dart';
import '../providers/driver_portal_providers.dart';

/// Tela de acompanhamento das solicitacoes de alteracao de perfil do motorista.
///
/// Lista o historico completo (pendentes, aprovadas e reprovadas) com status,
/// data, resumo das alteracoes solicitadas e observacao do admin.
class DriverChangeRequestsPage extends ConsumerWidget {
  const DriverChangeRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(driverProfileChangeRequestsProvider);
    final schoolsAsync = ref.watch(schoolsCatalogProvider);
    final districtsAsync = ref.watch(districtsCatalogProvider);
    final shiftsAsync = ref.watch(shiftsCatalogProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceSoft,
      appBar: FaixaAppBar.screen(
        title: 'Minhas solicitacoes',
        actions: [
          IconButton(
            tooltip: 'Atualizar',
            onPressed: () => ref.invalidate(driverProfileChangeRequestsProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => FaixaErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(driverProfileChangeRequestsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const FaixaEmptyState(
              message: 'Nenhuma solicitacao encontrada',
              subtitle: 'Alteracoes de escolas, bairros, turnos ou fotos aparecerao aqui.',
              icon: Icons.inbox_outlined,
            );
          }

          final schoolById = {
            for (final s in schoolsAsync.value ?? const <CatalogOption>[]) s.id: s,
          };
          final districtById = {
            for (final d in districtsAsync.value ?? const <CatalogOption>[]) d.id: d,
          };
          final shiftById = {
            for (final s in shiftsAsync.value ?? const <CatalogOption>[]) s.id: s,
          };

          final sortedItems = items.toList(growable: false)
            ..sort((a, b) {
              final aDate = a.createdAt ?? DateTime(1970);
              final bDate = b.createdAt ?? DateTime(1970);
              return bDate.compareTo(aDate);
            });

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: sortedItems
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                    child: _RequestCard(
                      request: item,
                      schoolById: schoolById,
                      districtById: districtById,
                      shiftById: shiftById,
                    ),
                  ),
                )
                .toList(growable: false),
          );
        },
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.schoolById,
    required this.districtById,
    required this.shiftById,
  });

  final DriverProfileChangeRequest request;
  final Map<int, CatalogOption> schoolById;
  final Map<int, CatalogOption> districtById;
  final Map<int, CatalogOption> shiftById;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _RequestStatus.fromString(request.status);
    final dateText = formatDateTime(request.createdAt);
    final summary = _buildSummary();
    final reviewNote = (request.reviewNote ?? '').trim();

    return FaixaSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusPill(status),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  dateText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.slate,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (summary.isNotEmpty) ...[
            Text(
              'Alteracoes solicitadas',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...summary.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: AppColors.yellowDark,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        line,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (summary.isEmpty)
            Text(
              'Nenhuma alteracao identificada nesta solicitacao.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.slate,
              ),
            ),
          if (reviewNote.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: status.isRejected
                    ? AppColors.danger.withValues(alpha: 0.08)
                    : AppColors.surfaceSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: status.isRejected
                      ? AppColors.danger.withValues(alpha: 0.25)
                      : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.isRejected
                        ? 'Motivo da reprovacao'
                        : 'Observacao do admin',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: status.isRejected
                          ? AppColors.danger
                          : AppColors.slate,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    reviewNote,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: status.isRejected
                          ? AppColors.danger
                          : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusPill(_RequestStatus status) {
    return StatusPill(label: status.label, color: status.color);
  }

  List<String> _buildSummary() {
    final lines = <String>[];

    final schoolIds = request.requestedSchoolIds;
    if (schoolIds != null && schoolIds.isNotEmpty) {
      final names = schoolIds
          .map((id) => schoolById[id]?.name ?? 'Escola #$id')
          .toList(growable: false);
      lines.add('Escolas: ${names.join(', ')}');
    }

    final districtShiftMap = request.requestedDistrictShiftMap;
    if (districtShiftMap != null && districtShiftMap.isNotEmpty) {
      final entries = districtShiftMap.entries.toList(growable: false)
        ..sort((a, b) {
          final aName = districtById[int.tryParse(a.key)]?.name ?? a.key;
          final bName = districtById[int.tryParse(b.key)]?.name ?? b.key;
          return aName.compareTo(bName);
        });

      for (final entry in entries) {
        final districtId = int.tryParse(entry.key);
        final districtName = districtById[districtId]?.name ??
            'Bairro #${entry.key}';
        final shiftNames = entry.value
            .map((id) => shiftById[id]?.name ?? 'Turno #$id')
            .toList(growable: false);
        if (shiftNames.isEmpty) {
          lines.add('Bairro: $districtName');
        } else {
          lines.add('Bairro $districtName: ${shiftNames.join(', ')}');
        }
      }
    }

    final photoLabels = <String>[
      if ((request.requestedAvatarPath ?? '').isNotEmpty) 'foto do motorista',
      if ((request.requestedVehicleImagePath ?? '').isNotEmpty)
        'foto do veiculo',
    ];
    if (photoLabels.isNotEmpty) {
      lines.add('Fotos: ${photoLabels.join(' e ')}');
    }

    final note = (request.requestNote ?? '').trim();
    if (note.isNotEmpty) {
      lines.add('Observacao enviada: $note');
    }

    return lines;
  }
}

enum _RequestStatus {
  pending('Pendente', AppColors.yellow),
  approved('Aprovada', AppColors.success),
  rejected('Reprovada', AppColors.danger),
  unknown('Registrada', AppColors.muted);

  const _RequestStatus(this.label, this.color);

  final String label;
  final Color color;

  bool get isRejected => this == _RequestStatus.rejected;

  factory _RequestStatus.fromString(String value) {
    return switch (value.toLowerCase().trim()) {
      'pending' => _RequestStatus.pending,
      'approved' => _RequestStatus.approved,
      'rejected' => _RequestStatus.rejected,
      _ => _RequestStatus.unknown,
    };
  }
}
