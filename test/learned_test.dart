import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qori_app/data/learned_store.dart';
import 'package:qori_app/screens/home_screen.dart';
import 'package:qori_app/theme/tokens.dart';
import 'package:qori_app/widgets/glass.dart';
import 'package:qori_app/widgets/hifdth_card.dart';
import 'package:qori_app/widgets/hifdth_mood.dart';
import 'package:qori_app/widgets/hifdth_painter.dart';
import 'package:qori_app/widgets/quran_progress_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n_en.dart';

void main() {
  setUp(() => HText.useGoogleFonts = false);

  group('LearnedStore', () {
    test('starts empty with nothing saved', () async {
      SharedPreferences.setMockInitialValues({});
      final store = LearnedStore.load(await SharedPreferences.getInstance());
      expect(store.surahsLearned, 0);
      expect(store.learnedCount(68), 0);
    });

    test('ignores unreadable JSON', () async {
      SharedPreferences.setMockInitialValues({LearnedStore.key: '{not json'});
      final store = LearnedStore.load(await SharedPreferences.getInstance());
      expect(store.learnedCount(1), 0);
    });

    test('drops surahs and ayahs out of range', () async {
      SharedPreferences.setMockInitialValues({LearnedStore.key: '{"0":[1],"115":[1],"112":[0,1,2,5],"x":[1]}'});
      final store = LearnedStore.load(await SharedPreferences.getInstance());
      expect(store.ayahsOf(112), {1, 2});
      expect(store.learnedCount(115), 0);
    });

    test('saves sorted lists, omits empty surahs and computes whole surahs', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = LearnedStore.load(prefs);
      await store.commit(112, {4, 2, 3, 1});
      await store.commit(68, {3, 1, 2});
      await store.commit(1, {});
      expect(prefs.getString(LearnedStore.key), '{"68":[1,2,3],"112":[1,2,3,4]}');
      expect(store.isSurahLearned(112), isTrue);
      expect(store.isSurahLearned(68), isFalse);
      expect(store.surahsLearned, 1);
    });
  });

  group('Learned sheet on Home', () {
    late SharedPreferences prefs;

    /// Builds Home from what's in prefs, like a fresh app launch.
    Future<void> restart(WidgetTester tester) async {
      final learned = LearnedStore.load(prefs);
      await tester.pumpWidget(MaterialApp(
        key: UniqueKey(),
        // No motion, so the Hifdth idle loop doesn't keep pumpAndSettle busy.
        builder: (context, child) =>
            MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
        home: Scaffold(body: HomeScreen(bottomInset: 114, learned: learned, now: DateTime(2026, 11, 16, 9))),
      ));
    }

    Future<void> pumpHome(WidgetTester tester, {Map<String, Object> saved = const {}}) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues(saved);
      prefs = await SharedPreferences.getInstance();
      await restart(tester);
    }

    Finder tile(int n) => find.bySemanticsLabel(RegExp('^Surah $n, '));
    Finder ayah(int n) => find.bySemanticsLabel(RegExp('^Ayah $n, '));
    final done = find.widgetWithText(FilledButton, 'Done');

    Future<void> openSurah(WidgetTester tester, int n) async {
      await tester.ensureVisible(tile(n).first);
      await tester.pumpAndSettle();
      await tester.tap(tile(n).first);
      await tester.pumpAndSettle();
      expect(find.text('Whole surah learned'), findsOneWidget);
    }

    /// Lets any toast time out so no timer is left running.
    Future<void> finish(WidgetTester tester) => tester.pump(const Duration(seconds: 10));

    testWidgets('first launch shows 0/114', (tester) async {
      await pumpHome(tester);
      expect(find.text('0/114', findRichText: true), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'^Surah \d+, .*Not started')), findsAtLeastNWidgets(114));
    });

    testWidgets('marking ayahs and tapping Done asks to save', (tester) async {
      await pumpHome(tester);
      await openSurah(tester, 68);
      for (final n in [1, 2, 3]) {
        await tester.tap(ayah(n));
        await tester.pump();
      }
      expect(find.text('3 of 52 ayahs learned'), findsOneWidget);
      await tester.tap(done);
      await tester.pumpAndSettle();
      expect(find.text('Save changes?'), findsOneWidget);
      expect(find.textContaining('3 ayahs marked learned', findRichText: true), findsOneWidget);
      expect(find.textContaining("You'll have 3 of 52 ayahs learned.", findRichText: true), findsOneWidget);
    });

    testWidgets('Save writes prefs and the card shows the surah in progress', (tester) async {
      await pumpHome(tester);
      await openSurah(tester, 68);
      for (final n in [1, 2, 3]) {
        await tester.tap(ayah(n));
        await tester.pump();
      }
      await tester.tap(done);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save changes'));
      await tester.pumpAndSettle();
      expect(prefs.getString(LearnedStore.key), '{"68":[1,2,3]}');
      expect(find.text('Whole surah learned'), findsNothing);
      expect(find.text('Saved · Al-Qalam, 3 of 52 ayahs learned'), findsOneWidget);
      expect(find.bySemanticsLabel('Surah 68, Al-Qalam. 3 of 52 ayahs · 49 to go'), findsOneWidget);
      await finish(tester);

      await restart(tester);
      expect(find.bySemanticsLabel('Surah 68, Al-Qalam. 3 of 52 ayahs · 49 to go'), findsOneWidget);
    });

    testWidgets('Discard leaves prefs unchanged', (tester) async {
      await pumpHome(tester, saved: {LearnedStore.key: '{"68":[1,2,3]}'});
      await openSurah(tester, 68);
      await tester.tap(find.bySemanticsLabel(RegExp('^Whole surah learned')));
      await tester.pump();
      expect(find.text('Learned · all 52 ayahs'), findsOneWidget);
      await tester.tap(done);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard changes'));
      await tester.pumpAndSettle();
      expect(prefs.getString(LearnedStore.key), '{"68":[1,2,3]}');
      expect(find.text('Changes discarded'), findsOneWidget);
      expect(find.bySemanticsLabel('Surah 68, Al-Qalam. 3 of 52 ayahs · 49 to go'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('Keep editing returns to the sheet with the draft intact', (tester) async {
      await pumpHome(tester);
      await openSurah(tester, 68);
      await tester.tap(ayah(5));
      await tester.pump();
      await tester.tap(done);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Save changes?'), findsNothing);
      expect(find.text('1 of 52 ayahs learned'), findsOneWidget);
      expect(prefs.getString(LearnedStore.key), isNull);
    });

    testWidgets('Done with no changes closes without the dialog', (tester) async {
      await pumpHome(tester);
      await openSurah(tester, 68);
      await tester.tap(done);
      await tester.pumpAndSettle();
      expect(find.text('Save changes?'), findsNothing);
      expect(find.text('Whole surah learned'), findsNothing);
    });

    testWidgets('dragging the sheet down with changes asks instead of closing', (tester) async {
      await pumpHome(tester);
      await openSurah(tester, 68);
      await tester.tap(ayah(1));
      await tester.pump();
      await tester.fling(find.text('Al-Qalam').last, const Offset(0, 500), 2000);
      await tester.pumpAndSettle();
      expect(find.text('Save changes?'), findsOneWidget);
      expect(find.text('Whole surah learned'), findsOneWidget);
    });

    testWidgets('tapping the scrim with changes asks instead of closing', (tester) async {
      await pumpHome(tester);
      await openSurah(tester, 68);
      await tester.tap(ayah(1));
      await tester.pump();
      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();
      expect(find.text('Save changes?'), findsOneWidget);
    });

    testWidgets('hold and slide marks every ayah passed', (tester) async {
      await pumpHome(tester);
      await openSurah(tester, 68);
      final gesture = await tester.startGesture(tester.getCenter(ayah(1)));
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.moveTo(tester.getCenter(ayah(6))); // one jump: 2–5 are filled in
      await tester.pump();
      await gesture.up();
      await tester.pump();
      expect(find.text('6 of 52 ayahs learned'), findsOneWidget);
    });

    testWidgets('sliding without holding marks every ayah passed', (tester) async {
      await pumpHome(tester);
      await openSurah(tester, 68);
      final gesture = await tester.startGesture(tester.getCenter(ayah(1)));
      await gesture.moveTo(tester.getCenter(ayah(2)));
      await gesture.moveTo(tester.getCenter(ayah(5)));
      await gesture.up();
      await tester.pump();
      expect(find.text('5 of 52 ayahs learned'), findsOneWidget);
      expect(find.text('Whole surah learned'), findsOneWidget); // the sheet didn't move
    });

    testWidgets('a grid that fits does not scroll', (tester) async {
      await pumpHome(tester);
      await openSurah(tester, 1);
      final grid = tester.widget<GridView>(find.byType(GridView));
      expect(grid.physics, isA<NeverScrollableScrollPhysics>());
    });

    testWidgets('a long grid scrolls up and down, and marks when sliding sideways', (tester) async {
      await pumpHome(tester);
      await openSurah(tester, 2);
      final grid = tester.widget<GridView>(find.byType(GridView));
      expect(grid.physics, isA<BouncingScrollPhysics>());

      await tester.drag(ayah(17), const Offset(0, -150));
      await tester.pumpAndSettle();
      expect(find.text('Not started · 286 ayahs'), findsWidgets); // sheet header (and the card behind it)
      expect(tester.widget<GridView>(find.byType(GridView)).controller!.offset, greaterThan(0));

      final gesture = await tester.startGesture(tester.getCenter(ayah(25)));
      await gesture.moveTo(tester.getCenter(ayah(26)));
      await gesture.moveTo(tester.getCenter(ayah(28)));
      await gesture.up();
      await tester.pump();
      expect(find.text('4 of 286 ayahs learned'), findsOneWidget);
    });

    double bubbleOpacity(WidgetTester tester) => tester
        .widget<AnimatedOpacity>(
            find.ancestor(of: find.text(en.askTitle), matching: find.byType(AnimatedOpacity)).first)
        .opacity;

    /// The small Hifdth flying or sitting in the corner (the card's own character isn't a HifdthAvatar).
    final mini = find.byType(HifdthAvatar);
    double look(WidgetTester tester) => tester.widget<HifdthAvatar>(mini).look;
    bool speaking(WidgetTester tester) => tester.widget<HifdthAvatar>(mini).speaking;

    /// The body's middle color as painted.
    Color bodyColor(WidgetTester tester) =>
        (tester.widget<CustomPaint>(find.descendant(of: mini, matching: find.byType(CustomPaint))).painter!
                as HifdthPainter)
            .style
            .body[1];
    final hint = find.textContaining('Press and hold');
    final scrollView = find.byType(SingleChildScrollView);

    Future<void> scrollBy(WidgetTester tester, double dy) async {
      await tester.drag(scrollView, Offset(0, -dy));
      await tester.pumpAndSettle();
    }

    /// Scrolls until the middle of the Quran card is just above the nav (if it isn't already).
    Future<void> scrollToQuranMiddle(WidgetTester tester) async {
      final card = find.byType(QuranProgressCard);
      final visibleBottom = 874 - 114.0;
      final dy = tester.getCenter(card).dy - visibleBottom + 20;
      if (dy > 0) await scrollBy(tester, dy);
    }

    testWidgets('Hifdth flies down after its card spot leaves, and back when scrolling up', (tester) async {
      await pumpHome(tester);
      expect(mini, findsNothing);
      await scrollBy(tester, 250);
      expect(mini, findsOneWidget);
      expect(tester.getRect(mini).size, const Size(56, 56));
      expect(tester.getRect(mini).right, 402 - 16);
      await scrollBy(tester, -2000);
      expect(mini, findsNothing);
    });

    testWidgets('at the end of the page Hifdth is level with the grid hint, with no extra space below the card',
        (tester) async {
      await pumpHome(tester);
      await scrollBy(tester, 4000);
      expect(tester.getCenter(mini).dy, closeTo(tester.getCenter(hint).dy, 0.5));
      expect(tester.getRect(find.byType(QuranProgressCard)).bottom, closeTo(874 - 114, 0.5));
    });

    testWidgets('halfway into the Quran card Hifdth looks left and asks; the bubble leads to the grid', (tester) async {
      await pumpHome(tester);
      // Hifdth sits in its card and says nothing until it has flown down.
      expect(mini, findsNothing);
      expect(bubbleOpacity(tester), 0);

      // Home is short enough that the Quran card is in view as soon as Hifdth lands.
      await scrollBy(tester, 250);
      await scrollToQuranMiddle(tester);
      expect(bubbleOpacity(tester), 1);
      expect(look(tester), -1);
      expect(speaking(tester), isTrue);
      expect(bodyColor(tester), MoodStyle.happy.speaking().body[1]); // blue

      await tester.tap(find.text(en.askTitle));
      await tester.pumpAndSettle();
      expect(bubbleOpacity(tester), 0);
      expect(look(tester), 0);
      expect(bodyColor(tester), MoodStyle.happy.body[1]);

      // Leaving (Hifdth flies back to its card) and coming back asks again.
      await scrollBy(tester, -600);
      expect(mini, findsNothing);
      await scrollBy(tester, 250);
      await scrollToQuranMiddle(tester);
      expect(bubbleOpacity(tester), 1);
    });

    testWidgets('the bubble goes quiet on its own, and tapping Hifdth asks again', (tester) async {
      await pumpHome(tester);
      await scrollBy(tester, 250);
      await scrollToQuranMiddle(tester);
      expect(bubbleOpacity(tester), 1);
      await tester.pump(const Duration(seconds: 9));
      expect(bubbleOpacity(tester), 0);
      await tester.tap(mini);
      await tester.pump();
      expect(bubbleOpacity(tester), 1);
      await tester.tap(mini);
      await tester.pump();
      expect(bubbleOpacity(tester), 0);
    });

    testWidgets('the question types in word by word, without the bubble changing size', (tester) async {
      await pumpHome(tester);
      // Real motion for this one.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HomeScreen(bottomInset: 114, learned: LearnedStore.load(prefs), now: DateTime(2026, 11, 16, 9)),
        ),
      ));
      await tester.drag(scrollView, const Offset(0, -250));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // landed
      await tester.drag(scrollView, const Offset(0, -300));
      await tester.pump();

      List<double> alphas(String text) => [
            for (final span in (tester.widget<Text>(find.text(text)).textSpan! as TextSpan).children!)
              (span as TextSpan).style!.color!.a,
          ];
      final bubble = find.ancestor(of: find.text(en.askTitle), matching: find.byType(Container)).first;

      await tester.pump(const Duration(milliseconds: 120));
      final early = alphas(en.askTitle);
      final size = tester.getSize(bubble);
      expect(early.first, greaterThan(0)); // the first words are in
      expect(early.last, 0); // the rest are still to come
      expect(alphas(en.askBody).every((a) => a == 0), isTrue);

      await tester.pump(const Duration(milliseconds: 400));
      final later = alphas(en.askTitle);
      for (var i = 0; i < later.length; i++) {
        expect(later[i], greaterThanOrEqualTo(early[i]));
      }

      await tester.pump(const Duration(milliseconds: 800));
      expect(alphas(en.askTitle).every((a) => a == 1), isTrue);
      expect(alphas(en.askBody).last, closeTo(0.9, 0.01)); // the body's slightly softer white
      expect(tester.getSize(bubble), size); // laid out in full from the start
      final glass = tester
          .widget<LiquidGlass>(find.ancestor(of: find.text(en.askTitle), matching: find.byType(LiquidGlass)));
      final tint = (glass.fill as LinearGradient).colors[1];
      expect(tint.b, greaterThan(tint.r)); // tinted blue
      expect(tint.a, lessThan(1)); // still see-through glass
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Hifdth flies from its card spot down to the corner', (tester) async {
      await pumpHome(tester);
      // Real motion for this one.
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: HomeScreen(bottomInset: 114, learned: LearnedStore.load(prefs), now: DateTime(2026, 11, 16, 9)),
        ),
      ));
      await tester.drag(scrollView, const Offset(0, -250));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final start = tester.getRect(mini);
      expect(start.width, greaterThan(100)); // still about full size, near the top
      expect(start.top, lessThan(200));
      await tester.pump(const Duration(milliseconds: 260));
      final mid = tester.getRect(mini);
      expect(mid.width, inExclusiveRange(56, 112));
      expect(mid.top, greaterThan(start.top));
      await tester.pump(const Duration(milliseconds: 300)); // 576 ms in all
      expect(tester.getRect(mini).size, const Size(56, 56));
      expect(tester.getRect(mini).right, 402 - 16);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('saved ayahs survive a restart', (tester) async {
      await pumpHome(tester, saved: {LearnedStore.key: '{"68":[1,2,3]}'});
      await restart(tester);
      expect(find.bySemanticsLabel('Surah 68, Al-Qalam. 3 of 52 ayahs · 49 to go'), findsOneWidget);
      await openSurah(tester, 68);
      expect(find.bySemanticsLabel('Ayah 2, learned'), findsOneWidget);
      expect(find.bySemanticsLabel('Ayah 4, not learned'), findsOneWidget);
    });
  });
}
