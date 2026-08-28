import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/pulse_theme.dart';

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      theme: PulseTheme.light(),
      darkTheme: PulseTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
