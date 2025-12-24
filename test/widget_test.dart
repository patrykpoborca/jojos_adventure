import 'package:flutter_test/flutter_test.dart';

import 'package:memory_lane/main.dart';

void main() {
  testWidgets('App loads without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MemoryLaneApp());

    // Verify the app renders (loading screen should appear)
    expect(find.text('Loading memories...'), findsOneWidget);
  });
}
