import 'package:flutter/material.dart';

import '../../../core/widgets/coming_soon.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: ComingSoon(
          icon: Icons.insights_outlined,
          title: 'Insights',
          message: 'Pulse Insights will appear once there\'s enough '
              'history to make them meaningful.',
        ),
      ),
    );
  }
}
