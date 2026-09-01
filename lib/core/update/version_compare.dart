/// True if [latest] is a strictly newer dot-separated version than
/// [current]. Tolerant of a leading 'v' (GitHub tag style, e.g. "v1.2.0")
/// and a trailing '+build' suffix (pubspec style, e.g. "1.2.0+3") on
/// either side. Any non-numeric component is treated as 0 rather than
/// throwing — a malformed tag should just never look "newer", not crash
/// the update check.
bool isVersionNewer({required String current, required String latest}) {
  final currentParts = _numericParts(current);
  final latestParts = _numericParts(latest);
  final length = currentParts.length > latestParts.length
      ? currentParts.length
      : latestParts.length;

  for (var i = 0; i < length; i++) {
    final c = i < currentParts.length ? currentParts[i] : 0;
    final l = i < latestParts.length ? latestParts[i] : 0;
    if (l != c) return l > c;
  }
  return false;
}

List<int> _numericParts(String version) {
  final trimmed = version.trim();
  final withoutV = trimmed.startsWith(RegExp('[vV]'))
      ? trimmed.substring(1)
      : trimmed;
  final withoutBuild = withoutV.split('+').first;
  return withoutBuild.split('.').map((p) => int.tryParse(p) ?? 0).toList();
}
