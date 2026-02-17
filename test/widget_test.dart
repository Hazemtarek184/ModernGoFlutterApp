import 'package:flutter_test/flutter_test.dart';
import 'package:modern_go/main.dart';

void main() {
  testWidgets('App should load login page', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ModernGoApp());

    // Verify that we are on the Login page
    expect(find.text('Log In'), findsOneWidget);
  });
}
