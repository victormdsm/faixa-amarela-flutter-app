abstract final class Validators {
  static bool isValidEmail(String value) {
    final email = value.trim();
    if (email.isEmpty) return false;
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(email);
  }

  static String? email(String value) {
    if (value.trim().isEmpty) {
      return 'E-mail e obrigatorio.';
    }
    if (!isValidEmail(value)) {
      return 'Informe um e-mail valido.';
    }
    return null;
  }

  static String? loginIdentifier(String value) {
    if (value.trim().isEmpty) {
      return 'Informe e-mail ou CPF.';
    }
    if (value.trim().length < 3) {
      return 'Informe um login valido.';
    }
    return null;
  }

  static String? password(String value) {
    if (value.trim().isEmpty) {
      return 'Senha e obrigatoria.';
    }
    if (value.trim().length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    return null;
  }

  static String? requiredField(String value, {String fieldName = 'Campo'}) {
    if (value.trim().isEmpty) {
      return '$fieldName e obrigatorio.';
    }
    return null;
  }

  static String? cpf(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'CPF e obrigatorio.';
    if (digits.length != 11) return 'Informe um CPF valido.';
    return null;
  }

  static String? phone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Telefone e obrigatorio.';
    if (digits.length < 10) return 'Informe um telefone valido.';
    return null;
  }
}
