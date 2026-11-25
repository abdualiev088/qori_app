import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Where the Qori API lives. Pass `--dart-define=QORI_API_URL=https://api.example.com/v1`
/// for a deployed server; without it, a dev server on this machine
/// (the Android emulator reaches the host at 10.0.2.2).
String defaultApiUrl() {
  const fromEnv = String.fromEnvironment('QORI_API_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  return defaultTargetPlatform == TargetPlatform.android ? 'http://10.0.2.2:8000/v1' : 'http://127.0.0.1:8000/v1';
}

/// Sends [request], allowing plain http when its URL is http.
///
/// Flutter refuses plain http to anything but localhost unless the zone
/// opts in. Only a dev server (on this Mac, reached from a phone) uses http;
/// a real server is https and keeps the platform's default.
Future<http.StreamedResponse> sendAllowingDevHttp(http.Client client, http.BaseRequest request) =>
    request.url.isScheme('http')
        ? runZoned(() => client.send(request), zoneValues: {#flutter.io.allow_http: true})
        : client.send(request);

/// A failed call. The server sends `{"error": {"code", "message", "fields"}}`;
/// [fields] maps request fields (email, password, ...) to their messages.
class ApiException implements Exception {
  ApiException(this.status, this.code, this.message, {this.fields = const {}, this.body});

  factory ApiException.offline([String? detail]) => ApiException(0, 'offline',
      "Can't reach Qori right now. Check your connection and try again.${detail == null ? '' : '\n\n$detail'}");

  /// The HTTP status, or 0 when the server couldn't be reached.
  final int status;
  final String code;
  final String message;
  final Map<String, List<String>> fields;

  /// The decoded response body, for errors that carry data (a 409 on progress does).
  final Object? body;

  bool get isOffline => status == 0;

  /// The first message for [field], if the server rejected it.
  String? field(String field) => fields[field]?.firstOrNull;

  @override
  String toString() => 'ApiException($status $code: $message)';
}

class Tokens {
  const Tokens({required this.access, required this.refresh});

  factory Tokens.fromJson(Map<String, dynamic> json) =>
      Tokens(access: json['access'] as String, refresh: json['refresh'] as String);

  final String access;
  final String refresh;

  Map<String, String> toJson() => {'access': access, 'refresh': refresh};
}

/// Keeps the session's tokens between launches.
abstract class TokenStore {
  Future<Tokens?> read();
  Future<void> write(Tokens? tokens);
}

/// Tokens in the iOS Keychain / Android Keystore.
class SecureTokenStore implements TokenStore {
  SecureTokenStore([this._storage = const FlutterSecureStorage()]);

  static const _key = 'qori.tokens.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<Tokens?> read() async {
    try {
      final raw = await _storage.read(key: _key);
      return raw == null ? null : Tokens.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null; // Unreadable: start a fresh session rather than fail to launch.
    }
  }

  @override
  Future<void> write(Tokens? tokens) =>
      tokens == null ? _storage.delete(key: _key) : _storage.write(key: _key, value: jsonEncode(tokens.toJson()));
}

class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this.tokens]);

  Tokens? tokens;

  @override
  Future<Tokens?> read() async => tokens;

  @override
  Future<void> write(Tokens? tokens) async => this.tokens = tokens;
}

/// JSON over HTTPS to the Qori API, with the session's bearer token.
///
/// An expired access token is refreshed once and the call retried. If the
/// refresh token is rejected too, the session is cleared and the call fails
/// with `session_expired`.
class ApiClient {
  ApiClient(
      {required this.baseUrl,
      required TokenStore tokens,
      http.Client? client,
      this.timeout = const Duration(seconds: 15)})
      : _store = tokens,
        _http = client ?? http.Client();

  final String baseUrl;
  final Duration timeout;
  final TokenStore _store;
  final http.Client _http;

  Tokens? _tokens;
  bool _loaded = false;
  Future<bool>? _refreshing;

  Future<Tokens?> _current() async {
    if (!_loaded) {
      _tokens = await _store.read();
      _loaded = true;
    }
    return _tokens;
  }

