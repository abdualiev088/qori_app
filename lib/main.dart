import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_shell.dart';
import 'data/api_client.dart';
import 'data/auth_api.dart';
import 'data/learned_store.dart';
import 'data/progress_sync.dart';
import 'player/audio_handler.dart';
import 'player/player_controller.dart';
import 'theme/tokens.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final handler = await AudioService.init(
    builder: HifdthAudioHandler.new,
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.qori_app.playback',
      androidNotificationChannelName: 'Hifdth playback',
      androidNotificationOngoing: true,
    ),
  );
  final prefs = await SharedPreferences.getInstance();
  final player = PlayerController(handler, prefs);
  final learned = LearnedStore.load(prefs);
  final api = ApiClient(baseUrl: defaultApiUrl(), tokens: SecureTokenStore());
  final sync = ProgressSync(client: api, store: learned, prefs: prefs)..attach();
  final auth = AuthApi(api, onSignedIn: sync.accountChanged);
  // Draw first; the audio session, the first ayah and the sync start in the background.
  runApp(QoriApp(player: player, learned: learned, auth: auth));
  sync.sync();
  auth.loadMe();
  AppLifecycleListener(onResume: sync.sync);
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
