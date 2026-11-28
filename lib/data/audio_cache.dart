import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'surah_source.dart';

/// One downloadable recording, as the server's audio manifest lists it.
class AudioFileInfo {
  const AudioFileInfo({required this.url, required this.size, required this.sha256, required this.durationMs});

  factory AudioFileInfo.fromJson(Map<String, dynamic> json) => AudioFileInfo(
        url: json['url'] as String,
        size: json['size'] as int,
        sha256: json['sha256'] as String,
        durationMs: json['duration_ms'] as int,
      );

  final String url;
  final int size;
  final String sha256;
  final int durationMs;
}

/// Where the recitation audio and its lists live: the public R2 bucket.
/// Pass `--dart-define=QORI_AUDIO_URL=https://audio.example.com` to use another.
String defaultAudioUrl() {
  const fromEnv = String.fromEnvironment('QORI_AUDIO_URL');
  // r2.dev is rate-limited: fine for testing, replaced by our own domain before release.
  return fromEnv.isNotEmpty ? fromEnv : 'https://pub-7de4094a116b495ab84aa2665580cd3c.r2.dev';
}

/// A surah's recordings for one reciter: `manifests/<reciter>/NNN.json`.
class SurahAudio {
  SurahAudio({required this.reciter, required this.basmala, required this.ayahs});

  factory SurahAudio.fromJson(Map<String, dynamic> json) {
    final basmala = json['basmala'];
    return SurahAudio(
      reciter: (json['reciter'] as Map<String, dynamic>)['slug'] as String,
      basmala: basmala == null ? null : AudioFileInfo.fromJson(basmala as Map<String, dynamic>),
      ayahs: {
        for (final a in json['ayahs'] as List)
          (a as Map<String, dynamic>)['ayah'] as int: AudioFileInfo.fromJson(a),
      },
    );
  }

  final String reciter;

  /// The reciter's shared Basmala, played as ayah 0; null for surahs 1 and 9.
  final AudioFileInfo? basmala;
  final Map<int, AudioFileInfo> ayahs;

  AudioFileInfo? file(int ayah) => ayah == 0 ? basmala : ayahs[ayah];
}

/// Recitation audio from the public bucket, kept on the device.
///
/// The bucket holds the files and the lists, so audio needs no API server
/// (docs/DECISIONS.md). Everything there is public; the lists hold no user data.
///
/// - Which surahs have audio comes from `manifests/recitations.json`, saved so
///   it's known offline too.
/// - Each surah's manifest (file URLs and checksums) is saved the first time
///   it's fetched; after that it's used straight away and refreshed in the
///   background once per launch.
/// - Files are stored by checksum in the app's support folder, which iOS
///   doesn't clear. The same file (the shared Basmala) is stored once.
/// - A file is fetched once however many times it's asked for at the same
///   time, and kept only if its checksum matches.
class AudioCache {
  AudioCache({
    required String baseUrl,
    required SharedPreferences prefs,
    http.Client? client,
    Future<Directory> Function()? directory,
  })  : _base = baseUrl,
        _prefs = prefs,
        _http = client ?? http.Client(),
        _directory = directory ?? getApplicationSupportDirectory {
    _readCatalog();
  }

  static const catalogKey = 'hifdth.audio.catalog.v1';
  static String manifestKey(int surah) => 'hifdth.audio.surah.$surah.v1';

  final String _base;
  final SharedPreferences _prefs;
  final http.Client _http;
  final Future<Directory> Function() _directory;

  String? reciterSlug;
  String? reciterName;
  Set<int> _surahs = {};
  final _manifests = <int, SurahAudio>{};
  final _refreshed = <int>{};
  final _inflight = <String, Future<String>>{};
  Future<Directory>? _dir;

  /// Whether the server has complete audio for [surah].
  bool has(int surah) => _surahs.contains(surah);

  void _readCatalog() {
    try {
      final json = jsonDecode(_prefs.getString(catalogKey) ?? 'null');
      if (json is Map<String, dynamic>) _applyCatalog(json);
    } catch (_) {}
  }

  void _applyCatalog(Map<String, dynamic> json) {
    reciterSlug = json['slug'] as String?;
    reciterName = json['name'] as String?;
    _surahs = {for (final s in json['surahs'] as List) s as int};
  }

  /// Fetches which surahs have audio. Keeps the saved list when offline.
  Future<void> refreshCatalog() async {
    try {
      final list = await _getJson('manifests/recitations.json') as List;
      if (list.isEmpty) return;
      final first = list.first as Map<String, dynamic>;
      _applyCatalog(first);
      await _prefs.setString(catalogKey, jsonEncode(first));
    } on ApiException {
      // Offline: the saved catalog stands.
    }
  }

  /// The surah's manifest: saved copy first (refreshed in the background), else the server.
  Future<SurahAudio> manifest(int surah) async {
    final inMemory = _manifests[surah];
    if (inMemory != null) return inMemory;

    final saved = _prefs.getString(manifestKey(surah));
    if (saved != null) {
      try {
        final m = SurahAudio.fromJson(jsonDecode(saved) as Map<String, dynamic>);
        _manifests[surah] = m;
        unawaited(_fetchManifest(surah).catchError((_) => m));
        return m;
      } catch (_) {
        // Unreadable: fetch a fresh one.
      }
    }
    return _fetchManifest(surah);
  }

