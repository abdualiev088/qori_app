import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qori_app/data/learned_store.dart';
import 'package:qori_app/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qori_app/theme/tokens.dart';

void main() {
  setUp(() => HText.useGoogleFonts = false);

  testWidgets('home shows the greeting, progress and streak', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    final learned = LearnedStore.load(await SharedPreferences.getInstance());
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: HomeScreen(bottomInset: 114, learned: learned, now: DateTime(2026, 11, 11, 15))),
    ));

    expect(find.text('Wednesday, 11 November'), findsOneWidget);
    expect(find.text('Good afternoon'), findsOneWidget);
    expect(find.text("TODAY'S PROGRESS"), findsOneWidget);
    expect(find.text('Evening session'), findsOneWidget);
    expect(find.text('67%'), findsOneWidget);
    expect(find.text('5 days'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
