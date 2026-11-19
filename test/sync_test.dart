import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qori_app/data/api_client.dart';
import 'package:qori_app/data/auth_api.dart';
import 'package:qori_app/data/learned_store.dart';
import 'package:qori_app/data/progress_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A small in-memory stand-in for the Qori backend, following docs/api.md.
class FakeServer {
  final progress = <int, Set<int>>{};
  final clock = <int, DateTime>{};
  final validAccess = <String>{};
  final validRefresh = <String>{};
  final calls = <String>[];
  final authHeaders = <String, String?>{};
  bool offline = false;
  var _n = 0;

  late final client = MockClient((request) async {
    if (offline) throw http.ClientException('offline');
    final path = request.url.path.replaceFirst('/v1', '');
    calls.add('${request.method} $path');
    authHeaders[path] = request.headers['Authorization'];
    final body = request.body.isEmpty ? null : jsonDecode(request.body);

    if (path == '/auth/guest') return _json(201, _tokens());
    if (path == '/auth/email/signin') return _json(200, _tokens(guest: false));
    if (path == '/auth/refresh') {
      if (!validRefresh.remove(body['refresh'])) return _error(401, 'invalid_refresh_token');
      return _json(200, _tokens());
    }

    final access = request.headers['Authorization']?.replaceFirst('Bearer ', '');
    if (!validAccess.contains(access)) return _error(401, 'token_not_valid');

    if (path == '/progress' && request.method == 'GET') return _json(200, _map());
    if (path == '/progress/merge') {
      (body as Map<String, dynamic>)
          .forEach((k, v) => progress.putIfAbsent(int.parse(k), () => {}).addAll((v as List).cast<int>()));
      return _json(200, _map());
    }
    final surah = int.parse(path.split('/').last);
    final at = DateTime.parse(body['updated_at'] as String);
    if (clock[surah] != null && clock[surah]!.isAfter(at)) {
      return _json(409, {
        'surah': surah,
        'ayahs': progress[surah]?.toList() ?? [],
        'error': {'code': 'stale_write', 'message': 'newer'},
      });
    }
    progress[surah] = (body['ayahs'] as List).cast<int>().toSet();
    clock[surah] = at;
    return _json(200, {'surah': surah, 'ayahs': body['ayahs'], 'updated_at': body['updated_at']});
  });

  Map<String, dynamic> _tokens({bool guest = true}) {
    _n++;
    validAccess.add('a$_n');
    validRefresh.add('r$_n');
    return {
      'access': 'a$_n',
      'refresh': 'r$_n',
      'user': {'id': 'u$_n', 'email': guest ? null : 'a@b.co', 'display_name': '', 'is_guest': guest},
    };
  }

  Map<String, dynamic> _map() => {
        for (final s in progress.keys.toList()..sort())
          if (progress[s]!.isNotEmpty) '$s': progress[s]!.toList()..sort(),
      };

  static http.Response _json(int status, Object body) =>
      http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

  static http.Response _error(int status, String code) => _json(status, {
        'error': {'code': code, 'message': code}
      });
}

