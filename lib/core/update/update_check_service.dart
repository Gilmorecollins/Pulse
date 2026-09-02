import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A GitHub release, trimmed to what the update banner needs.
class LatestRelease {
  LatestRelease({
    required this.version,
    required this.releaseUrl,
    required this.name,
    this.apkDownloadUrl,
  });

  /// The release's tag with any leading 'v' stripped (e.g. "1.1.0").
  final String version;
  final String releaseUrl;
  final String name;

  /// Direct download URL for the release's .apk asset, if one was
  /// attached. Null falls back to opening [releaseUrl] in the browser
  /// instead of an in-app download.
  final String? apkDownloadUrl;
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

      Map<String, dynamic>? apkAsset;
      for (final asset in (json['assets'] as List<dynamic>? ?? const [])) {
        final map = asset as Map<String, dynamic>;
        if ((map['name'] as String? ?? '').toLowerCase().endsWith('.apk')) {
          apkAsset = map;
          break;
        }
      }

      return LatestRelease(
        version: tag.startsWith('v') ? tag.substring(1) : tag,
        releaseUrl: url,
        name: (json['name'] as String?) ?? tag,
        apkDownloadUrl: apkAsset?['browser_download_url'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// Downloads [url] to a fixed filename in the temp directory,
  /// overwriting any previous download. Reports 0.0-1.0 progress via
  /// [onProgress] when the server declares a content length.
  Future<File> downloadApk(
    String url, {
    void Function(double progress)? onProgress,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final file = File(p.join(tempDir.path, 'pulse_update.apk'));
    if (await file.exists()) {
      await file.delete();
    }

    final client = http.Client();
    try {
      final response = await client
          .send(http.Request('GET', Uri.parse(url)))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw StateError('Download failed (HTTP ${response.statusCode}).');
      }

      final total = response.contentLength;
      var received = 0;
      final sink = file.openWrite();
      await response.stream
          .map((chunk) {
            received += chunk.length;
            if (total != null && total > 0) {
              onProgress?.call(received / total);
            }
            return chunk;
          })
          .pipe(sink);
    } finally {
      client.close();
    }
    return file;
  }

  /// Hands the downloaded APK to Android's package installer. Android
  /// still requires the user's own tap on the resulting confirmation
  /// screen (and, the first time, a tap through "allow installs from
  /// this app") — nothing here installs silently.
  Future<void> installApk(File file) async {
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      throw StateError(result.message);
    }
  }
}
