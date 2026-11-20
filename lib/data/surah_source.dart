import 'dart:convert';

import 'package:flutter/services.dart';

import 'al_qalam.dart' as qalam;

export 'al_qalam.dart' show Ayah, basmala;

/// Where to play an ayah's audio from: a file bundled with the app, or one
/// downloaded to the device.
sealed class AudioRef {
  const AudioRef(this.path);
  final String path;
}

class AssetAudio extends AudioRef {
  const AssetAudio(super.path);
}

class FileAudio extends AudioRef {
  const FileAudio(super.path);
}

/// Where the player gets a surah's text and audio. Swappable, so the
/// reciter's audio (or text from a server) can come in later without
/// touching the player.
abstract class SurahSource {
  /// The surah's ayahs, Arabic and English. May throw if it can't load.
  Future<List<qalam.Ayah>> ayat(int surah);

  /// Whether this surah has audio yet.
  bool hasAudio(int surah);

  /// Where to play an ayah (0 is the Basmala) from, downloading it first if
  /// needed. Null when the surah has no audio. Throws if a download fails.
  Future<AudioRef?> audio(int surah, int ayah);

  /// Starts fetching the ayahs around [ayah] so they're ready when the player
  /// moves on. Never throws.
  void prefetch(int surah, int ayah);

  /// A fallback length for an ayah's audio, in seconds, before the file reports its own.
  double ayahSeconds(int surah, int ayah);
}

/// Text for all 114 surahs from the bundled `assets/quran/quran.json`
/// (quran-uthmani and Sahih International, from api.alquran.cloud). Only
/// Al-Qalam (68) has audio: Alijon Qori's recitation, bundled per ayah.
class BundledSurahSource implements SurahSource {
  BundledSurahSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const asset = 'assets/quran/quran.json';
  static const _audioSurah = 68;

  final AssetBundle _bundle;
  Future<List<dynamic>>? _all;

  @override
  Future<List<qalam.Ayah>> ayat(int surah) async {
    // Al-Qalam keeps the text its recitation was timed to.
    if (surah == _audioSurah) return qalam.ayat;
    final all = await (_all ??= _load());
    final rows = all[surah - 1] as List<dynamic>;
    return [
      for (final (i, row) in rows.indexed) qalam.Ayah(i + 1, (row as List)[0] as String, row[1] as String),
    ];
  }

  Future<List<dynamic>> _load() async {
    try {
      return jsonDecode(await _bundle.loadString(asset)) as List<dynamic>;
    } catch (_) {
      _all = null; // let the next call try again
      rethrow;
    }
  }

  @override
  bool hasAudio(int surah) => surah == _audioSurah;

  @override
  Future<AudioRef?> audio(int surah, int ayah) async =>
      hasAudio(surah) ? AssetAudio('assets/audio/068_${ayah.toString().padLeft(3, '0')}.mp3') : null;

  @override
  void prefetch(int surah, int ayah) {} // bundled audio is always there

  @override
  double ayahSeconds(int surah, int ayah) =>
      surah == _audioSurah && ayah < qalam.ayahDurations.length ? qalam.ayahDurations[ayah] : 6;
}
