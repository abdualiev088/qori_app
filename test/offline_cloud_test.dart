import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qori_app/data/auth_api.dart';
import 'package:qori_app/data/learned_store.dart';
import 'package:qori_app/screens/home_screen.dart';
import 'package:qori_app/theme/tokens.dart';
import 'package:qori_app/widgets/hifdth_card.dart';
import 'package:qori_app/widgets/quran_progress_card.dart';
import 'package:qori_app/widgets/signed_out_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_auth_api.dart';
import 'l10n_en.dart';

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
    final auth = FakeAuthApi()..user = const QoriUser(id: '1', email: 'a@b.co');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: HomeScreen(bottomInset: 0, learned: learned, auth: auth, now: DateTime(2026, 11, 19, 9))),
    ));
    expect(find.byIcon(Icons.cloud_off_rounded), findsNothing);

    auth.online.value = false;
    await settle(tester);
    expect(find.byIcon(Icons.cloud_off_rounded), findsOneWidget);

    // It keeps gently pulsing while offline.
    double cloudScale() => tester
        .widget<ScaleTransition>(
            find.ancestor(of: find.byIcon(Icons.cloud_off_rounded), matching: find.byType(ScaleTransition)).first)
        .scale
        .value;
    final before = cloudScale();
    await tester.pump(const Duration(milliseconds: 400));
    expect(cloudScale(), isNot(before));

    auth.online.value = true;
    await settle(tester);
    expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off_rounded), findsNothing);

    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(find.byIcon(Icons.cloud_done_rounded), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('signed out, only the Quran progress card is swapped for the sign-in card', (tester) async {
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
    await tester.pump();

    expect(find.byType(SignedOutCard), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.byType(QuranProgressCard), findsNothing); // nothing to change
    expect(find.byType(HifdthCard), findsOneWidget); // the rest of Home stays
    expect(find.bySemanticsLabel('Profile'), findsNothing); // the account lives in Settings

    auth.user = const QoriUser(id: '1', email: 'a@b.co');
    await tester.pump();
    expect(find.byType(SignedOutCard), findsNothing);
    expect(find.byType(QuranProgressCard), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the signed-out card\'s prompt types itself in when it speaks', (tester) async {
    Widget card(bool speaking) => MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: SignedOutCard(onSignIn: () {}, onRegister: () {}, speaking: speaking)),
          ),
        );
    double lastWordAlpha() {
      final spans = (tester.widget<Text>(find.text(en.signInBubble)).textSpan! as TextSpan).children!;
      return (spans.last as TextSpan).style!.color!.a;
    }

    await tester.pumpWidget(card(false));
    expect(lastWordAlpha(), 0);

    await tester.pumpWidget(card(true));
    await tester.pump(const Duration(milliseconds: 60));
    expect(lastWordAlpha(), lessThan(1)); // still typing
    await tester.pump(const Duration(seconds: 1));
    expect(lastWordAlpha(), 1);
    expect(find.text('HIFZ'), findsNothing);
  });
}
