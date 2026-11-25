import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_shell.dart';
import 'data/api_client.dart';
import 'data/audio_cache.dart';
import 'data/auth_api.dart';
import 'data/learned_store.dart';
import 'data/locale_store.dart';
import 'data/plan_store.dart';
import 'data/progress_sync.dart';
import 'player/audio_engine.dart';
import 'player/audio_handler.dart';
import 'player/player_controller.dart';
import 'l10n/l10n.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final handler = await AudioService.init(
    builder: HifdthAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.abdualiev088.hifz.playback',
      androidNotificationChannelName: 'Hifdth playback',
      androidNotificationOngoing: true,
    ),
  );
  final prefs = await SharedPreferences.getInstance();
  final api = ApiClient(baseUrl: defaultApiUrl(), tokens: SecureTokenStore());
  // Recitation audio: downloaded from the server on first play, then kept on the device.
  final audio = AudioCache(api: api, prefs: prefs);
  final player = PlayerController(JustAudioEngine(handler), prefs, source: RemoteSurahSource(audio));
  final learned = LearnedStore.load(prefs);
  final plans = PlanStore.load(prefs);
  final locale = LocaleStore.load(prefs);
  // The player's own texts (status line, lock screen) follow the language too.
  void strings() => player.setStrings(lookupAppLocalizations(locale.locale));
  strings();
  locale.addListener(strings);
  final sync = ProgressSync(client: api, store: learned, prefs: prefs)..attach();
  final auth = AuthApi(api, onSignedIn: sync.accountChanged, onSignedOut: sync.signedOut, prefs: prefs);
  // Draw first; the audio session, the first ayah and the sync start in the background.
  runApp(HifzApp(player: player, learned: learned, auth: auth, plans: plans, locale: locale));
  // Who is signed in decides everything else: a session that isn't a real
  // account (a guest from an older version) is dropped, then progress syncs.
  unawaited(auth.loadMe().then((_) => auth.dropUnlessSignedIn()).then((_) => sync.sync()));
  unawaited(audio.refreshCatalog());
  AppLifecycleListener(onResume: () {
    sync.sync();
    audio.refreshCatalog();
  });
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.speech());
  await player.init();
}

class HifzApp extends StatelessWidget {
  const HifzApp({
    super.key,
    required this.player,
    required this.learned,
    required this.auth,
    required this.plans,
    required this.locale,
  });

  final PlayerController player;
  final LearnedStore learned;
  final AuthApi auth;
  final PlanStore plans;
  final LocaleStore locale;

  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: locale, builder: (context, _) => _app());

  Widget _app() {
    return MaterialApp(
      title: 'Hifz',
      debugShowCheckedModeBanner: false,
      locale: locale.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: HColors.accent),
        scaffoldBackgroundColor: HColors.bgTop,
        textTheme: ThemeData.light().textTheme.apply(fontFamily: HText.inter().fontFamily),
      ),
      home: AppShell(player: player, learned: learned, auth: auth, plans: plans, locale: locale),
    );
  }
}
