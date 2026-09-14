import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicktryandroidios/main.dart';

void main() {
  testWidgets('App loads cleanly smoke test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: EnglishTutorApp()));

    // Verify that the title bar displays Emma (AI Tutor)
    expect(find.text('Emma (AI Tutor)'), findsOneWidget);
  });
}
