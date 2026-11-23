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
import 'data/progress_sync.dart';
import 'player/audio_engine.dart';
import 'player/audio_handler.dart';
import 'player/player_controller.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final handler = await AudioService.init(
    builder: HifdthAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.abdualiev088.qori.playback',
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
  final sync = ProgressSync(client: api, store: learned, prefs: prefs)..attach();
  final auth = AuthApi(api, onSignedIn: sync.accountChanged, onSignedOut: sync.signedOut, prefs: prefs);
  // Draw first; the audio session, the first ayah and the sync start in the background.
  runApp(QoriApp(player: player, learned: learned, auth: auth));
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

class QoriApp extends StatelessWidget {
  const QoriApp({super.key, required this.player, required this.learned, required this.auth});

  final PlayerController player;
  final LearnedStore learned;
  final AuthApi auth;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qori',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: HColors.accent),
        scaffoldBackgroundColor: HColors.bgTop,
        textTheme: ThemeData.light().textTheme.apply(fontFamily: HText.inter().fontFamily),
      ),
      home: AppShell(player: player, learned: learned, auth: auth),
    );
  }
}
