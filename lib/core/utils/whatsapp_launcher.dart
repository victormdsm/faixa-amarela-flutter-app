import 'package:url_launcher/url_launcher.dart';

class WhatsAppLaunchResult {
  const WhatsAppLaunchResult({
    required this.success,
    this.errorMessage,
    this.normalizedPhone,
  });

  final bool success;
  final String? errorMessage;
  final String? normalizedPhone;
}

abstract final class WhatsAppLauncher {
  static Future<WhatsAppLaunchResult> openChat({
    required String? phone,
    required String contactName,
    String? message,
  }) async {
    final normalizedPhone = _normalizePhone(phone);
    if (normalizedPhone == null) {
      return WhatsAppLaunchResult(
        success: false,
        errorMessage: 'Telefone/WhatsApp nao informado para $contactName.',
      );
    }

    final text = (message == null || message.trim().isEmpty)
        ? 'Ola, vi seu perfil no app Faixa Amarela e gostaria de saber sobre o transporte escolar.'
        : message.trim();

    final uri = Uri.https('wa.me', '/$normalizedPhone', {'text': text});

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened) {
      return WhatsAppLaunchResult(
        success: false,
        normalizedPhone: normalizedPhone,
        errorMessage: 'Nao foi possivel abrir o WhatsApp neste dispositivo.',
      );
    }

    return WhatsAppLaunchResult(
      success: true,
      normalizedPhone: normalizedPhone,
    );
  }

  static String? _normalizePhone(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    var digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    if (digits.startsWith('00') && digits.length > 4) {
      digits = digits.substring(2);
    }

    // Assume BR local numbers when country code is omitted.
    if (!digits.startsWith('55') &&
        (digits.length == 10 || digits.length == 11)) {
      digits = '55$digits';
    }

    if (digits.length < 10) return null;
    return digits;
  }
}
