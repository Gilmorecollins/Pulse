import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../preferences/preferences_provider.dart';
import 'update_check_service.dart';
import 'version_compare.dart';

final updateCheckServiceProvider = Provider<UpdateCheckService>((ref) {
  return UpdateCheckService();
});

/// Non-null only when a genuinely newer release exists AND the user
/// hasn't already dismissed that specific version. Checked once per app
/// session (this provider is only read once, on Today's first build) —
/// no throttling beyond that needed for a personal app against GitHub's
/// public, unauthenticated rate limit.
final updateInfoProvider = FutureProvider<LatestRelease?>((ref) async {
  final release = await ref
      .read(updateCheckServiceProvider)
      .fetchLatestRelease();
  if (release == null) return null;

  final packageInfo = await PackageInfo.fromPlatform();
  if (!isVersionNewer(current: packageInfo.version, latest: release.version)) {
    return null;
  }

  final dismissed = await ref
      .read(preferencesRepositoryProvider)
      .getDismissedUpdateVersion();
  if (dismissed == release.version) return null;

  return release;
});
