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
  AuthApi(this._client, {SocialSignIn? social, this.onSignedIn}) : _social = social ?? SocialSignIn();

  final ApiClient _client;
  final SocialSignIn _social;

  /// Runs after every successful sign-in or sign-up, with the new tokens saved.
  /// The app merges the device's progress into the account here.
  final Future<void> Function()? onSignedIn;

  QoriUser? user;

  /// Signed in to a real account, not the automatic guest one.
  bool get signedIn => user != null && !user!.isGuest;

  /// Loads who is signed in, for a session saved from an earlier launch.
  Future<void> loadMe() async {
    if (!await _client.hasSession) return;
    try {
      user = QoriUser.fromJson(await _client.get('/me') as Map<String, dynamic>);
    } on ApiException {
      // Offline or the session expired; the profile button shows sign-in until it loads.
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
