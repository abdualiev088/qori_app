import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'surahs.dart';

/// Which ayahs of each surah the user has marked learned, saved on the device.
///
/// A surah counts as learned when every one of its ayahs is; there is no
/// separate flag.
class LearnedStore extends ChangeNotifier {
  LearnedStore._(this._prefs, this._learned);

  /// Reads the saved state; anything unreadable starts empty.
  factory LearnedStore.load(SharedPreferences prefs) => LearnedStore._(prefs, _decode(prefs.getString(key)));

  static const key = 'hifdth.learned.v1';

  final SharedPreferences _prefs;
  final Map<int, Set<int>> _learned;

  Set<int> ayahsOf(int surah) => {...?_learned[surah]};

  int learnedCount(int surah) => _learned[surah]?.length ?? 0;

  bool isSurahLearned(int surah) => learnedCount(surah) == surahAyahCounts[surah - 1];

  int get surahsLearned => [for (var n = 1; n <= 114; n++) n].where(isSurahLearned).length;

  /// Called after every [commit] with the surah and its new set, so it can be synced.
  void Function(int surah, Set<int> ayahs)? onCommit;

  /// Replaces [surah]'s learned ayahs, saves, and notifies listeners.
  Future<void> commit(int surah, Set<int> ayahs) async {
    final clean = _clean(surah, ayahs);
    if (clean == null) return;
    clean.isEmpty ? _learned.remove(surah) : _learned[surah] = clean;
    notifyListeners();
    await _prefs.setString(key, _encode(_learned));
    onCommit?.call(surah, clean);
  }

  /// Everything learned, in the saved shape: {"68": [1, 2, 3]}.
  Map<String, List<int>> toJson() => {
        for (final s in _learned.keys.toList()..sort())
          if (_learned[s]!.isNotEmpty) '$s': _learned[s]!.toList()..sort(),
      };

  /// Takes the server's progress (the same shape as [toJson]) as the truth,
  /// except for the surahs in [keep], which have local changes not yet sent.
  /// Doesn't call [onCommit].
  Future<void> applyServer(Map<String, dynamic> json, {Set<int> keep = const {}}) async {
    final server = _decode(jsonEncode(json));
    final next = {
      for (final s in keep)
        if (_learned[s] case final ayahs?) s: ayahs,
      for (final MapEntry(:key, :value) in server.entries)
        if (!keep.contains(key)) key: value,
    };
    if (_encode(next) == _encode(_learned)) return;
    _learned
      ..clear()
      ..addAll(next);
    notifyListeners();
    await _prefs.setString(key, _encode(_learned));
  }

  /// Valid ayahs of a valid surah, or null when [surah] isn't 1–114.
  static Set<int>? _clean(int surah, Iterable<int> ayahs) {
    if (surah < 1 || surah > 114) return null;
    final count = surahAyahCounts[surah - 1];
    return {
      for (final a in ayahs)
        if (a >= 1 && a <= count) a
    };
  }

  static Map<int, Set<int>> _decode(String? raw) {
    final result = <int, Set<int>>{};
    if (raw == null) return result;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return result;
      for (final MapEntry(:key, :value) in json.entries) {
        final surah = int.tryParse('$key');
        if (surah == null || value is! List) continue;
        final ayahs = _clean(surah, value.whereType<int>());
        if (ayahs != null && ayahs.isNotEmpty) result[surah] = ayahs;
      }
    } on FormatException {
      return {};
    }
    return result;
  }

  static String _encode(Map<int, Set<int>> learned) {
    final surahs = learned.keys.where((s) => learned[s]!.isNotEmpty).toList()..sort();
    return jsonEncode({for (final s in surahs) '$s': learned[s]!.toList()..sort()});
  }
}
