import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../data/ads_repository.dart';
import '../../domain/ad.dart';
import '../providers/ads_providers.dart';
import 'ad_link_launcher.dart';

/// Anúncio em formato de cartão (imagem 16:9, título, CTA e chip
/// "Publicidade"). Exibe o primeiro anúncio `card` do placement; não
/// renderiza nada quando não há anúncios ou quando a busca falha.
class AdCardWidget extends ConsumerWidget {
  const AdCardWidget({
    super.key,
    required this.placement,
    required this.role,
    this.cityId,
  });

  final String placement;
  final AdRole role;

  /// Cidade da superfície; `null` = o backend só serve anúncios sem
  /// segmentação geográfica.
  final int? cityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(
      adsProvider((placement: placement, role: role, cityId: cityId)),
    );

    final ad = adsAsync.when(
      loading: () => null,
      error: (error, stackTrace) => null,
      data: (ads) => ads
          .where((ad) => ad.format == AdFormat.card)
          .firstOrNull,
    );
    if (ad == null) return const SizedBox.shrink();

    // Impressão 1× por anúncio por sessão por placement (dedup no repository).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(adsRepositoryProvider)
          .trackImpression(
            ad.id,
            placement: placement,
            surface: AdFormat.card.wireValue,
            role: role,
            cityId: cityId,
          );
    });

    Future<void> onTap() async {
      if (!ad.isClickable) return;
      await ref
          .read(adsRepositoryProvider)
          .trackClick(
            ad.id,
            placement: placement,
            surface: AdFormat.card.wireValue,
            role: role,
            cityId: cityId,
          );
      await openAdLink(ad.linkUrl!);
    }

    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: ad.isClickable ? onTap : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                ad.resolvedImageUrl ?? ad.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppColors.surfaceSoft,
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.yellow,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.surfaceSoft,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.muted,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          ad.displayTitle,
                          style: textTheme.titleSmall?.copyWith(
                            color: AppColors.ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const _SponsoredChip(),
                    ],
                  ),
                  if (ad.isClickable) ...[
                    const SizedBox(height: AppSpacing.md),
                    FilledButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(ad.ctaText),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SponsoredChip extends StatelessWidget {
  const _SponsoredChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'Publicidade',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.muted,
          fontSize: 10,
        ),
      ),
    );
  }
}
