import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qori_app/app_shell.dart';
import 'package:qori_app/data/auth_api.dart';
import 'package:qori_app/data/learned_store.dart';
import 'package:qori_app/data/plan_store.dart';
import 'package:qori_app/data/surah_source.dart';
import 'package:qori_app/player/player_controller.dart';
import 'package:qori_app/screens/player_screen.dart';
import 'package:qori_app/theme/tokens.dart';
import 'package:qori_app/widgets/mini_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_audio_engine.dart';
import 'fake_auth_api.dart';

/// Lets transitions and the text load finish (Hifdth's idle loop never settles).
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 150));
  }
}

void main() {
  setUp(() {
    HText.useGoogleFonts = false;
    // rootBundle caches loads; one started under an earlier test's fake clock would never finish.
    rootBundle.evict(BundledSurahSource.asset);
  });

  late FakeAudioEngine engine;
  late PlayerController player;

  /// The app, on the Player tab's surah list.
  Future<void> openPlayerTab(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1206, 2622)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    engine = FakeAudioEngine();
    player = PlayerController(engine, prefs);
    await player.init();
    final auth = FakeAuthApi()..user = const QoriUser(id: '1', email: 'a@b.co');
    await tester.pumpWidget(MaterialApp(
      home: AppShell(player: player, learned: LearnedStore.load(prefs), auth: auth, plans: PlanStore.load(prefs)),
    ));
    await tester.tap(find.text('Player'));
    await settle(tester);
  }

  Finder searchField() => find.byType(TextField);
  bool miniShowing(WidgetTester tester) => tester.widget<MiniPlayer>(find.byType(MiniPlayer)).visible;

  Finder ayahRow(int n) => find.bySemanticsLabel(RegExp('^Ayah $n\\.'));

  /// The bundled text loads with real I/O: give it real time, up to 5 s.
  Future<void> waitForAyah(WidgetTester tester, int n) async {
    for (var i = 0; i < 50 && ayahRow(n).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
    }
    await settle(tester);
  }

  /// Taps ayah [n] of the open surah, which makes the surah active.
  Future<void> tapAyah(WidgetTester tester, int n) async {
    await waitForAyah(tester, n);
    Scrollable.ensureVisible(tester.element(ayahRow(n)), alignment: 0.5);
    await settle(tester);
    await tester.tap(ayahRow(n));
    await settle(tester);
  }

  Future<void> search(WidgetTester tester, String text) async {
    await tester.enterText(searchField(), text);
    await tester.pump();
  }

  testWidgets('search finds surahs by name, number and Arabic, and says when nothing matches', (tester) async {
    await openPlayerTab(tester);
    expect(find.text('Surahs'), findsOneWidget);
    expect(find.text('Juz 1'), findsOneWidget);

    await search(tester, 'yaseen');
    expect(find.text('Ya-Sin'), findsOneWidget);
    expect(find.text('Juz 22 · Yaseen'), findsOneWidget);
    expect(find.text('Juz 1'), findsNothing); // the juz layout hides while searching

    await search(tester, '18');
    expect(find.text('Al-Kahf'), findsOneWidget);

    await search(tester, 'الكهف');
    expect(find.text('Al-Kahf'), findsOneWidget);

    await search(tester, 'zzzz');
    expect(find.text('No surah matches “zzzz”'), findsOneWidget);
    await tester.tap(find.text('Clear search'));
    await tester.pump();
    expect(find.text('Juz 1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a juz row opens the player at that row\'s first ayah', (tester) async {
    await openPlayerTab(tester);
    await tester.tap(find.text('Continues · ayahs 142–252'));
    await settle(tester);

    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(find.text('Alijon Qori · Surah 2 · 286 ayahs'), findsOneWidget);
    await waitForAyah(tester, 142); // scrolled to the row's first ayah
    expect(player.surah, isNull); // only reading until an ayah is tapped

    await tapAyah(tester, 142);
    expect(player.surah, 2);
    expect(player.current, 142);
    expect(find.text('Audio for Al-Baqarah is coming soon'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('back keeps playing and shows the mini-player; reopening keeps the place', (tester) async {
    await openPlayerTab(tester);
    await search(tester, 'qalam');
    await tester.tap(find.text('Al-Qalam'));
    await settle(tester);
    expect(miniShowing(tester), isFalse);

    // Play from ayah 5.
    await tapAyah(tester, 5);
    expect(miniShowing(tester), isFalse); // hidden while the player is open
    await player.load(5);
    await tester.pump();
    expect(engine.playing, isTrue);
    expect(player.current, 5);
    final position = player.current;

    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);
    expect(find.byType(PlayerScreen), findsNothing);
    expect(engine.playing, isTrue); // leaving the player no longer stops audio
    expect(miniShowing(tester), isTrue);
    expect(find.textContaining('Ayah $position of 52'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(RegExp('^Open player')));
    await settle(tester);
    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(player.current, position);
    expect(engine.playing, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('× stops playback and hides the mini-player', (tester) async {
    await openPlayerTab(tester);
    await search(tester, '68');
    await tester.tap(find.text('Al-Qalam'));
    await settle(tester);
    await tapAyah(tester, 1); // tapping an ayah plays it
    expect(engine.playing, isTrue);
    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);
    expect(miniShowing(tester), isTrue);

    await tester.tap(find.bySemanticsLabel('Stop and close Al-Qalam'));
    await settle(tester);
    expect(engine.playing, isFalse);
    expect(player.surah, isNull);
    expect(miniShowing(tester), isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('opening another surah while one plays only reads it; tapping an ayah switches', (tester) async {
    await openPlayerTab(tester);
    await search(tester, '68');
    await tester.tap(find.text('Al-Qalam'));
    await settle(tester);
    await tapAyah(tester, 5);
    await player.load(5);
    await tester.pump();
    expect(engine.playing, isTrue);
    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);

    // Open Al-Fatihah from the list: Al-Qalam keeps playing, in the mini-player.
    await search(tester, 'fatihah');
    await tester.tap(find.text('Al-Fatihah'));
    await settle(tester);
    await waitForAyah(tester, 2);
    expect(find.byType(PlayerScreen), findsOneWidget);
    expect(find.text('Alijon Qori · Surah 1 · 7 ayahs'), findsOneWidget);
    expect(player.surah, 68);
    expect(engine.playing, isTrue);
    expect(miniShowing(tester), isTrue);
    expect(find.text('REPEAT EACH AYAH'), findsNothing); // no full player while only reading

    // Tapping an ayah makes Al-Fatihah the active surah, and the full player appears.
    await tapAyah(tester, 2);
    expect(player.surah, 1);
    expect(player.current, 2);
    expect(engine.playing, isFalse); // Al-Qalam stopped
    expect(miniShowing(tester), isFalse);
    expect(find.text('REPEAT EACH AYAH'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('opening a surah with nothing playing selects nothing; leaving shows no mini-player', (tester) async {
    await openPlayerTab(tester);
    await search(tester, '68');
    await tester.tap(find.text('Al-Qalam'));
    await settle(tester);
    await waitForAyah(tester, 1);
    expect(player.surah, isNull);
    expect(find.text('REPEAT EACH AYAH'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Back'));
    await settle(tester);
    expect(miniShowing(tester), isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
