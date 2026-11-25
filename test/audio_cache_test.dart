import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hifz_app/data/api_client.dart';
import 'package:hifz_app/data/audio_cache.dart';
import 'package:hifz_app/data/surah_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The server's content endpoints and media files, in memory.
class FakeContentServer {
  /// sha256 → bytes, served at `/media/<sha>.mp3`.
  final files = <String, List<int>>{};
  final requests = <String>[];
  bool offline = false;

  /// Serves this instead of the real bytes (to test a corrupted download).
  List<int>? corruptWith;

  String add(List<int> bytes) {
    final sha = sha256.convert(bytes).toString();
    files[sha] = bytes;
    return sha;
  }

  Map<String, dynamic> info(String sha) =>
      {'url': 'http://test/media/$sha.mp3', 'size': files[sha]!.length, 'sha256': sha, 'duration_ms': 4000};

  late final String basmala = add(utf8.encode('bismillah'));
  late final fatiha = [basmala, for (var n = 2; n <= 7; n++) add(utf8.encode('fatiha $n'))];
  late final ikhlas = [for (var n = 1; n <= 4; n++) add(utf8.encode('ikhlas $n'))];

  late final client = MockClient((request) async {
    if (offline) throw http.ClientException('offline');
    final path = request.url.path;
    requests.add(path);
    if (path == '/v1/recitations') {
      return _json([
        {'slug': 'alijon-qori', 'name': 'Alijon Qori', 'surahs': [1, 112]},
      ]);
    }
    if (path == '/v1/surahs/1/audio') {
      return _json({
        'surah': 1,
        'reciter': {'slug': 'alijon-qori', 'name': 'Alijon Qori'},
        'basmala': null,
        'ayahs': [for (final (i, sha) in fatiha.indexed) {'ayah': i + 1, ...info(sha)}],
      });
    }
    if (path == '/v1/surahs/112/audio') {
      return _json({
        'surah': 112,
        'reciter': {'slug': 'alijon-qori', 'name': 'Alijon Qori'},
        'basmala': info(basmala),
        'ayahs': [for (final (i, sha) in ikhlas.indexed) {'ayah': i + 1, ...info(sha)}],
      });
    }
    if (path.startsWith('/media/')) {
      final sha = path.substring(7).replaceAll('.mp3', '');
      final bytes = files[sha];
      return bytes == null ? http.Response('', 404) : http.Response.bytes(corruptWith ?? bytes, 200);
    }
    return http.Response('{"error": {"code": "not_found", "message": "Not found."}}', 404);
  });

  int get downloads => requests.where((r) => r.startsWith('/media/')).length;

  static http.Response _json(Object body) =>
      http.Response(jsonEncode(body), 200, headers: {'content-type': 'application/json'});
}

void main() {
  late FakeContentServer server;
  late Directory dir;
  late SharedPreferences prefs;

  setUp(() async {
    server = FakeContentServer();
    dir = await Directory.systemTemp.createTemp('hifz_audio_test');
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() => dir.delete(recursive: true));

  AudioCache newCache() => AudioCache(
        api: ApiClient(baseUrl: 'http://test/v1', tokens: MemoryTokenStore(), client: server.client),
        prefs: prefs,
        client: server.client,
        directory: () async => dir,
      );

  /// Lets background downloads (prefetch) finish.
  Future<void> drain() => Future<void>.delayed(const Duration(milliseconds: 50));

  test('the catalog says which surahs have audio, and is remembered offline', () async {
    final cache = newCache();
    expect(cache.has(1), isFalse);
    await cache.refreshCatalog();
    expect(cache.has(1), isTrue);
    expect(cache.has(2), isFalse);

    server.offline = true;
    final later = newCache();
    await later.refreshCatalog();
    expect(later.has(112), isTrue);
    expect(later.reciterName, 'Alijon Qori');
  });

  test('an ayah is downloaded once, checked, and then played from the device', () async {
    final cache = newCache();
    await cache.refreshCatalog();
    final path = await cache.file(1, 2);
    expect(File(path).readAsStringSync(), 'fatiha 2');
    expect(path, endsWith('${server.fatiha[1]}.mp3'));

    await cache.file(1, 2);
    expect(server.downloads, 1);
  });

  test('taps on the same ayah at the same time share one download', () async {
    final cache = newCache();
    final paths = await Future.wait([cache.file(1, 3), cache.file(1, 3), cache.file(1, 3)]);
    expect(paths.toSet(), hasLength(1));
    expect(server.downloads, 1);
  });

  test('a corrupted download is rejected and not kept', () async {
    final cache = newCache();
    server.corruptWith = utf8.encode('garbage');
    await expectLater(cache.file(1, 4), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'download_corrupt')));
    expect(dir.listSync(recursive: true).whereType<File>(), isEmpty);

    server.corruptWith = null;
    expect(File(await cache.file(1, 4)).readAsStringSync(), 'fatiha 4');
  });

  test('the shared Basmala is stored once for every surah', () async {
    final cache = newCache();
    final fromFatiha = await cache.file(1, 1);
    final fromIkhlas = await cache.file(112, 0);
    expect(fromIkhlas, fromFatiha);
    expect(server.downloads, 1);
  });

  test('playing an ayah fetches the ones before and after it', () async {
    final cache = newCache();
    await cache.file(112, 2);
    cache.prefetch(112, 2);
    await drain();
    expect(await cache.isDownloaded(112, 1), isTrue);
    expect(await cache.isDownloaded(112, 3), isTrue);
    expect(await cache.isDownloaded(112, 4), isFalse);

    cache.prefetch(112, 1); // before ayah 1 comes the Basmala
    await drain();
    expect(await cache.isDownloaded(112, 0), isTrue);
  });

  test('offline, downloaded ayahs still play from the saved manifest', () async {
    await newCache().file(112, 1);
    server.offline = true;
    final later = newCache();
    expect(File(await later.file(112, 1)).readAsStringSync(), 'ikhlas 1');
    await expectLater(later.file(112, 2), throwsA(isA<ApiException>().having((e) => e.isOffline, 'offline', true)));
  });

  test('the recording length comes from the manifest', () async {
    final cache = newCache();
    expect(cache.seconds(1, 1), isNull);
    await cache.manifest(1);
    expect(cache.seconds(1, 1), 4.0);
  });

  group('RemoteSurahSource', () {
    test('Al-Qalam stays bundled; a server surah plays from a downloaded file', () async {
      final cache = newCache();
      await cache.refreshCatalog();
      final source = RemoteSurahSource(cache);

      final qalam = await source.audio(68, 1);
      expect(qalam, isA<AssetAudio>().having((a) => a.path, 'path', 'assets/audio/068_001.mp3'));

      final fatiha = await source.audio(1, 1);
      expect(fatiha, isA<FileAudio>());
      expect(File(fatiha!.path).readAsStringSync(), 'bismillah');

      expect(source.hasAudio(2), isFalse);
      expect(await source.audio(2, 1), isNull);
      expect(server.requests.where((r) => r.startsWith('/v1/surahs/2')), isEmpty);
    });
  });
}