  Future<SurahAudio> _fetchManifest(int surah) async {
    if (!_refreshed.add(surah) && _manifests[surah] != null) return _manifests[surah]!;
    if (reciterSlug == null) await refreshCatalog();
    final slug = reciterSlug;
    if (slug == null) throw ApiException.offline();
    final json = await _getJson('manifests/$slug/${surah.toString().padLeft(3, '0')}.json') as Map<String, dynamic>;
    final m = SurahAudio.fromJson(json);
    _manifests[surah] = m;
    await _prefs.setString(manifestKey(surah), jsonEncode(json));
    return m;
  }

  Future<Object?> _getJson(String path) async {
    final url = '$_base/$path';
    final http.Response response;
    try {
      response = await http.Response.fromStream(
          await sendAllowingDevHttp(_http, http.Request('GET', Uri.parse(url))).timeout(const Duration(seconds: 20)));
    } catch (e) {
      throw ApiException.offline(kDebugMode ? '$url\n$e' : null);
    }
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'no_audio', 'This surah has no recording yet.');
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw ApiException(-1, 'bad_list', "Couldn't read the list of recordings. Please try again.");
    }
  }

  /// The ayah's file on the device (0 is the Basmala), downloading it if needed.
  Future<String> file(int surah, int ayah) async {
    final info = (await manifest(surah)).file(ayah);
    if (info == null) throw ApiException(404, 'no_audio', 'This ayah has no recording yet.');
    // A block body: `=> _inflight.remove(..)` would return this very future,
    // and whenComplete would wait on it forever.
    return _inflight[info.sha256] ??= _ensure(info).whenComplete(() {
      _inflight.remove(info.sha256);
    });
  }

  /// Whether the ayah's file is already on the device.
  Future<bool> isDownloaded(int surah, int ayah) async {
    final info = _manifests[surah]?.file(ayah);
    if (info == null) return false;
    final f = File(await _pathFor(info));
    return f.existsSync() && f.lengthSync() == info.size;
  }

  /// Downloads the ayahs before and after [ayah] in the background.
  void prefetch(int surah, int ayah) {
    final m = _manifests[surah];
    if (m == null) return;
    for (final n in [ayah + 1, ayah - 1]) {
      if (m.file(n) != null) unawaited(file(surah, n).then<void>((_) {}, onError: (_) {}));
    }
  }

  /// The length of the ayah's recording, if its manifest is loaded.
  double? seconds(int surah, int ayah) {
    final ms = _manifests[surah]?.file(ayah)?.durationMs;
    return ms == null ? null : ms / 1000;
  }

  Future<String> _pathFor(AudioFileInfo info) async {
    final dir = await (_dir ??= _directory().then((d) => Directory('${d.path}/audio').create(recursive: true)));
    return '${dir.path}/${info.sha256}.mp3';
  }

  Future<String> _ensure(AudioFileInfo info) async {
    final path = await _pathFor(info);
    final file = File(path);
    if (file.existsSync() && file.lengthSync() == info.size) return path;

    final http.Response response;
    try {
      response = await http.Response.fromStream(
          await sendAllowingDevHttp(_http, http.Request('GET', Uri.parse(info.url))).timeout(const Duration(seconds: 60)));
    } catch (e) {
      throw ApiException.offline(kDebugMode ? '${info.url}\n$e' : null);
    }
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, 'download_failed', "Couldn't download this ayah. Please try again.");
    }
    final bytes = response.bodyBytes;
    if (sha256.convert(bytes).toString() != info.sha256) {
      throw ApiException(-1, 'download_corrupt', "The download didn't come through intact. Please try again.");
    }
    // Write next to it, then rename, so a half-written file is never played.
    final partial = File('$path.part');
    await partial.writeAsBytes(bytes, flush: true);
    await partial.rename(path);
    return path;
  }
}

/// Text from the app; audio bundled where it is (Al-Qalam), otherwise from
/// [AudioCache]: downloaded on first play, then played from the device.
class RemoteSurahSource implements SurahSource {
  RemoteSurahSource(this.cache, {SurahSource? bundled}) : _bundled = bundled ?? BundledSurahSource();

  final AudioCache cache;
  final SurahSource _bundled;

  @override
  Future<List<Ayah>> ayat(int surah) => _bundled.ayat(surah);

  @override
  bool hasAudio(int surah) => _bundled.hasAudio(surah) || cache.has(surah);

  @override
  Future<AudioRef?> audio(int surah, int ayah) async {
    if (_bundled.hasAudio(surah)) return _bundled.audio(surah, ayah);
    if (!cache.has(surah)) return null;
    return FileAudio(await cache.file(surah, ayah));
  }

  @override
  void prefetch(int surah, int ayah) {
    if (!_bundled.hasAudio(surah)) cache.prefetch(surah, ayah);
  }

  @override
  double ayahSeconds(int surah, int ayah) =>
      _bundled.hasAudio(surah) ? _bundled.ayahSeconds(surah, ayah) : (cache.seconds(surah, ayah) ?? 6);
}
