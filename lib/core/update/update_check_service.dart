import 'dart:convert';

import 'package:http/http.dart' as http;

/// A GitHub release, trimmed to what the update banner needs.
class LatestRelease {
  LatestRelease({
    required this.version,
    required this.releaseUrl,
    required this.name,
  });

  /// The release's tag with any leading 'v' stripped (e.g. "1.1.0").
  final String version;
  final String releaseUrl;
  final String name;
}

/// Checks GitHub's public releases API for this repo — no auth needed
/// since the repo is public; if it's ever made private this will start
/// silently failing closed (404), which is the right behavior (see
/// docs/ARCHITECTURE.md's Update check section).
class UpdateCheckService {
  UpdateCheckService({this.repo = 'Gilmorecollins/Pulse'});

  final String repo;

  /// Never throws — any network/parse failure resolves to null, exactly
  /// like "no update available", so a flaky connection or a temporary
  /// GitHub API hiccup never surfaces as an error to the user for a
  /// purely optional check.
  Future<LatestRelease?> fetchLatestRelease() async {
    try {
      final response = await http
          .get(Uri.parse('https://api.github.com/repos/$repo/releases/latest'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final tag = json['tag_name'] as String?;
      final url = json['html_url'] as String?;
      if (tag == null || url == null) return null;

      return LatestRelease(
        version: tag.startsWith('v') ? tag.substring(1) : tag,
        releaseUrl: url,
        name: (json['name'] as String?) ?? tag,
      );
    } catch (_) {
      return null;
    }
  }
}
