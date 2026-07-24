/// Formata uma duração em segundos para exibição legível.
String formatEta(int seconds) {
  if (seconds < 60) return '${seconds}s';
  if (seconds < 3600) return '${(seconds / 60).round()} min';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  return '${h}h ${m}min';
}

/// Formata uma distância em metros para exibição legível.
String formatDistance(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}
