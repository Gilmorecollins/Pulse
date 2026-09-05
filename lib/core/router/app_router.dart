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

typedef _NavItemData = ({
  IconData icon,
  IconData selectedIcon,
  String label,
  Color color,
});

// One accent per tab, shown only while that tab is active — muted
// gray otherwise (see _NavItem). Moderate saturation, similar
// brightness across all five so none reads as more "important" than
// the others; kept out of the app's semantic colors (PulseColors.coral
// is reserved for errors) to avoid implying a status.
const _navItems = <_NavItemData>[
  (
    icon: SolarIconsOutline.calendarDate,
    selectedIcon: SolarIconsBold.calendarDate,
    label: 'Today',
    color: Color(0xFF3F5E96), // navyBlue — the brand primary
  ),
  (
    icon: SolarIconsOutline.calendarMinimalistic,
    selectedIcon: SolarIconsBold.calendarMinimalistic,
    label: 'Week',
    color: Color(0xFF7C5CBF), // violet
  ),
  (
    icon: SolarIconsOutline.history,
    selectedIcon: SolarIconsBold.history,
    label: 'History',
    color: Color(0xFFC98A3E), // amber
  ),
  (
    icon: SolarIconsOutline.chart,
    selectedIcon: SolarIconsBold.chart,
    label: 'Insights',
    color: Color(0xFF2F9E77), // teal green
  ),
  (
    icon: SolarIconsOutline.settings,
    selectedIcon: SolarIconsBold.settings,
    label: 'Settings',
    color: Color(0xFF5C6B7A), // slate
  ),
];

class _PulseNavShell extends StatelessWidget {
  const _PulseNavShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _FloatingNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// A custom floating capsule rather than Material's stock NavigationBar
/// wrapped in extra chrome — that combination fought back with sizing
/// that didn't respond predictably to explicit height overrides once
/// nested in custom decoration. Building the bar directly here keeps
/// every dimension explicit and controllable.
class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Material(
          // A light, brand-tinted pill (the same secondaryContainer tone
          // already used for badges/pills elsewhere in Settings) rather
          // than plain gray or a stark dark card — visibly separated
          // from the page's near-white "mist" background via hue rather
          // than a jarring lightness jump, with the shadow doing the
          // rest of the "floating" work.
          color: scheme.secondaryContainer,
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(28),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < _navItems.length; i++)
                  _NavItem(
                    item: _navItems[i],
                    selected: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItemData item;
  final bool selected;
  final VoidCallback onTap;

  static const _duration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Selection is shown purely through color/weight, no extra shape
    // wrapping just the icon — that read as a disconnected floating
    // card, only around the icon and not the label beneath it. Each
    // tab's own accent only appears while it's active; inactive tabs
    // fall back to the same muted gray so exactly one color pops at a
    // time instead of a permanently "rainbow" bar.
    final color = selected
        ? item.color
        : scheme.onSecondaryContainer.withValues(alpha: 0.6);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: selected ? 1.12 : 1.0,
              duration: _duration,
              curve: Curves.easeOut,
              // Icon glyphs (outline vs bold) can't morph into each
              // other, so the swap crossfades instead — combined with
              // the color/scale change, it still reads as one smooth
              // transition rather than an abrupt cut.
              child: AnimatedSwitcher(
                duration: _duration,
                transitionBuilder: (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  key: ValueKey(selected),
                  color: color,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: _duration,
              style:
                  (Theme.of(context).textTheme.labelSmall ??
                          const TextStyle())
                      .copyWith(
                        color: color,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}
