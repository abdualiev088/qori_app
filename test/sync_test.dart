import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:hifz_app/data/api_client.dart';
import 'package:hifz_app/data/auth_api.dart';
import 'package:hifz_app/data/learned_store.dart';
import 'package:hifz_app/data/progress_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A small in-memory stand-in for the Hifz backend, following docs/api.md.
class FakeServer {
  /// The signed-in account's progress. There are no guest accounts.
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

    if (path == '/auth/guest') return _error(404, 'not_found');
    if (path == '/auth/email/signin') return _json(200, _tokens());
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

  /// A new signed-in session, as the sign-in endpoints return it.
  Map<String, dynamic> _tokens() {
    _n++;
    validAccess.add('a$_n');
    validRefresh.add('r$_n');
    return {
      'access': 'a$_n',
      'refresh': 'r$_n',
      'user': {'id': 'u1', 'email': 'a@b.co', 'display_name': '', 'is_guest': false},
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

  /// Starts a signed-in session, as after signing in on an earlier launch.
  Future<void> signedIn() => api.setTokens(Tokens.fromJson(server._tokens()));

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
    test('signed out, nothing syncs and no session is made', () async {
      final (_, sync, _) = await setUpSync();
      await sync.sync();
      expect(server.calls, isEmpty);
      expect(await api.hasSession, isFalse);
    });

    test('the first sync of a session merges the phone into an empty account', () async {
      final (store, sync, _) = await setUpSync({LearnedStore.key: '{"68":[1,2,3]}'});
      await signedIn();
      await sync.sync();
      expect(server.calls.first, 'POST /progress/merge');
      expect(server.progress, {
        68: {1, 2, 3}
      });
      expect(store.ayahsOf(68), {1, 2, 3});
    });

    test('a commit is sent to the server', () async {
      final (store, sync, prefs) = await setUpSync();
      await signedIn();
      await sync.sync();
      await store.commit(68, {4, 5});
      await sync.sync();
      expect(server.progress[68], {4, 5});
      expect(prefs.getString(ProgressSync.pendingKey), '{}');
    });

    test('commits made offline wait in the queue and go out when back online', () async {
      final (store, sync, prefs) = await setUpSync();
      await signedIn();
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
      await signedIn();
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
      await signedIn();
      await sync.sync();
      server.progress[2] = {1, 2, 3};
      await sync.sync();
      expect(store.ayahsOf(2), {1, 2, 3});
    });

    test('signing in to an account with ayahs replaces what the phone had', () async {
      final (store, sync, _) = await setUpSync({LearnedStore.key: '{"68":[1]}'});
      server.progress[1] = {1, 2, 3};

      final auth = AuthApi(api, onSignedIn: sync.accountChanged);
      await auth.signIn(email: 'a@b.co', password: 'secret123');

      expect(server.authHeaders['/auth/email/signin'], isNull); // sign-in sends no session
      expect(store.toJson(), {
        '1': [1, 2, 3]
      });
      expect(server.progress.keys, [1]); // nothing from the phone was sent to the account
    });

    test('signing in to an empty account fills it with the phone\'s ayahs', () async {
      final (store, sync, _) = await setUpSync({LearnedStore.key: '{"68":[1,2]}'});

      final auth = AuthApi(api, onSignedIn: sync.accountChanged);
      await auth.signIn(email: 'a@b.co', password: 'secret123');

      expect(server.progress[68], {1, 2});
      expect(store.ayahsOf(68), {1, 2});
    });

    test('logging out clears the phone\'s progress and leaves no session', () async {
      final (store, sync, _) = await setUpSync();
      final auth = AuthApi(api, onSignedIn: sync.accountChanged, onSignedOut: sync.signedOut);
      server.progress[1] = {1, 2};
      await auth.signIn(email: 'a@b.co', password: 'secret123');
      expect(store.ayahsOf(1), {1, 2});

      await auth.signOut();

      expect(store.toJson(), isEmpty);
      expect(server.progress[1], {1, 2}); // the account keeps its ayahs
      expect(await api.hasSession, isFalse);
      expect(auth.signedIn, isFalse);
    });

    test('the client notices going offline and back online', () async {
      final (_, sync, _) = await setUpSync();
      await signedIn();
      server.offline = true;
      await sync.sync();
      expect(api.online.value, isFalse);
      server.offline = false;
      await sync.sync();
      expect(api.online.value, isTrue);
    });
  });
}
