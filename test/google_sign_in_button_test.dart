import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sub_tv/feature/auth/presentation/widget/google_sign_in_button.dart';

void main() {
  testWidgets('renders the official asset without layout errors and fires '
      'onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GoogleSignInButton(onPressed: () => tapped = true),
          ),
        ),
      ),
    );

    expect(find.byType(GoogleSignInButton), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(GoogleSignInButton));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('pending shows a spinner and blocks taps', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GoogleSignInButton(
              onPressed: () => tapped = true,
              pending: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(GoogleSignInButton));
    await tester.pump();
    expect(tapped, isFalse);
  });
}
