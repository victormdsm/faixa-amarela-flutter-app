import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/skeleton_image_placeholder.dart';
import '../../../../domain/models/driver_profile.dart';

/// Card de perfil do motorista exibido no dashboard.
class DriverProfileCard extends StatelessWidget {
  const DriverProfileCard({super.key, this.profile});

  final DriverProfile? profile;

  @override
  Widget build(BuildContext context) {
    final name = (profile?.name ?? '').trim().isNotEmpty
        ? profile!.name
        : 'Motorista';
    final vanPlate = (profile?.vanPlate ?? '').trim().isNotEmpty
        ? profile!.vanPlate
        : 'Placa não informada';
    final isOnline = profile?.isActive ?? false;
    final avatarUrl = profile?.avatarUrl;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          _Avatar(imageUrl: avatarUrl, name: name),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    const Icon(
                      Icons.directions_bus_filled_rounded,
                      size: 14,
                      color: AppColors.slate,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Van $vanPlate',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.slate),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatusPill(isOnline: isOnline),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({this.imageUrl, required this.name});

  final String? imageUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    final hasImage = (imageUrl ?? '').trim().isNotEmpty;

    return CircleAvatar(
      radius: 28,
      backgroundColor: AppColors.yellowLight,
      child: hasImage
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                placeholder: (context, url) => const SkeletonImagePlaceholder(),
                errorWidget: (context, url, error) => _fallbackIcon(),
              ),
            )
          : _fallbackIcon(),
    );
  }

  Widget _fallbackIcon() {
    return Text(
      name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
      style: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
        fontSize: 20,
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final color = isOnline ? AppColors.success : AppColors.muted;
    final label = isOnline ? 'Online' : 'Offline';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isOnline)
            const AppPulsingDot(color: AppColors.success)
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
