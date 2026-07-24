import 'package:intl/intl.dart';

/// Formatadores de data e hora padronizados em pt-BR.
///
/// Depende de `initializeDateFormatting('pt_BR', null)` chamado no `main.dart`.
final DateFormat _dateTimeFormatter = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
final DateFormat _dateFormatter = DateFormat('dd/MM/yyyy', 'pt_BR');

/// Formata data e hora no padrão brasileiro: `dd/mm/aaaa hh:mm` (hora local).
String formatDateTime(DateTime? value) {
  final local = value?.toLocal();
  if (local == null) return 'Data não informada';
  return _dateTimeFormatter.format(local);
}

/// Tempo relativo em pt-BR: `agora mesmo`, `há X min`, `há X h`, `ontem`
/// ou `dd/mm/aaaa` para datas mais antigas.
String timeAgo(DateTime? value, {DateTime? now}) {
  final local = value?.toLocal();
  if (local == null) return '';
  final reference = (now ?? DateTime.now()).toLocal();
  final difference = reference.difference(local);

  if (difference.isNegative || difference.inMinutes < 1) {
    return 'agora mesmo';
  }
  if (difference.inMinutes < 60) {
    return 'há ${difference.inMinutes} min';
  }
  if (_isSameDay(reference, local)) {
    return 'há ${difference.inHours} h';
  }
  final yesterday = reference.subtract(const Duration(days: 1));
  if (_isSameDay(yesterday, local)) {
    return 'ontem';
  }
  return _dateFormatter.format(local);
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
