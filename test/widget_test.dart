// LONE LINK — Widget Test (smoke test)
//
// Verifies the app can be instantiated without errors.
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lone_link/presentation/app.dart';

void main() {
  testWidgets('App renders without errors', (WidgetTester tester) async {
    // Build the app wrapped in ProviderScope.
    await tester.pumpWidget(
      const ProviderScope(
        child: LoneLinkApp(),
      ),
    );

    // Verify the splash screen shows (first screen after launch).
    // The app title should appear in the splash screen.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('LONE LINK'), findsOneWidget);
    expect(find.text('Decentralized Messaging'), findsOneWidget);
  });
}
