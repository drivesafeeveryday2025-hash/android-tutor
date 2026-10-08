import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quicktryandroidios/main.dart';

void main() {
  testWidgets('App loads frontpage and navigates to conversation test',
      (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: EnglishTutorApp()));
    await tester.pumpAndSettle();

    // Verify that the frontpage headline and CTA button are displayed
    expect(find.text('Speak English with Confidence'), findsOneWidget);
    expect(find.text('Try Out English Tutor'), findsOneWidget);

    // Tap the 'Try Out English Tutor' button to enter conversation
    final buttonFinder = find.text('Try Out English Tutor');
    await tester.ensureVisible(buttonFinder);
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    // Verify that the conversation screen displays Chole (AI Tutor) in the AppBar
    expect(find.text('Chole (AI Tutor)'), findsOneWidget);
  });
}
