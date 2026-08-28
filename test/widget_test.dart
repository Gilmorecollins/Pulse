import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pulse/app.dart';

void main() {
  testWidgets('Pulse launches to the Today screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PulseApp()));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text("TODAY'S PROGRESS"), findsOneWidget);
  });
}
