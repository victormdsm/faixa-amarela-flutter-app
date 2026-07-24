import 'package:flutter/services.dart';

/// Coleção de [TextInputFormatter]s customizados para campos comuns do app.
///
/// Todos os formatters mantêm apenas os dígitos no valor final e atualizam a
/// posição do cursor de forma conservadora (preserva a posição relativa ao
/// texto digitado).
abstract final class InputFormatters {
  /// CPF: `000.000.000-00`
  static TextInputFormatter cpf() => const _CpfInputFormatter();

  /// Telefone: `(00) 0000-0000` ou `(00) 00000-0000`
  static TextInputFormatter phone() => const _PhoneInputFormatter();

  /// CEP: `00000-000`
  static TextInputFormatter cep() => const _CepInputFormatter();

  /// Data de nascimento: `00/00/0000`
  static TextInputFormatter date() => const _DateInputFormatter();

  static String _apply(TextInputFormatter formatter, String digits) {
    return formatter
        .formatEditUpdate(
          TextEditingValue.empty,
          TextEditingValue(text: digits.replaceAll(RegExp(r'\D'), '')),
        )
        .text;
  }

  /// Formata uma string de dígitos como CPF.
  static String formatCpf(String value) => _apply(cpf(), value);

  /// Formata uma string de dígitos como telefone.
  static String formatPhone(String value) => _apply(phone(), value);

  /// Formata uma string de dígitos como CEP.
  static String formatCep(String value) => _apply(cep(), value);

  /// Formata uma string de dígitos como data de nascimento.
  static String formatDate(String value) => _apply(date(), value);
}

class _CpfInputFormatter extends TextInputFormatter {
  const _CpfInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;

    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(limited[i]);
    }

    final text = buffer.toString();
    final selection = _computeSelection(newValue, oldValue, text);
    return TextEditingValue(text: text, selection: selection);
  }
}

class _PhoneInputFormatter extends TextInputFormatter {
  const _PhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 11) digits = digits.substring(0, 11);

    final buffer = StringBuffer();
    if (digits.isNotEmpty) buffer.write('(');
    for (var i = 0; i < digits.length; i++) {
      if (i == 2) buffer.write(') ');
      if (i == 7 && digits.length == 11) buffer.write('-');
      if (i == 6 && digits.length == 10) buffer.write('-');
      buffer.write(digits[i]);
    }

    final text = buffer.toString();
    final selection = _computeSelection(newValue, oldValue, text);
    return TextEditingValue(text: text, selection: selection);
  }
}

class _CepInputFormatter extends TextInputFormatter {
  const _CepInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 5) buffer.write('-');
      buffer.write(digits[i]);
    }

    final text = buffer.toString();
    final selection = _computeSelection(newValue, oldValue, text);
    return TextEditingValue(text: text, selection: selection);
  }
}

class _DateInputFormatter extends TextInputFormatter {
  const _DateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 8) digits = digits.substring(0, 8);

    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(digits[i]);
    }

    final text = buffer.toString();
    final selection = _computeSelection(newValue, oldValue, text);
    return TextEditingValue(text: text, selection: selection);
  }
}

/// Calcula a nova posição do cursor após a formatação.
///
/// A estratégia mantém a posição absoluta do cursor dentro dos limites do novo
/// texto. Se o usuário estiver apagando, mantém a posição de inserção próxima
/// do que havia antes; se estiver digitando, avança o cursor quando um
/// caractere de formatação é pulado automaticamente.
TextSelection _computeSelection(
  TextEditingValue newValue,
  TextEditingValue oldValue,
  String formattedText,
) {
  final rawCursor = newValue.selection.baseOffset;
  if (rawCursor <= 0) {
    return const TextSelection.collapsed(offset: 0);
  }

  final raw = newValue.text;
  var formattedOffset = 0;
  var rawOffset = 0;

  while (rawOffset < rawCursor && formattedOffset < formattedText.length) {
    if (rawOffset < raw.length && raw[rawOffset] == formattedText[formattedOffset]) {
      rawOffset++;
      formattedOffset++;
    } else if (!_isDigit(formattedText[formattedOffset])) {
      formattedOffset++;
    } else {
      rawOffset++;
    }
  }

  // Se o usuário digitou um dígito que resultou em separador logo em seguida,
  // avançamos o cursor para depois do separador.
  while (formattedOffset < formattedText.length &&
      !_isDigit(formattedText[formattedOffset])) {
    formattedOffset++;
  }

  final offset = formattedOffset.clamp(0, formattedText.length);
  return TextSelection.collapsed(offset: offset);
}

bool _isDigit(String char) => char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57;
