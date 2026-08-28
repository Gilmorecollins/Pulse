import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/notifications/notification_provider.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.initialize();

  final container = ProviderContainer(
    overrides: [
      notificationServiceProvider.overrideWithValue(notificationService),
    ],
  );

  // A tapped notification should always open its matching screen, whether
  // the app was already running or this tap is what launched it.
  notificationService.onNotificationTap.listen((payload) {
    switch (payload) {
      case 'checkin':
        container.read(routerProvider).go('/checkin');
      case 'reflection':
        container.read(routerProvider).go('/reflection');
    }
  });

  runApp(
    UncontrolledProviderScope(container: container, child: const PulseApp()),
  );
}
