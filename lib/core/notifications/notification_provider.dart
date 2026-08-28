import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_service.dart';

/// One NotificationService for the app's lifetime, initialized once in
/// main() before runApp (see lib/main.dart) so scheduling/tap-handling is
/// ready before the first frame.
final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError(
    'notificationServiceProvider must be overridden in main() with an '
    'already-initialized NotificationService.',
  );
});
