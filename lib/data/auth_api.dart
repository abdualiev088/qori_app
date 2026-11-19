import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'social_sign_in.dart';

export 'api_client.dart' show ApiException;
export 'social_sign_in.dart' show SignInCancelled;

/// The signed-in user, as the server describes them.
class QoriUser {
  const QoriUser({required this.id, this.email, this.displayName = '', this.isGuest = false, this.hasPassword = false});

  factory QoriUser.fromJson(Map<String, dynamic> json) => QoriUser(
        id: json['id'] as String,
        email: json['email'] as String?,
        displayName: (json['display_name'] as String?) ?? '',
        isGuest: (json['is_guest'] as bool?) ?? false,
        hasPassword: (json['has_password'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'email': email, 'display_name': displayName, 'is_guest': isGuest, 'has_password': hasPassword};

  final String id;
  final String? email;
  final String displayName;
  final bool isGuest;

  /// False for accounts made with Apple or Google only.
  final bool hasPassword;
}

/// Sign-in calls. Everything the sign-in screen needs from the server goes through here.
///
/// Every call sends the current guest token, so the server carries the
/// guest's progress over to the account (see the backend's docs/api.md).
/// Failures throw [ApiException]; closing the Apple or Google sheet throws
/// [SignInCancelled].
class AuthApi {
  AuthApi(this._client, {SocialSignIn? social, this.onSignedIn, SharedPreferences? prefs})
      : _social = social ?? SocialSignIn(),
        _prefs = prefs {
    user = _readCachedUser();
  }

  final ApiClient _client;
  final SocialSignIn _social;

  /// Remembers who is signed in, so the app still knows offline.
  final SharedPreferences? _prefs;
  static const userKey = 'qori.user.v1';

  /// Runs after every successful sign-in or sign-up, with the new tokens saved.
  /// The app merges the device's progress into the account here.
  final Future<void> Function()? onSignedIn;

  QoriUser? _user;

  QoriUser? get user => _user;

  set user(QoriUser? value) {
    _user = value;
    final prefs = _prefs;
    if (prefs == null) return;
    value == null ? prefs.remove(userKey) : prefs.setString(userKey, jsonEncode(value.toJson()));
  }

  QoriUser? _readCachedUser() {
    final raw = _prefs?.getString(userKey);
    if (raw == null) return null;
    try {
      return QoriUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Signed in to a real account, not the automatic guest one.
  bool get signedIn => user != null && !user!.isGuest;

  /// Refreshes who is signed in from the server. Returns false when the server
  /// can't be reached; the remembered user then stays, so the app keeps
  /// showing the signed-in state offline. A session the server has ended
  /// (or that no longer exists) clears it.
  Future<bool> loadMe() async {
    if (!await _client.hasSession) {
      user = null;
      return true;
    }
    try {
      user = QoriUser.fromJson(await _client.get('/me') as Map<String, dynamic>);
      return true;
    } on ApiException catch (e) {
      if (e.isOffline || e.status >= 500) return false;
      if (!await _client.hasSession) user = null; // the refresh token was rejected too
      return true;
    }
  }

  Future<void> updateName(String name) async =>
      user = QoriUser.fromJson(await _client.patch('/me', {'display_name': name.trim()}) as Map<String, dynamic>);

  /// Revokes this device's session. Progress stays on the device and syncs to a
  /// fresh guest account, as on first launch.
  Future<void> signOut() async {
    final refresh = await _client.refreshToken;
    try {
      if (refresh != null) await _client.post('/auth/signout', {'refresh': refresh});
    } on ApiException {
      // Already revoked or offline: signing out locally is what matters.
    }
    await _endSession();
  }

  /// Deletes the account and all its data on the server.
  Future<void> deleteAccount() async {
    await _client.delete('/me');
    await _endSession();
  }

  Future<void> _endSession() async {
    await _client.setTokens(null);
    user = null;
    await onSignedIn?.call(); // starts a new guest session
  }

  Future<bool> accountExists(String email) async {
    final res = await _client.post('/auth/email/check', {'email': email.trim()}) as Map<String, dynamic>;
    return res['exists'] == true;
  }

  Future<void> signIn({required String email, required String password}) async =>
      _adopt(await _client.post('/auth/email/signin', {'email': email.trim(), 'password': password}));

  Future<void> createAccount({required String name, required String email, required String password}) async => _adopt(
      await _client.post('/auth/email/signup', {'name': name.trim(), 'email': email.trim(), 'password': password}));

  Future<void> sendPasswordReset(String email) => _client.post('/auth/password/reset', {'email': email.trim()});

  Future<void> signInWithApple() async => _signInWith('apple', await _social.apple());

  Future<void> signInWithGoogle() async => _signInWith('google', await _social.google());

  Future<void> _signInWith(String provider, SocialCredential credential) async => _adopt(await _client
      .post('/auth/social', {'provider': provider, 'id_token': credential.idToken, 'name': credential.name}));

  Future<void> _adopt(dynamic response) async {
    final json = response as Map<String, dynamic>;
    await _client.setTokens(Tokens.fromJson(json));
    user = QoriUser.fromJson(json['user'] as Map<String, dynamic>);
    await onSignedIn?.call();
  }
}
