import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// Alias semântico para [AppErrorState].
///
/// Mantém a mesma API e comportamento, padronizando o prefixo Faixa
/// nos componentes compartilhados.
typedef FaixaErrorState = AppErrorState;

/// Alias semântico para [AppEmptyState].
///
/// Mantém a mesma API e comportamento, padronizando o prefixo Faixa
/// nos componentes compartilhados.
typedef FaixaEmptyState = AppEmptyState;

class AppErrorState extends StatelessWidget {
  const AppErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: AppColors.danger,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Algo deu errado',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.message,
    required this.icon,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String message;

  /// Mantido por compatibilidade de API — o visual é sempre a
  /// [FaixaEmptyIllustration] da marca, independente do ícone informado.
  final IconData icon;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaixaEmptyIllustration(),
            const SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            if ((subtitle ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.slate),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppMetricCard extends StatelessWidget {
  const AppMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.ink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
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
  }
}

/// Chip métrico compacto para exibir um valor numérico e seu rótulo.
///
/// Usado em dashboards e execução de rotas para indicadores como
/// "Pendentes", "Embarcados", "Paradas" etc.
class AppMetricChip extends StatelessWidget {
  const AppMetricChip({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.slate),
            ),
          ],
        ),
      ),
    );
  }
}

class AppInfoPill extends StatelessWidget {
  const AppInfoPill({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.slate),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              text,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.slate),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ponto pulsante animado, usado para indicar status "ao vivo".
class AppPulsingDot extends StatefulWidget {
  const AppPulsingDot({super.key, required this.color});

  final Color color;

  @override
  State<AppPulsingDot> createState() => _AppPulsingDotState();
}

class _AppPulsingDotState extends State<AppPulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _anim.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Linha de informação com ícone e texto, usada em cards e detalhes.
class AppIconTextRow extends StatelessWidget {
  const AppIconTextRow({
    super.key,
    required this.icon,
    required this.text,
    this.italic = false,
  });

  final IconData icon;
  final String text;
  final bool italic;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: AppColors.slate),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.slate,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ],
    );
  }
}

/// Avatar com imagem de rede e fallback para a inicial do nome.
class AppNetworkAvatar extends StatelessWidget {
  const AppNetworkAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 20,
  });

  final String name;
  final String? imageUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasImage = (imageUrl ?? '').trim().isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.yellowLight,
      backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
      onBackgroundImageError: hasImage ? (error, stackTrace) {} : null,
      child: hasImage
          ? null
          : Text(
              name.isNotEmpty ? name.characters.first.toUpperCase() : '?',
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

/// Ilustração de marca para estados vazios: círculo amarelo `#FF9E1B` com a
/// faixa ink em diagonal (sinalização escolar) e o glyph do ônibus em ink —
/// o mesmo vocabulário do marcador da van no mapa.
class FaixaEmptyIllustration extends StatelessWidget {
  const FaixaEmptyIllustration({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.yellow,
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Faixa ink levemente diagonal, como na sinalização escolar.
            Align(
              alignment: const Alignment(0, 0.78),
              child: Transform.rotate(
                angle: -0.14,
                child: Container(
                  width: size * 1.25,
                  height: size * 0.2,
                  color: AppColors.ink,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: size * 0.14),
                child: Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.ink,
                  size: size * 0.44,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner de status com ícone, cor e mensagem.
class AppStatusRow extends StatelessWidget {
  const AppStatusRow({
    super.key,
    required this.icon,
    required this.color,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AppInfoBanner extends StatelessWidget {
  const AppInfoBanner({
    super.key,
    required this.message,
    required this.icon,
    required this.color,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tipo semântico de erro exibido pelo [FaixaErrorBanner].
enum FaixaErrorType { network, auth, validation, server, unknown }

/// Infere o [FaixaErrorType] a partir da mensagem amigável (pt-BR) produzida
/// pela camada de tradução de `ApiException` ou por validações locais.
FaixaErrorType inferFaixaErrorType(String message) {
  final m = message.toLowerCase();
  bool hasAny(List<String> tokens) => tokens.any(m.contains);

  if (hasAny(const [
    'sem conex',
    'tempo de resposta',
    'falha de comunica',
    'falar com o servidor',
    'comunicar com a api',
    'verifique sua conex',
  ])) {
    return FaixaErrorType.network;
  }
  if (hasAny(const [
    'erro interno',
    'servidor indispon',
    'muitas tentativas',
  ])) {
    return FaixaErrorType.server;
  }
  if (hasAny(const [
    'sess',
    'credenciais',
    'permiss',
    'token',
    'autentica',
    'acesso negado',
    'acesso restrito',
    'faca login',
    'faça login',
    'ativada',
    'tentativas excedido',
  ])) {
    return FaixaErrorType.auth;
  }
  if (hasAny(const [
    'dados inv',
    'e-mail válido',
    'muito curto',
    'muito longo',
    'obrigatór',
    'inválid',
    'já está em uso',
    'não confere',
    'revise os campos',
  ])) {
    return FaixaErrorType.validation;
  }
  return FaixaErrorType.unknown;
}

/// Banner de erro com ícone semântico por tipo e cor por severidade.
///
/// Segue o padrão visual Faixa (surface + hairline, sem bloco com alpha),
/// alinhado ao `AuthInlineFeedback` das telas de autenticação.
class FaixaErrorBanner extends StatelessWidget {
  const FaixaErrorBanner({super.key, required this.message, this.type});

  final String message;

  /// Quando nulo, o tipo é inferido da mensagem via [inferFaixaErrorType].
  final FaixaErrorType? type;

  @override
  Widget build(BuildContext context) {
    final resolved = type ?? inferFaixaErrorType(message);
    final (icon, color) = switch (resolved) {
      FaixaErrorType.network => (Icons.wifi_off_rounded, AppColors.warning),
      FaixaErrorType.auth => (Icons.lock_outline_rounded, AppColors.danger),
      FaixaErrorType.validation => (
        Icons.warning_amber_rounded,
        AppColors.warning,
      ),
      FaixaErrorType.server => (Icons.error_outline_rounded, AppColors.danger),
      FaixaErrorType.unknown => (
        Icons.error_outline_rounded,
        AppColors.danger,
      ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 13,
                color: color,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
