import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_app/data/plan.dart';
import 'package:hifz_app/data/plan_store.dart';
import 'package:hifz_app/screens/method_screen.dart';
import 'package:hifz_app/theme/tokens.dart';
import 'package:hifz_app/widgets/auth_widgets.dart';
import 'package:hifz_app/widgets/method_explainer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n_en.dart';

void main() {
  setUp(() => HText.useGoogleFonts = false);

  late PlanStore store;
  final saved = <String>[];

  Future<void> open(WidgetTester tester, {Map<String, Object> prefs = const {}}) async {
    tester.view
      ..physicalSize = const Size(1206, 2622)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(prefs);
    store = PlanStore.load(await SharedPreferences.getInstance());
    saved.clear();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: MethodScreen(store: store, bottomInset: 96, onSaved: saved.add)),
    ));
    await tester.pump();
  }

  testWidgets('the first visit explains the method once, then opens on the plan form', (tester) async {
    await open(tester);
    expect(find.text(en.methodName), findsWidgets);
    expect(find.text('HOW IT WORKS'), findsOneWidget);
    expect(find.text(Method33.steps(en)[0]), findsOneWidget);
    expect(store.howSeen, isTrue);

    // It plays: the next step after 2.6 s.
    await tester.pump(StepPlayer.interval);
    expect(find.text(Method33.steps(en)[1]), findsOneWidget);

    await tester.tap(find.text('Set up my plan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250)); // the 200 ms fade
    expect(find.text('Set your plan'), findsOneWidget);
    expect(find.text('How it works'), findsOneWidget);
    expect(find.text('HOW IT WORKS'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the form previews the default plan and creates it', (tester) async {
    await open(tester, prefs: {PlanStore.howSeenKey: true});
    expect(find.text('Set your plan'), findsOneWidget);
    expect(find.text('An-Nas'), findsWidgets);
    expect(find.text('An-Naba'), findsWidgets);
    expect(find.text('50'), findsOneWidget); // days
    expect(find.textContaining('Day 1'), findsOneWidget);
    expect(find.text('5 of 15 lines on a page'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // A preset changes the pace and the preview.
    await tester.tap(find.text('½ page'));
    await tester.pump();
    expect(find.text('about half a page'), findsOneWidget);
    expect(find.text('36'), findsOneWidget);

    await tester.ensureVisible(find.text('Create my plan'));
    await tester.tap(find.text('Create my plan'));
    await tester.pump();
    expect(store.plan!.linesPerDay, 7);
    expect(store.plan!.restWeekday, DateTime.friday);
    expect(saved.single, 'Plan created · day 1 of 36 is on Home');
    expect(find.text('Update my plan'), findsOneWidget);
  });

  testWidgets('Update my plan is enabled only while there are unsaved changes', (tester) async {
    await open(tester, prefs: {PlanStore.howSeenKey: true});
    bool enabled() => tester.widget<PrimaryButton>(find.byType(PrimaryButton)).onPressed != null;
    await tester.tap(find.text('Create my plan'));
    await tester.pump();
    expect(find.text('Your plan'), findsOneWidget);
    expect(find.text('Update my plan'), findsOneWidget);
    expect(enabled(), isFalse); // just saved

    await tester.tap(find.text('1 page'));
    await tester.pump();
    expect(enabled(), isTrue);
    await tester.tap(find.text('5 lines'));
    await tester.pump();
    expect(enabled(), isFalse); // back to what's saved

    await tester.ensureVisible(find.text('Sunday'));
    await tester.tap(find.text('Sunday'));
    await tester.pump();
    expect(enabled(), isTrue);
    await tester.tap(find.text('Update my plan'));
    await tester.pump();
    expect(store.plan!.restWeekday, DateTime.sunday);
    expect(saved.last, 'Plan updated');
    expect(enabled(), isFalse);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });

  testWidgets('How it works stays open while the plan is edited', (tester) async {
    await open(tester, prefs: {PlanStore.howSeenKey: true});
    await tester.tap(find.text('How it works'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('AT A GLANCE'), findsOneWidget);
    await tester.pump(StepPlayer.interval);
    expect(find.text(Method33.steps(en)[1]), findsOneWidget);

    await tester.ensureVisible(find.text('Saturday'));
    await tester.tap(find.text('Saturday'));
    await tester.pump();
    expect(find.text('AT A GLANCE'), findsOneWidget);
    expect(find.text(Method33.steps(en)[1]), findsOneWidget); // not restarted

    await tester.ensureVisible(find.text('How it works'));
    await tester.tap(find.text('How it works'));
    await tester.pump(); // the fold starts on the next frame
    await tester.pump(const Duration(milliseconds: 300));
    // Folded: still built (it folds with its content), but clipped away.
    expect(find.text('AT A GLANCE').hitTestable(), findsNothing);
    expect(tester.getSize(find.byType(SizeTransition)).height, 0);
  });

  testWidgets('switching the reading order swaps the ends; an impossible range blocks saving', (tester) async {
    await open(tester, prefs: {PlanStore.howSeenKey: true});
    await tester.tap(find.text('From the beginning'));
    await tester.pump();
    // An-Naba 1 → An-Nas 6.
    expect(find.bySemanticsLabel(RegExp(r'^Start surah: 78')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^End surah: 114')), findsOneWidget);
    expect(find.textContaining('The end must come after'), findsNothing);

    // Reading from the end with An-Naba first is backwards.
    await tester.tap(find.text('From the end'));
    await tester.pump();
    await tester.tap(find.text('From the end')); // no change on the same option
    await tester.pump();
    expect(find.bySemanticsLabel(RegExp(r'^Start surah: 114')), findsOneWidget);

    // From the end, starting at Al-Fatihah can't reach An-Naba.
    await tester.tap(find.bySemanticsLabel(RegExp(r'^Start surah:')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'fatihah');
    await tester.pump();
    await tester.tap(find.text('Al-Fatihah'));
    await tester.pumpAndSettle();
    expect(find.textContaining('The end must come after the start when reading from the end'), findsOneWidget);
    await tester.ensureVisible(find.text('Create my plan'));
    await tester.tap(find.text('Create my plan'));
    await tester.pump();
    expect(store.plan, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a typed ayah is clamped when the field is left', (tester) async {
    await open(tester, prefs: {PlanStore.howSeenKey: true});
    final field = find.byType(TextField).first; // the start ayah
    await tester.enterText(field, '99');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('6'), findsWidgets); // An-Nas has 6 ayahs
    expect(tester.widget<TextField>(field).controller!.text, '6');
  });

  testWidgets('the surah picker searches and picks', (tester) async {
    await open(tester, prefs: {PlanStore.howSeenKey: true});
    await tester.tap(find.bySemanticsLabel(RegExp(r'^End surah:')));
    await tester.pumpAndSettle();
    expect(find.text('End surah'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'mulk');
    await tester.pump();
    expect(find.text('Al-Mulk'), findsOneWidget);
    await tester.tap(find.text('Al-Mulk'));
    await tester.pumpAndSettle();
    expect(find.text('Set your plan'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^End surah: 67')), findsOneWidget);
    expect(find.text('30'), findsWidgets); // the end ayah is Al-Mulk's last
  });

  test('defaults match the spec', () {
    final p = Plan(
        order: ReadingOrder.fromEnd,
        start: const Pos(114, 1),
        end: const Pos(78, 40),
        linesPerDay: 5,
        restWeekday: DateTime.friday,
        startDate: DateTime(2026, 11, 24));
    expect(p.lessons.length, 50);
  });
}
