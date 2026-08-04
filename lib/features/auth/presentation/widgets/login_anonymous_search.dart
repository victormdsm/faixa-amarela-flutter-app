import 'package:flutter/material.dart';

import '../../../../core/presentation/widgets/find_transport_button.dart';

/// Acesso anônimo à busca de transporte escolar: CTA primário em destaque
/// (antes era um TextButton discreto que passava despercebido no login).
class LoginAnonymousSearch extends StatelessWidget {
  const LoginAnonymousSearch({
    super.key,
    required this.onSearch,
    this.enabled = true,
  });

  final VoidCallback onSearch;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return FindTransportButton(onPressed: onSearch, enabled: enabled);
  }
}
