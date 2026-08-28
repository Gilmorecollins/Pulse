import 'package:flutter/material.dart';

import '../../../core/widgets/coming_soon.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: ComingSoon(
          icon: Icons.history,
          title: 'History',
          message: 'Past days will show up here once you\'ve completed '
              'a few daily reports.',
        ),
      ),
    );
  }
}