  Future<bool> get hasSession async => await _current() != null;

  /// Whether the last request reached the server. Starts hopeful; the first
  /// failed request turns it off and the next successful one back on.
  final online = ValueNotifier<bool>(true);

  /// This device's refresh token, to revoke it on sign-out.
  Future<String?> get refreshToken async => (await _current())?.refresh;

  Future<void> setTokens(Tokens? tokens) async {
    _tokens = tokens;
    _loaded = true;
    await _store.write(tokens);
  }

  Future<dynamic> get(String path) => _send('GET', path);
  Future<dynamic> post(String path, [Object? body]) => _send('POST', path, body);
  Future<dynamic> put(String path, Object? body) => _send('PUT', path, body);
  Future<dynamic> patch(String path, Object? body) => _send('PATCH', path, body);
  Future<dynamic> delete(String path) => _send('DELETE', path);

  /// A POST without this device's session, for signing in to an existing
  /// account: the server then leaves the account's progress as it is
  /// instead of merging the guest's into it.
  Future<dynamic> postWithoutSession(String path, Object? body) async => _decode(await _raw('POST', path, body, null));

  Future<dynamic> _send(String method, String path, [Object? body, bool retry = true]) async {
    final tokens = await _current();
    final response = await _raw(method, path, body, tokens?.access);

    // The auth endpoints answer 401 for a wrong password; only other calls mean "token expired".
    if (response.statusCode == 401 && tokens != null && !path.startsWith('/auth/') && retry) {
      // Signed in to another account while this call was out: just retry with the new session.
      if (!identical(await _current(), tokens)) return _send(method, path, body, false);
      if (await _refresh()) return _send(method, path, body, false);
      throw ApiException(401, 'session_expired', 'Please sign in again.');
    }
    return _decode(response);
  }

  Future<http.Response> _raw(String method, String path, Object? body, String? access) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers['Accept'] = 'application/json'
      ..headers.addAll({if (access != null) 'Authorization': 'Bearer $access'});
    if (body != null) {
      request
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
    }
    try {
      final response =
          await http.Response.fromStream(await sendAllowingDevHttp(_http, request).timeout(timeout));
      online.value = true;
      return response;
    } catch (e) {
      online.value = false;
      // Debug builds say where they tried and why, so a build pointed at the
      // wrong server doesn't look like a network problem.
      throw ApiException.offline(kDebugMode ? '$baseUrl\n$e' : null);
    }
  }

  /// One refresh at a time, however many calls hit a 401 together.
  Future<bool> _refresh() => _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);

  Future<bool> _doRefresh() async {
    final before = await _current();
    final refresh = before?.refresh;
    if (refresh == null) return false;
    final response = await _raw('POST', '/auth/refresh', {'refresh': refresh}, null);
    // A sign-in may have replaced the session meanwhile; never touch the new one.
    if (!identical(await _current(), before)) return true;
    if (response.statusCode == 200) {
      await setTokens(Tokens.fromJson(_decode(response) as Map<String, dynamic>));
      return true;
    }
    if (response.statusCode == 401) await setTokens(null);
    return false;
  }

  static dynamic _decode(http.Response response) {
    Object? json;
    if (response.body.isNotEmpty) {
      try {
        json = jsonDecode(utf8.decode(response.bodyBytes));
      } on FormatException {
        json = null;
      }
    }
    if (response.statusCode < 400) return json;

    final error = json is Map<String, dynamic> ? json['error'] : null;
    if (error is! Map<String, dynamic>) {
      throw ApiException(response.statusCode, 'http_${response.statusCode}', 'Something went wrong. Please try again.',
          body: json);
    }
    final fields = <String, List<String>>{
      for (final MapEntry(:key, :value) in ((error['fields'] as Map<String, dynamic>?) ?? {}).entries)
        key: [for (final m in value as List) '$m'],
    };
    throw ApiException(response.statusCode, '${error['code']}', '${error['message']}', fields: fields, body: json);
  }
}
