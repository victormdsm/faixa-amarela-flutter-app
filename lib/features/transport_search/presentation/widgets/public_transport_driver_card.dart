import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../domain/entities/public_transport_driver.dart';
import 'public_transport_driver_detail_sheet.dart';

/// Card de um motorista de transporte escolar publico encontrado na busca.
/// Exibe resumo do veículo, contato público, CNH, sobre (information),
/// escolas e bairros. Toque no card — ou no botão "Ver mais" — abre o bottom
/// sheet completo, de onde sai o contato via WhatsApp (contato público — o
/// backend nunca expõe o celular pessoal).
class PublicTransportDriverCard extends StatelessWidget {
  const PublicTransportDriverCard({super.key, required this.driver});

  final PublicTransportDriver driver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => showPublicTransportDriverDetail(context, driver: driver),
        child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppNetworkAvatar(
              name: driver.name,
              imageUrl: driver.avatarUrl,
              radius: 30,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  if ((driver.information ?? '').isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      driver.information!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.slate,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if ((driver.vehicleDescription ?? '').isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_bus_outlined,
                          size: 13,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            [
                              driver.vehicleDescription!,
                              if ((driver.vehiclePlate ?? '').isNotEmpty)
                                driver.vehiclePlate!.toUpperCase(),
                            ].join(' • '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.slate,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if ((driver.publicContactName ?? '').isNotEmpty ||
                      (driver.publicContactPhone ?? '').isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_in_talk_outlined,
                          size: 13,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            [
                              if ((driver.publicContactName ?? '').isNotEmpty)
                                driver.publicContactName!,
                              if ((driver.publicContactPhone ?? '').isNotEmpty)
                                driver.publicContactPhone!,
                            ].join(' • '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.slate,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if ((driver.cnh ?? '').isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.badge_outlined,
                          size: 13,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            'CNH ${driver.cnh}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.slate,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (driver.schools.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.school_outlined,
                          size: 13,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            driver.schools.take(2).join(' · '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.slate,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (driver.districts.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            driver.districts.take(2).join(' · '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.slate,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.yellowLight,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        size: 14,
                        color: AppColors.yellowDark,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '-',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.yellowDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton(
                  // O tema global define minimumSize: Size.fromHeight(48)
                  // (largura mínima infinita). Dentro deste Row (filho
                  // não-flex) isso zeraria a largura do Expanded do texto,
                  // então o botão fixa sua própria largura mínima.
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(88, 48),
                  ),
                  // O card resume o motorista; o contato fica no detalhe.
                  // Antes o botão disparava o WhatsApp direto e o responsável
                  // solicitava sem ver van, escolas, bairros e turnos.
                  onPressed: () =>
                      showPublicTransportDriverDetail(context, driver: driver),
                  child: const Text('Ver mais'),
                ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
}
