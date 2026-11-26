import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qori_app/data/learned_store.dart';
import 'package:qori_app/data/plan.dart';
import 'package:qori_app/data/plan_store.dart';
import 'package:qori_app/screens/home_screen.dart';
import 'package:qori_app/widgets/hifdth_card.dart';
import 'package:qori_app/widgets/hifdth_mood.dart';
import 'package:qori_app/theme/tokens.dart';
import 'package:qori_app/widgets/toast.dart';
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

    // No plan: no day pill or week strip yet.
    expect(find.bySemanticsLabel(RegExp('Open the calendar')), findsNothing);
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
    for (final d in [23, 24, 25]) {
      await plans.toggle(DateTime(2026, 11, d), 'new'); // every evening learned
    }
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

  testWidgets('the calendar steps through days; other days show their tasks but cannot be ticked', (tester) async {
    await fresh();
    await plans.save(plan(), today: DateTime(2026, 11, 23));
    await plans.toggle(DateTime(2026, 11, 23), 'new'); // Monday done
    await plans.toggle(DateTime(2026, 11, 24), 'm33'); // Tuesday partly
    await home(tester, DateTime(2026, 11, 26, 13)); // Thursday

    expect(find.text('Today'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Thursday, 26, Today')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Monday, 23, Done')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Wednesday, 25, Missed')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Friday, 27, Rest day')), findsOneWidget);

    // Tuesday's and Wednesday's evening lessons weren't learned: two days skipped.
    expect(find.text('Day 4/52'), findsOneWidget);
    expect(find.textContaining('Skipped 2 days · finish moved to'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Previous day'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('WED, 25 NOV'), findsOneWidget);
    expect(find.text('Missed that day'), findsOneWidget);
    expect(find.text('Day 3/52'), findsOneWidget);
    // Lesson 2 again, since Tuesday's evening wasn't learned.
    expect(find.text(nb('Al-Masad · An-Nasr · Al-Kafirun')), findsOneWidget);
    // A missed day: Hifdth is sad and each unticked task shows a red cross.
    expect(tester.widget<HifdthCard>(find.byType(HifdthCard)).mood, HifdthMood.sad);
    expect(find.byIcon(Icons.close_rounded), findsNWidgets(3)); // the strip's badge + two tasks
    // Looking back doesn't tick anything.
    await tester.tap(find.text(nb('Al-Masad · An-Nasr · Al-Kafirun')));
    await tester.pump();
    expect(plans.isDone(DateTime(2026, 11, 25), 'new'), isFalse);

    // The month: pick Monday the 23rd.
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Yesterday\. Open the calendar')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('November 2026'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Monday, 23 November, Done')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('MON, 23 NOV'), findsOneWidget);
    expect(find.text('All done that day'), findsOneWidget);
    expect(tester.widget<HifdthCard>(find.byType(HifdthCard)).mood, HifdthMood.happy);

    // Partly done (Tuesday's morning only): worried.
    await tester.tap(find.bySemanticsLabel('Next day'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('1 of 2 done that day'), findsOneWidget);
    expect(tester.widget<HifdthCard>(find.byType(HifdthCard)).mood, HifdthMood.worried);

    // Back to today from the sheet.
    await tester.tap(find.bySemanticsLabel(RegExp(r'Open the calendar$')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(find.text('Back to today'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text("TODAY'S PLAN"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
