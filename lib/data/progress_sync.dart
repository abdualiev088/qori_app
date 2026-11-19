import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'learned_store.dart';

/// Keeps learned ayahs in step with the server. The device stays the source
/// of truth while offline:
///
/// - Every [LearnedStore.commit] is queued (latest set per surah) and sent as
///   `PUT /progress/{surah}` once online. If the server has a newer write,
///   its set replaces the local one.
/// - With no session yet, a guest account is created, so progress syncs
///   before sign-up.
/// - When a session starts (a new guest, or any sign-in), the device's whole
///   progress is merged into the account first (union), so nothing is lost.
/// - With the queue empty, the server's progress replaces the local copy,
///   which brings in changes from other devices.
class ProgressSync {
  ProgressSync({required this.client, required this.store, required this.prefs, DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final ApiClient client;
  final LearnedStore store;
  final SharedPreferences prefs;
  final DateTime Function() _clock;

  /// Surahs changed on the device and not yet on the server:
  /// {"68": {"ayahs": [1, 2], "updated_at": "2026-11-19T10:00:00.000Z"}}.
  static const pendingKey = 'hifdth.sync.pending.v1';

  /// Whether the device's progress has been merged into the current account.
  static const mergedKey = 'hifdth.sync.merged.v1';

  Future<void>? _running;
  bool _again = false;

  /// Starts listening to the store's commits.
  void attach() => store.onCommit = _queue;

  /// Call after a sign-in or sign-up: the new account gets the device's progress.
  Future<void> accountChanged() async {
    await prefs.setBool(mergedKey, false);
    await sync();
  }

  /// One sync at a time; a request during a sync runs once more after it.
  Future<void> sync() {
    if (_running != null) {
      _again = true;
      return _running!;
    }
    return _running = _loop().whenComplete(() => _running = null);
  }

  Future<void> _loop() async {
    do {
      _again = false;
      try {
        await _syncOnce();
      } on ApiException {
        return; // Offline or server trouble: everything stays queued for next time.
      }
    } while (_again);
  }

  Future<void> _syncOnce() async {
    if (!await client.hasSession) {
      await client.setTokens(Tokens.fromJson(await client.post('/auth/guest') as Map<String, dynamic>));
      await prefs.setBool(mergedKey, false);
    }
    if (prefs.getBool(mergedKey) != true) {
      final merged = await client.post('/progress/merge', store.toJson()) as Map<String, dynamic>;
      await store.applyServer(merged, keep: _pending.keys.map(int.parse).toSet());
      await prefs.setBool(mergedKey, true);
    }
    await _flush();
    if (_pending.isEmpty) await store.applyServer(await client.get('/progress') as Map<String, dynamic>);
  }

  Future<void> _flush() async {
    for (final MapEntry(key: surah, value: change) in _pending.entries) {
      try {
        await client.put('/progress/$surah', change);
      } on ApiException catch (e) {
        if (e.isOffline || e.status >= 500 || e.status == 401) rethrow;
        if (e.status == 409 && e.body is Map<String, dynamic>) {
          // The server has a newer write: take its set for this surah.
          final ayahs = (e.body as Map<String, dynamic>)['ayahs'];
          await store.applyServer({...store.toJson(), surah: ayahs}..removeWhere((_, v) => v is List && v.isEmpty));
        }
        // 409 handled; 400/404 can never succeed. Either way, drop it.
      }
      _removePending(surah, change);
    }
  }

  void _queue(int surah, Set<int> ayahs) {
    final pending = _pending;
    pending['$surah'] = {'ayahs': ayahs.toList()..sort(), 'updated_at': _clock().toUtc().toIso8601String()};
    prefs.setString(pendingKey, jsonEncode(pending));
    unawaited(sync());
  }

  /// Removes a sent change, unless the user changed that surah again meanwhile.
  void _removePending(String surah, Map<String, dynamic> sent) {
    final pending = _pending;
    if (jsonEncode(pending[surah]) != jsonEncode(sent)) return;
    pending.remove(surah);
    prefs.setString(pendingKey, jsonEncode(pending));
  }

  Map<String, Map<String, dynamic>> get _pending {
    try {
      final raw = jsonDecode(prefs.getString(pendingKey) ?? '{}') as Map<String, dynamic>;
      return raw.map((k, v) => MapEntry(k, v as Map<String, dynamic>));
    } catch (_) {
      return {};
    }
  }
}
