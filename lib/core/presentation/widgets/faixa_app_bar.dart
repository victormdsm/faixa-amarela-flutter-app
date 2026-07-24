import 'package:flutter/material.dart';

/// AppBar padronizado do app Faixa Amarela.
///
/// O visual unificado vem do [AppBarTheme]: fundo branco, texto e ícones
/// ink e a faixa amarela de 4px na borda inferior.
///
/// Use [FaixaAppBar.portal] na home de cada perfil (logo oficial
/// centralizada). Use [FaixaAppBar.screen] em telas internas/push (título
/// alinhado à esquerda, botão voltar).
class FaixaAppBar extends StatelessWidget implements PreferredSizeWidget {
  const FaixaAppBar._({
    super.key,
    this.title,
    this.centerTitle = false,
    this.leading,
    this.actions,
  });

  /// AppBar da home do portal — logo oficial centralizada.
  factory FaixaAppBar.portal({Key? key, List<Widget>? actions}) {
    return FaixaAppBar._(
      key: key,
      centerTitle: true,
      title: Image.asset(
        'assets/images/logo.png',
        height: 40,
        fit: BoxFit.contain,
        semanticLabel: 'Faixa Amarela',
        errorBuilder: (context, error, stackTrace) => Text(
          'Faixa Amarela',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      actions: actions,
    );
  }

  /// AppBar de telas internas — título da tela à esquerda, com voltar.
  factory FaixaAppBar.screen({
    Key? key,
    required String title,
    List<Widget>? actions,
    bool showBack = true,
    VoidCallback? onBack,
  }) {
    return FaixaAppBar._(
      key: key,
      title: Text(title),
      leading: showBack
          ? Builder(
              builder: (context) => IconButton(
                tooltip: 'Voltar',
                onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
            )
          : null,
      actions: actions,
    );
  }

  final Widget? title;
  final bool centerTitle;
  final Widget? leading;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: centerTitle,
      title: title,
      leading: leading,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
