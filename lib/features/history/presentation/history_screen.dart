import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/coming_soon.dart';
import '../../report/presentation/report_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(reportHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: SafeArea(
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "We couldn't load your history. Check your connection "
                    'and try again.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(reportHistoryProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (reports) => reports.isEmpty
              ? const ComingSoon(
                  icon: SolarIconsOutline.history,
                  title: 'History',
                  message: 'Past days will show up here once you\'ve '
                      'completed a daily reflection.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: reports.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    final pct = (report.completionRate * 100).round();
                    return Card(
                      child: ListTile(
                        title: Text(
                          DateFormat('d MMMM yyyy').format(report.date),
                        ),
                        trailing: Text(
                          '$pct% completed',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        onTap: () =>
                            context.push('/report/${report.dailyPlanId}'),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
