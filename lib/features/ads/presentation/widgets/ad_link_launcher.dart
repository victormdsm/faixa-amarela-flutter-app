import 'package:url_launcher/url_launcher.dart';

/// Abre o link do anúncio com fallback entre os modos de launch.
Future<void> openAdLink(String link) async {
  final uri = _normalizeUri(link);
  if (uri == null) return;

  final openedExternally = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  );
  if (openedExternally) return;

  final openedDefault = await launchUrl(uri, mode: LaunchMode.platformDefault);
  if (openedDefault) return;

  await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
}

Uri? _normalizeUri(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;

  final parsed = Uri.tryParse(trimmed);
  if (parsed != null && parsed.hasScheme) {
    return parsed;
  }

  return Uri.tryParse('https://$trimmed');
}
