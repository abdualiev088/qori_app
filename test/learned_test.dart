import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qori_app/data/learned_store.dart';
import 'package:qori_app/screens/home_screen.dart';
import 'package:qori_app/theme/tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
