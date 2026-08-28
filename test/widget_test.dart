import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pulse/app.dart';
import 'package:pulse/core/database/database.dart';
import 'package:pulse/core/database/database_provider.dart';

Widget _appWithMemoryDb() {
  return ProviderScope(
    overrides: [
      databaseProvider.overrideWithValue(
        PulseDatabase.forTesting(NativeDatabase.memory()),
      ),
    ],
    child: const PulseApp(),
  );
}

/// Dispose the widget tree (and with it the database's stream
/// subscriptions) before the test ends, then pump once more so Drift's
/// cleanup timer fires instead of leaking past the test boundary.
Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  setUpAll(() {
    // Each test opens its own isolated in-memory database; Drift's
    // multiple-instance warning is a false positive here.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  testWidgets('a fresh install shows onboarding, not Today', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(_appWithMemoryDb());
    await tester.pumpAndSettle();

    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text("TODAY'S PROGRESS"), findsNothing);

    await _dispose(tester);
  });

  testWidgets('a returning user lands on the Today screen', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_complete': true,
      'user_name': 'Test User',
      'check_in_time': '13:00',
      'report_time': '20:00',
    });

    await tester.pumpWidget(_appWithMemoryDb());
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text("TODAY'S PROGRESS"), findsOneWidget);

    await _dispose(tester);
  });
}
