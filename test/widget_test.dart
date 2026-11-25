import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_app/data/learned_store.dart';
import 'package:hifz_app/data/plan.dart';
import 'package:hifz_app/data/plan_store.dart';
import 'package:hifz_app/screens/home_screen.dart';
import 'package:hifz_app/theme/tokens.dart';
import 'package:hifz_app/widgets/toast.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Task titles are drawn with non-breaking hyphens.
String nb(String s) => s.replaceAll('-', '\u2011');

void main() {
  setUp(() => HText.useGoogleFonts = false);

  late PlanStore plans;

  Future<void> home(WidgetTester tester, DateTime now, {VoidCallback? onOpenMethod}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: HomeScreen(
          bottomInset: 114,
          learned: LearnedStore.load(await SharedPreferences.getInstance()),
          plans: plans,
          onOpenMethod: onOpenMethod,
          now: now,
        ),
      ),
    ));
  }

  Future<void> fresh() async {
    SharedPreferences.setMockInitialValues({});
    plans = PlanStore.load(await SharedPreferences.getInstance());
  }

  Plan plan() => Plan(
        order: ReadingOrder.fromEnd,
        start: const Pos(114, 1),
        end: const Pos(78, 40),
        linesPerDay: 5,
        restWeekday: DateTime.friday,
        startDate: DateTime(2026, 11, 23),
      );

  testWidgets('with no plan, Home asks to set one up', (tester) async {
    await fresh();
    var opened = false;
    await home(tester, DateTime(2026, 11, 11, 15), onOpenMethod: () => opened = true);

    expect(find.text('Wednesday, 11 November'), findsOneWidget);
    expect(find.text('Good afternoon'), findsOneWidget);
    expect(find.text("TODAY'S PLAN"), findsOneWidget);
    expect(find.text('Hifdth is waiting for your plan'), findsOneWidget);
    expect(find.text('No plan yet'), findsOneWidget);
    expect(find.text('Nothing due today'), findsOneWidget);
    expect(find.text('0 days'), findsOneWidget);
    expect(find.bySemanticsLabel('Your plan'), findsNothing);

    await tester.tap(find.text('Set up my plan'));
    expect(opened, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('day 1 has one evening task; ticking it fills the goal and finishes the day', (tester) async {
    await fresh();
    await plans.save(plan(), today: DateTime(2026, 11, 23));
    await home(tester, DateTime(2026, 11, 23, 15));

    expect(find.text('Day 1/50'), findsOneWidget);
    expect(find.text(nb('An-Nas · Al-Falaq · Al-Ikhlas')), findsOneWidget);
    // The evening lesson: a moon tile and its tags.
    expect(find.byIcon(Icons.nightlight_round), findsOneWidget);
    expect(find.byIcon(Icons.wb_sunny_rounded), findsNothing);
    expect(find.text('Memorize'), findsOneWidget);
    expect(find.text('5 lines'), findsOneWidget);
    expect(find.text('by 22:00'), findsOneWidget);
    expect(find.text('1 left today'), findsOneWidget);
    // Your plan, as chips.
    expect(find.text('An-Nas → An-Naba'), findsOneWidget);
    expect(find.text('5 lines/day'), findsOneWidget);
    expect(find.bySemanticsLabel('Day 1/50'), findsOneWidget); // the strip
    expect(find.text('Friday off'), findsOneWidget);
    expect(find.bySemanticsLabel('Daily goal 0 percent'), findsOneWidget);

    await tester.tap(find.text(nb('An-Nas · Al-Falaq · Al-Ikhlas')));
    await tester.pump();
    expect(plans.isDone(DateTime(2026, 11, 23), 'new'), isTrue);
    expect(find.text('All done today'), findsOneWidget);
    expect(find.bySemanticsLabel('Daily goal 100 percent'), findsOneWidget);
    expect(find.text("Today's plan is done. Well done!"), findsWidgets); // the pill and the toast
    expect(find.text('1 day'), findsOneWidget);

    // Unticking takes it back.
    await tester.tap(find.text(nb('An-Nas · Al-Falaq · Al-Ikhlas')));
    await tester.pump();
    expect(find.text('1 left today'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Toast.hide(); // its timer would outlive the test
  });

  testWidgets('day 4 adds the morning recitation; a missed morning worries Hifdth', (tester) async {
    await fresh();
    await plans.save(plan(), today: DateTime(2026, 11, 23));
    await home(tester, DateTime(2026, 11, 26, 13));

    expect(find.text('Day 4/50'), findsOneWidget);
    expect(find.text(nb('An-Nas 1 → Quraysh 4')), findsOneWidget);
    // Morning (sun) comes first, then the evening (moon).
    expect(find.byIcon(Icons.wb_sunny_rounded), findsOneWidget);
    expect(find.byIcon(Icons.nightlight_round), findsOneWidget);
    expect(find.text('Recite 33×'), findsOneWidget);
    expect(tester.getTopLeft(find.byIcon(Icons.wb_sunny_rounded)).dy,
        lessThan(tester.getTopLeft(find.byIcon(Icons.nightlight_round)).dy));
    expect(find.text('Hifdth is getting worried…'), findsOneWidget);
  });

  testWidgets('the rest day says so', (tester) async {
    await fresh();
    await plans.save(plan(), today: DateTime(2026, 11, 23));
    await home(tester, DateTime(2026, 11, 27, 10)); // Friday

    expect(find.text('Rest day. Hifdth is resting too'), findsOneWidget);
    expect(find.text('Rest day'), findsOneWidget);
    expect(find.text('Nothing due today'), findsOneWidget);
  });
}
