import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hifz_app/data/api_client.dart';
import 'package:hifz_app/data/surah_source.dart';
import 'package:hifz_app/player/player_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_audio_engine.dart';

/// A server surah: every ayah is "downloaded" to `/dl/<surah>/<ayah>.mp3`.
class FakeDownloadSource implements SurahSource {
  bool offline = false;
  final prefetched = <(int, int)>[];

  /// When set, downloads wait for this before finishing.
  Completer<void>? gate;

  @override
  Future<List<Ayah>> ayat(int surah) async => [for (var n = 1; n <= 7; n++) Ayah(n, 'ar $n', 'en $n')];

  @override
  bool hasAudio(int surah) => true;

  @override
  Future<AudioRef?> audio(int surah, int ayah) async {
    await gate?.future;
    if (offline) throw ApiException.offline();
    return FileAudio('/dl/$surah/$ayah.mp3');
  }

  @override
  void prefetch(int surah, int ayah) => prefetched.add((surah, ayah));

  @override
  double ayahSeconds(int surah, int ayah) => 4;
}

void main() {
  late FakeAudioEngine engine;
  late FakeDownloadSource source;
  late PlayerController player;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    engine = FakeAudioEngine();
    source = FakeDownloadSource();
    player = PlayerController(engine, await SharedPreferences.getInstance(), source: source);
    await player.init();
    await player.openSurah(1, ayah: 1);
  });

  test('tapping an ayah plays the downloaded file, then fetches its neighbours', () async {
    await player.load(3);
    expect(engine.file, '/dl/1/3.mp3');
    expect(engine.playing, isTrue);
    expect(source.prefetched.last, (1, 3));
    expect(player.audioError, isNull);
  });

  test('while downloading the player shows loading', () async {
    source.gate = Completer();
    final loading = player.load(4);
    await Future<void>.delayed(Duration.zero);
    expect(player.loading, isTrue);
    expect(engine.file, isNot('/dl/1/4.mp3'));

    source.gate!.complete();
    await loading;
    expect(engine.file, '/dl/1/4.mp3');
    expect(player.loading, isFalse);
  });

  test('offline and not downloaded: says why, and stops loading', () async {
    source.offline = true;
    await player.load(5);
    expect(player.audioError, contains("Can't reach Hifz"));
    expect(player.loading, isFalse);
    expect(engine.playing, isFalse);

    source.offline = false;
    await player.load(5);
    expect(player.audioError, isNull);
    expect(engine.file, '/dl/1/5.mp3');
  });

  test('tapping another ayah during a download plays only the last one', () async {
    source.gate = Completer();
    final first = player.load(2);
    final second = player.load(6);
    source.gate!.complete();
    await Future.wait([first, second]);
    expect(engine.file, '/dl/1/6.mp3');
    expect(source.prefetched, isNot(contains((1, 2))));
  });
}
