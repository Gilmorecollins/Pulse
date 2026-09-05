import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/checkin/presentation/checkin_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/reflection/presentation/reflection_screen.dart';
import '../../features/report/presentation/report_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/today/presentation/today_screen.dart';
import '../../features/week/presentation/week_screen.dart';
import '../preferences/preferences_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/today',
    redirect: (context, state) async {
      final onboardingComplete =
          await ref.read(preferencesRepositoryProvider).isOnboardingComplete();
      final goingToOnboarding = state.matchedLocation == '/onboarding';

      if (!onboardingComplete && !goingToOnboarding) return '/onboarding';
      if (onboardingComplete && goingToOnboarding) return '/today';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/checkin/:taskId',
        builder: (context, state) =>
            TaskCheckInScreen(taskId: state.pathParameters['taskId']!),
      ),
      GoRoute(
        path: '/reflection',
        builder: (context, state) => const ReflectionScreen(),
      ),
      GoRoute(
        path: '/report/:planId',
        builder: (context, state) =>
            ReportScreen(planId: state.pathParameters['planId']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _PulseNavShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/week',
                builder: (context, state) => const WeekScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/insights',
                builder: (context, state) => const InsightsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _PulseNavShell extends StatelessWidget {
  const _PulseNavShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(SolarIconsOutline.calendarDate),
            selectedIcon: Icon(SolarIconsBold.calendarDate),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(SolarIconsOutline.calendarMinimalistic),
            selectedIcon: Icon(SolarIconsBold.calendarMinimalistic),
            label: 'Week',
          ),
          NavigationDestination(
            icon: Icon(SolarIconsOutline.history),
            selectedIcon: Icon(SolarIconsBold.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(SolarIconsOutline.chart),
            selectedIcon: Icon(SolarIconsBold.chart),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(SolarIconsOutline.settings),
            selectedIcon: Icon(SolarIconsBold.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
