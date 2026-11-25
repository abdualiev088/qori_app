import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qori_app/data/locale_store.dart';
import 'package:qori_app/l10n/app_localizations.dart';
import 'package:qori_app/l10n/plan_text.dart';
import 'package:qori_app/player/player_controller.dart';
import 'package:qori_app/screens/settings_screen.dart';
import 'package:qori_app/theme/tokens.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_audio_engine.dart';

void main() {
  setUp(() => HText.useGoogleFonts = false);

  late LocaleStore locale;
  late PlayerController player;

  Future<void> open(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(1206, 2622)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    locale = LocaleStore.load(prefs);
    player = PlayerController(FakeAudioEngine(), prefs);
    await tester.pumpWidget(ListenableBuilder(
      listenable: locale,
      builder: (context, _) => MaterialApp(
        locale: locale.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: SettingsScreen(locale: locale, player: player, bottomInset: 96)),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('English by default; picking a language redraws the app in it and remembers it', (tester) async {
    await open(tester);
    expect(find.text('Settings'), findsOneWidget);
    expect(locale.language, AppLanguage.en);

    await tester.tap(find.text('Русский'));
    await tester.pumpAndSettle();
    expect(find.text('Настройки'), findsOneWidget);
    expect(find.text('ЯЗЫК'), findsOneWidget);

    await tester.tap(find.text('Ўзбекча'));
    await tester.pumpAndSettle();
    expect(find.text('Созламалар'), findsOneWidget);

    await tester.tap(find.text('Oʻzbekcha'));
    await tester.pumpAndSettle();
    expect(find.text('Sozlamalar'), findsOneWidget);

    final again = LocaleStore.load(await SharedPreferences.getInstance());
    expect(again.language, AppLanguage.uzLatn);
    expect(tester.takeException(), isNull);
  });

  testWidgets('playback settings change the player', (tester) async {
    await open(tester);
    await tester.tap(find.text('7×'));
    await tester.pump();
    expect(player.repeat, 7);
    await tester.tap(find.text('∞'));
    await tester.pump();
    expect(player.repeat, 0);

    final before = player.autoNext;
    await tester.tap(find.text('Then next ayah'));
    await tester.pump();
    expect(player.autoNext, !before);
  });

  test('every language has every text, with plurals and dates that read right', () {
    for (final l in AppLocalizations.supportedLocales.map(lookupAppLocalizations)) {
      expect(l.weekdaysLong.split(','), hasLength(7));
      expect(l.weekdaysShort.split(','), hasLength(7));
      expect(l.weekdayLetters.split(','), hasLength(7));
      expect(l.monthsLong.split(','), hasLength(12));
      expect(l.monthsShort.split(','), hasLength(12));
    }
    final ru = lookupAppLocalizations(const Locale('ru'));
    expect(ru.ayahsCount(1), '1 аят');
    expect(ru.ayahsCount(3), '3 аята');
    expect(ru.ayahsCount(5), '5 аятов');
    expect(ru.ayahsCount(21), '21 аят');
    expect(linesText(ru, 23), '1½ страницы');
    expect(dateLong(ru, DateTime(2026, 11, 25)), 'среда, 25 ноября');

    final uz = lookupAppLocalizations(const Locale('uz'));
    expect(uz.ayahsCount(5), '5 oyat');
    expect(dateShort(uz, DateTime(2026, 11, 25), now: DateTime(2026)), 'Ch, 25-noy');

    final cyrl = lookupAppLocalizations(const Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl'));
    expect(cyrl.tabSettings, 'Созламалар');
    expect(cyrl.quranProgressCaps, 'ҚУРЪОН БЎЙИЧА НАТИЖА');
  });
}
