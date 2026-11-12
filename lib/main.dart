import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_shell.dart';
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
  // Draw first; the audio session and the first ayah load in the background.
  runApp(QoriApp(player: player));
  final session = await AudioSession.instance;
  await session.configure(const AudioSessionConfiguration.speech());
  await player.init();
}

class QoriApp extends StatelessWidget {
  const QoriApp({super.key, required this.player});

  final PlayerController player;

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
      home: AppShell(player: player),
    );
  }
}
