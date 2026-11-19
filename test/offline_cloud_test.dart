import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qori_app/data/learned_store.dart';
import 'package:qori_app/screens/home_screen.dart';
import 'package:qori_app/theme/tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_api.dart';

/// Starts the cross-fade on one frame and lets it finish (Hifdth never settles).
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump();
}

void main() {
  setUp(() => HText.useGoogleFonts = false);

  testWidgets('the cloud shows offline, turns green when back online, then goes', (tester) async {
    tester.view
      ..physicalSize = const Size(402, 874)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final learned = LearnedStore.load(await SharedPreferences.getInstance());
    final auth = FakeAuthApi();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: HomeScreen(bottomInset: 0, learned: learned, auth: auth, now: DateTime(2026, 11, 19, 9))),
    ));
    expect(find.byIcon(Icons.cloud_off_rounded), findsNothing);

    auth.online.value = false;
    await settle(tester);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);

    auth.online.value = true;
    await settle(tester);
    expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(find.byIcon(Icons.cloud_done_rounded), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
