String normalizeAlign(String raw) {
  final a = raw.toLowerCase().trim();
  if (a.contains('good')) return 'good';
  if (a.contains('bad') || a.contains('evil')) return 'bad';
  return 'neutral';
}