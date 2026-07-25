import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Shell visual das telas de autenticação.
///
/// Header amarelo cortado pela faixa diagonal reta da marca, com a logo
/// real, e o card de conteúdo sobreposto.
///
/// Mantém a API pública: [title], [subtitle], [child] e [showBack].
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = true,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _AuthHeader(showBack: showBack)),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -AppSpacing.xl),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 20,
                        offset: Offset(0, 8),
                        color: AppColors.shadowSubtle,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: textTheme.headlineSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.ink.withValues(alpha: 0.6),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.showBack});

  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ClipPath(
      clipper: _AuthHeaderClipper(),
      child: Container(
        color: AppColors.yellow,
        child: SafeArea(
          bottom: false,
          child: Padding(
            // O respiro inferior (xxxl = 48) é maior que a profundidade máxima
            // do corte diagonal (36 no _AuthHeaderClipper): a faixa sempre
            // corta área vazia do header, nunca o conteúdo.
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 44,
                  child: showBack
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.ink,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.surface.withValues(
                                alpha: 0.25,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.xxl),
                Center(
                  // Logo oficial direto sobre o amarelo, sem tile branco:
                  // logo_lockup.png é a variante transparente (sem variantes
                  // de densidade) prevista na skill de marca para superfícies
                  // amarelas — o logo.png tem variantes 2x-4x opacas.
                  child: Image.asset(
                    'assets/images/logo_lockup.png',
                    height: 96,
                    fit: BoxFit.contain,
                    semanticLabel: 'Faixa Amarela',
                    errorBuilder: (context, error, stackTrace) =>
                        const _LogoLoadError(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Faixa Amarela',
                  textAlign: TextAlign.center,
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Seu filho a caminho, você acompanhando',
                  textAlign: TextAlign.center,
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.ink.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Falha visível da logo: exibe o erro em vez de um ícone stock.
class _LogoLoadError extends StatelessWidget {
  const _LogoLoadError();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.danger.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          'logo_lockup.png\nnão encontrado',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.danger),
        ),
      ),
    );
  }
}

/// Faixa diagonal reta na base do header (corte estilo sinalização) —
/// substitui a curva genérica anterior.
class _AuthHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 36)
      ..lineTo(size.width, size.height - 8)
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Feedback inline para mensagens de erro/sucesso em telas de auth.
class AuthInlineFeedback extends StatelessWidget {
  const AuthInlineFeedback({
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
