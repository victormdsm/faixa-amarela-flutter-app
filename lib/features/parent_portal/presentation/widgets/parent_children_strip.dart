import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/child.dart';

/// Status simplificado de um dependente na dashboard.
enum ChildBoardingStatus { boarded, waiting, notBoarded }

/// Resolve o status de embarque do filho cruzando com os boardings do dia
/// (payload de `GET /parent/boardings`).
///
/// APP-04: o vínculo filho↔boarding é feito pelo caminho real do payload —
/// `boarding['client']['child']['id']` (o mesmo usado em
/// `parent_boardings_page.dart`). Antes o código lia `boarding['childId']`,
/// chave que não existe no contrato, e o badge nunca casava por id.
///
/// APP-08: `absent` (status emitido pelo backend quando o motorista marca
/// falta) conta como "Não embarcou".
ChildBoardingStatus resolveChildBoardingStatus({
  required int childId,
  required String childName,
  required List<Map<String, dynamic>> boardings,
}) {
  final normalizedName = childName.toLowerCase().trim();

  for (final boarding in boardings) {
    final client = boarding['client'];
    final child = client is Map ? client['child'] : null;
    final bChildId = child is Map ? (child['id'] as num?)?.toInt() : null;
    final bName = child is Map
        ? child['name']?.toString().toLowerCase().trim()
        : null;
    final matches =
        (bChildId != null && bChildId > 0 && bChildId == childId) ||
        (normalizedName.isNotEmpty && bName == normalizedName);
    if (!matches) continue;

    final status = boarding['status']?.toString().toLowerCase() ?? '';
    if (status == 'boarded' || status == 'embarcado' || status == 'done') {
      return ChildBoardingStatus.boarded;
    }
    if (status == 'not_boarded' ||
        status == 'nao_embarcado' ||
        status == 'absent') {
      return ChildBoardingStatus.notBoarded;
    }
  }
  return ChildBoardingStatus.waiting;
}

/// Lista horizontal compacta de dependentes do responsavel.
class ParentChildrenStrip extends StatelessWidget {
  const ParentChildrenStrip({
    super.key,
    required this.children,
    this.boardings = const [],
    this.onTap,
  });

  final List<Child> children;
  final List<Map<String, dynamic>> boardings;
  final ValueChanged<Child>? onTap;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return _EmptyChildren(onTap: onTap != null ? () {} : null);
    }

    return SizedBox(
      // Altura com folga para padding + avatar + nome + linha de status
      // (conteúdo ~97px); antes 92 estourava em aparelhos com fonte maior.
      height: 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final child = children[index];
          final status = resolveChildBoardingStatus(
            childId: child.id,
            childName: child.name,
            boardings: boardings,
          );
          return _ChildChip(
            name: child.name,
            status: status,
            onTap: onTap != null ? () => onTap!(child) : null,
          );
        },
      ),
    );
  }
}

class _ChildChip extends StatelessWidget {
  const _ChildChip({required this.name, required this.status, this.onTap});

  final String name;
  final ChildBoardingStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      ChildBoardingStatus.boarded => (
        'Embarcou',
        AppColors.success,
        Icons.check_rounded,
      ),
      ChildBoardingStatus.notBoarded => (
        'Nao embarcou',
        AppColors.danger,
        Icons.close_rounded,
      ),
      ChildBoardingStatus.waiting => (
        'Aguardando',
        AppColors.warning,
        Icons.schedule_rounded,
      ),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        width: 86,
        padding: const EdgeInsets.all(AppSpacing.md),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.yellowLight,
              child: Text(
                name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              name.split(' ').first,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 10, color: color),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 9,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyChildren extends StatelessWidget {
  const _EmptyChildren({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.child_care_outlined, color: AppColors.muted),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Nenhum dependente cadastrado.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.slate),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