void main() {
  late FakeServer server;
  late MemoryTokenStore tokens;
  late ApiClient api;

  setUp(() {
    server = FakeServer();
    tokens = MemoryTokenStore();
    api = ApiClient(baseUrl: 'http://test/v1', tokens: tokens, client: server.client);
  });

  Future<(LearnedStore, ProgressSync, SharedPreferences)> setUpSync([Map<String, Object> saved = const {}]) async {
    SharedPreferences.setMockInitialValues(saved);
    final prefs = await SharedPreferences.getInstance();
    final store = LearnedStore.load(prefs);
    var t = DateTime.utc(2026, 11, 19, 10);
    final sync =
        ProgressSync(client: api, store: store, prefs: prefs, clock: () => t = t.add(const Duration(seconds: 1)))
          ..attach();
    return (store, sync, prefs);
  }

  group('ApiClient', () {
    test('turns the server error shape into an ApiException with fields', () async {
      final client = ApiClient(
        baseUrl: 'http://test/v1',
        tokens: MemoryTokenStore(),
        client: MockClient((_) async => http.Response(
            jsonEncode({
              'error': {
                'code': 'invalid',
                'message': 'Bad email',
                'fields': {
                  'email': ['Bad email']
                }
              }
            }),
            400)),
      );
      final error =
          await client.post('/auth/email/check', {'email': 'x'}).then<Object?>((_) => null, onError: (e) => e);
      expect(error, isA<ApiException>().having((e) => e.field('email'), 'email', 'Bad email'));
    });

    test('a network failure is an offline ApiException', () async {
      server.offline = true;
      expect(() => api.get('/progress'), throwsA(isA<ApiException>().having((e) => e.isOffline, 'offline', true)));
    });

    test('an expired access token is refreshed once and the call retried', () async {
      await tokens.write(const Tokens(access: 'expired', refresh: 'r0'));
      server.validRefresh.add('r0');
      expect(await api.get('/progress'), <String, dynamic>{});
      expect(server.calls, ['GET /progress', 'POST /auth/refresh', 'GET /progress']);
      expect(tokens.tokens!.refresh, isNot('r0'));
    });

    test('a rejected refresh clears the session', () async {
      await tokens.write(const Tokens(access: 'expired', refresh: 'revoked'));
      await expectLater(
          api.get('/progress'), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'session_expired')));
      expect(tokens.tokens, isNull);
      expect(await api.hasSession, isFalse);
    });
  });

  group('ProgressSync', () {
    test('first sync creates a guest and merges the device progress into it', () async {
      final (store, sync, _) = await setUpSync({LearnedStore.key: '{"68":[1,2,3]}'});
      await sync.sync();
      expect(server.calls.take(2), ['POST /auth/guest', 'POST /progress/merge']);
      expect(server.progress, {
        68: {1, 2, 3}
      });
      expect(tokens.tokens, isNotNull);
      expect(store.ayahsOf(68), {1, 2, 3});
    });

    test('a commit is sent to the server', () async {
      final (store, sync, prefs) = await setUpSync();
      await sync.sync();
      await store.commit(68, {4, 5});
      await sync.sync();
      expect(server.progress[68], {4, 5});
      expect(prefs.getString(ProgressSync.pendingKey), '{}');
    });

    test('commits made offline wait in the queue and go out when back online', () async {
      final (store, sync, prefs) = await setUpSync();
      await sync.sync();
      server.offline = true;
      await store.commit(68, {1});
      await store.commit(1, {1, 2});
      await sync.sync();
      expect(jsonDecode(prefs.getString(ProgressSync.pendingKey)!), hasLength(2));

      server.offline = false;
      await sync.sync();
      expect(server.progress, {
        68: {1},
        1: {1, 2}
      });
      expect(prefs.getString(ProgressSync.pendingKey), '{}');
    });

    test('a newer write on the server wins and replaces the local set', () async {
      final (store, sync, _) = await setUpSync();
      await sync.sync();
      server.progress[68] = {7, 8};
      server.clock[68] = DateTime.utc(2030); // another device, later
      await store.commit(68, {1});
      await sync.sync();
      expect(store.ayahsOf(68), {7, 8});
      expect(server.progress[68], {7, 8});
    });

    test('with nothing queued, changes from other devices come down', () async {
      final (store, sync, _) = await setUpSync();
      await sync.sync();
      server.progress[2] = {1, 2, 3};
      await sync.sync();
      expect(store.ayahsOf(2), {1, 2, 3});
    });

    test('a merge never overwrites a surah that is still queued', () async {
      final (store, sync, _) = await setUpSync({LearnedStore.key: '{"68":[1,2]}'});
      server.offline = true;
      await store.commit(68, {1}); // un-mark ayah 2 while offline, before any account exists
      server.offline = false;
      server.progress[68] = {2};
      await sync.sync();
      expect(store.ayahsOf(68), {1});
      expect(server.progress[68], {1});
    });

    test('signing in sends the guest token and merges the device progress into the account', () async {
      final (store, sync, prefs) = await setUpSync({LearnedStore.key: '{"68":[1]}'});
      await sync.sync();
      final guestAccess = tokens.tokens!.access;

      final auth = AuthApi(api, onSignedIn: sync.accountChanged);
      await auth.signIn(email: 'a@b.co', password: 'secret123');

      expect(server.authHeaders['/auth/email/signin'], 'Bearer $guestAccess');
      expect(tokens.tokens!.access, isNot(guestAccess));
      expect(auth.user!.isGuest, isFalse);
      expect(server.calls.where((c) => c == 'POST /progress/merge'), hasLength(2));
      expect(prefs.getBool(ProgressSync.mergedKey), isTrue);
      expect(store.ayahsOf(68), {1});
    });
  });
}
