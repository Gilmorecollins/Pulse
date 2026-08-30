import 'package:flutter/material.dart';

import '../../../core/widgets/coming_soon.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: ComingSoon(
          icon: Icons.settings_outlined,
          title: 'Settings',
          message: 'Profile, check-in frequency, quiet hours and theme '
              'will live here (Phase 2).',
        ),
      ),
    );
  }
}
