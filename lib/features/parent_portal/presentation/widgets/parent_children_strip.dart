import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../domain/models/child.dart';

/// Status simplificado de um dependente na dashboard.
enum _ChildStatus { boarded, waiting, notBoarded }

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
          final status = _resolveStatus(child);
          return _ChildChip(
            name: child.name,
            status: status,
            onTap: onTap != null ? () => onTap!(child) : null,
          );
        },
      ),
    );
  }

  _ChildStatus _resolveStatus(Child child) {
    final childId = child.id;
    final childName = child.name.toLowerCase().trim();

    for (final boarding in boardings) {
      final bChildId = boarding['childId'];
      final bName = boarding['childName']?.toString().toLowerCase().trim();
      final matches =
          (bChildId == childId) || (childName.isNotEmpty && bName == childName);
      if (!matches) continue;

      final status = boarding['status']?.toString().toLowerCase() ?? '';
      if (status == 'boarded' || status == 'embarcado' || status == 'done') {
        return _ChildStatus.boarded;
      }
      if (status == 'not_boarded' || status == 'nao_embarcado') {
        return _ChildStatus.notBoarded;
      }
    }
    return _ChildStatus.waiting;
  }
}

class _ChildChip extends StatelessWidget {
  const _ChildChip({required this.name, required this.status, this.onTap});

  final String name;
  final _ChildStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (status) {
      _ChildStatus.boarded => (
        'Embarcou',
        AppColors.success,
        Icons.check_rounded,
      ),
      _ChildStatus.notBoarded => (
        'Nao embarcou',
        AppColors.danger,
        Icons.close_rounded,
      ),
      _ChildStatus.waiting => (
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
