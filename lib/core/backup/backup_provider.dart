import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'google_drive_service.dart';

/// One GoogleDriveService for the app's lifetime, silently signed in once
/// in main() before runApp (see lib/main.dart) — same pattern as
/// notificationServiceProvider.
final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  throw UnimplementedError(
    'googleDriveServiceProvider must be overridden in main() with an '
    'already-initialized GoogleDriveService.',
  );
});
