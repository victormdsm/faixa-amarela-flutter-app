import 'dart:convert';

/// Notificação exibida na central do app (lista + detalhe).
///
/// O `GET /notifications` do backend NestJS devolve `title`/`body` no topo.
/// Registros legados escritos pelo Laravel (canal `database`, ex.:
/// `DriverParentAlertNotification`) guardam o texto dentro do JSON de `data`
/// (`custom_message`, `body`, `title`) e podem vir com as colunas de topo
/// vazias — por isso o parse faz fallback para `data`, sempre priorizando o
/// `body` de topo quando presente. `data` também pode chegar como String JSON
/// (coluna `text` legada); nesse caso é decodificada. O conteúdo de `data`
/// nunca é exibido cru para o usuário.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final DateTime? createdAt;
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = _parseData(json['data']);
    return AppNotification(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      title: _firstNonBlank([json['title'], data['title']]) ?? 'Notificação',
      // O texto real do motorista: prioriza o body de topo; em registros
      // legados, cai para a mensagem guardada no payload `data`.
      body:
          _firstNonBlank([
            json['body'],
            data['custom_message'],
            data['body'],
            data['message'],
          ]) ??
          '',
      data: data,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      readAt: DateTime.tryParse((json['readAt'] ?? '').toString()),
    );
  }

  static Map<String, dynamic> _parseData(Object? raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } on FormatException {
        // Payload ilegível não é informação para o usuário — ignora.
      }
    }
    return const {};
  }

  static String? _firstNonBlank(List<Object?> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }
}
