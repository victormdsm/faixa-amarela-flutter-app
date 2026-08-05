import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/presentation/widgets/app_feedback.dart';
import '../../../../core/presentation/widgets/app_shared_widgets.dart';
import '../../../../core/presentation/widgets/full_image_viewer.dart';
import '../../../../core/utils/whatsapp_launcher.dart';
import '../../domain/entities/public_transport_driver.dart';
import '../providers/transport_search_providers.dart';
import 'vehicle_banner_fallback.dart';

/// Abre o bottom sheet de detalhe do motorista encontrado na busca pública.
Future<void> showPublicTransportDriverDetail(
  BuildContext context, {
  required PublicTransportDriver driver,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => PublicTransportDriverDetailSheet(driver: driver),
  );
}

/// Bottom sheet de detalhe do motorista (busca pública, sem login).
///
/// Exibe foto, nome, CNH, descrição, van, contato público (WhatsApp/ligação
/// — sempre o telefone público da van, nunca o celular pessoal) e as
/// escolas/bairros/turnos atendidos.
///
/// O conteúdo resolve via [transportDriverDetailProvider]: dados frescos da
/// última busca entram sozinhos; enquanto carrega mostra um indicador (ou o
/// resumo do card) e, se a resolução falhar, um erro amigável com retry.
class PublicTransportDriverDetailSheet extends ConsumerWidget {
  const PublicTransportDriverDetailSheet({super.key, required this.driver});

  /// Resumo vindo do card — usado como conteúdo imediato e como fallback
  /// enquanto o provider resolve (ou se ele falhar).
  final PublicTransportDriver driver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(transportDriverDetailProvider(driver.id));

    return detailAsync.when(
      data: (fresh) {
        if (fresh == null) {
          return _DetailErrorContent(
            message:
                'Este motorista não está mais disponível nas buscas da sua região.',
            onRetry: () => ref.invalidate(transportDriversProvider),
          );
        }
        return _DriverDetailContent(driver: fresh);
      },
      loading: () => driver.id > 0
          ? _DriverDetailContent(driver: driver)
          : const _DetailLoadingContent(),
      error: (_, _) => driver.id > 0
          ? _DriverDetailContent(driver: driver)
          : _DetailErrorContent(
              message:
                  'Não foi possível carregar os dados do motorista agora.',
              onRetry: () => ref.invalidate(transportDriversProvider),
            ),
    );
  }
}

class _DetailLoadingContent extends StatelessWidget {
  const _DetailLoadingContent();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 220,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _DetailErrorContent extends StatelessWidget {
  const _DetailErrorContent({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: AppColors.warning,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _DriverDetailContent extends StatelessWidget {
  const _DriverDetailContent({required this.driver});

  final PublicTransportDriver driver;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cnh = (driver.cnh ?? '').trim();
    final about = driver.about;
    final vehicleDescription = (driver.vehicleDescription ?? '').trim();
    final vehiclePlate = (driver.vehiclePlate ?? '').trim();
    final contactPhone = (driver.contactPhone ?? '').trim();
    final contactName = (driver.publicContactName ?? '').trim().isNotEmpty
        ? driver.publicContactName!.trim()
        : driver.name;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Cabeçalho: foto grande + nome ──────────────────────────
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                AppNetworkAvatar(
                  name: driver.name,
                  imageUrl: driver.avatarUrl,
                  radius: 44,
                ),
                Positioned(
                  right: -6,
                  top: -6,
                  child: FullImageViewerEyeButton(
                    imageUrl: driver.avatarUrl,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            driver.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          if (cnh.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.badge_rounded,
                  size: 16,
                  color: AppColors.slate,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'CNH $cnh',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.slate,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          // ── Descrição (oculta quando vazia) ────────────────────────
          if (about != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Text(
              about,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.slate,
              ),
            ),
          ],

          // ── Van ────────────────────────────────────────────────────
          const SizedBox(height: AppSpacing.xl),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: (driver.vehicleImageUrl ?? '').trim().isNotEmpty
                      ? Image.network(
                          driver.vehicleImageUrl!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const VehicleBannerFallback(),
                        )
                      : const VehicleBannerFallback(),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: FullImageViewerEyeButton(
                  imageUrl: driver.vehicleImageUrl,
                ),
              ),
            ],
          ),
          if (vehicleDescription.isNotEmpty || vehiclePlate.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.directions_bus_rounded,
                  size: 16,
                  color: AppColors.slate,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    [
                      if (vehicleDescription.isNotEmpty) vehicleDescription,
                      if (vehiclePlate.isNotEmpty)
                        'Placa ${vehiclePlate.toUpperCase()}',
                    ].join(' • '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.slate,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ── Cobertura: escolas, bairros e turnos ───────────────────
          if (driver.schools.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _DetailChipSection(
              icon: Icons.school_outlined,
              label: 'Escolas atendidas',
              values: driver.schools,
            ),
          ],
          if (driver.districts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _DetailChipSection(
              icon: Icons.location_on_outlined,
              label: 'Bairros atendidos',
              values: driver.districts,
            ),
          ],
          if (driver.shifts.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _DetailChipSection(
              icon: Icons.schedule_rounded,
              label: 'Turnos atendidos',
              values: driver.shifts,
            ),
          ],

          // ── Contato público ────────────────────────────────────────
          const SizedBox(height: AppSpacing.xl),
          if (contactPhone.isEmpty)
            Text(
              'Este motorista ainda não cadastrou um contato público.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.muted,
              ),
            )
          else ...[
            FilledButton.icon(
              onPressed: () => _openWhatsApp(context, contactPhone, driver.name),
              icon: const Icon(Icons.chat_rounded),
              label: Text('Chamar $contactName no WhatsApp'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () => _callPhone(context, contactPhone),
              icon: const Icon(Icons.phone_rounded),
              label: const Text('Ligar'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openWhatsApp(
    BuildContext context,
    String phone,
    String driverName,
  ) async {
    final result = await WhatsAppLauncher.openChat(
      phone: phone,
      contactName: driverName,
    );
    if (!context.mounted || result.success) return;
    showAppSnackBar(
      context,
      message: result.errorMessage ?? 'Falha ao abrir o WhatsApp.',
      type: AppFeedbackType.error,
    );
  }

  Future<void> _callPhone(BuildContext context, String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final opened = await launchUrl(Uri(scheme: 'tel', path: digits));
    if (!context.mounted || opened) return;
    showAppSnackBar(
      context,
      message: 'Não foi possível iniciar a ligação neste dispositivo.',
      type: AppFeedbackType.error,
    );
  }
}

class _DetailChipSection extends StatelessWidget {
  const _DetailChipSection({
    required this.icon,
    required this.label,
    required this.values,
  });

  final IconData icon;
  final String label;
  final List<String> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: AppColors.muted),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.slate,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: values
              .map(
                (value) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: AppColors.yellow.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    value,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      ],
    );
  }
}
