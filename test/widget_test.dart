// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:smartpen/main.dart';

void main() {
  testWidgets('SmartPen app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SmartPenApp(showOnboarding: false, isLoggedIn: true));

    // Verify that the app loads and displays the title
    expect(find.text('SmartPen Studio'), findsOneWidget);
    expect(find.text('Disconnected'), findsOneWidget);
  });
}
