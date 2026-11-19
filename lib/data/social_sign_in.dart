import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'api_client.dart';

/// What the native Apple or Google sheet hands back: an ID token for the server
/// to check, and the user's name when the provider shares it.
class SocialCredential {
  const SocialCredential({required this.idToken, this.name = ''});

  final String idToken;
  final String name;
}

/// The user closed the Apple or Google sheet. Not an error: nothing to show.
class SignInCancelled implements Exception {}

/// The native Apple and Google sign-in sheets.
///
/// Google needs its OAuth client IDs, passed with --dart-define:
///   GOOGLE_IOS_CLIENT_ID     the iOS client (its reversed ID must also be a URL scheme in ios/Runner/Info.plist)
///   GOOGLE_SERVER_CLIENT_ID  the web client; ID tokens are then issued for it on every platform
/// The server must list the token's audience in GOOGLE_CLIENT_IDS.
class SocialSignIn {
  static const _googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
  static const _googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  Future<void>? _googleReady;

  Future<SocialCredential> apple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final token = credential.identityToken;
      if (token == null) throw _failed('Apple');
      // Apple shares the name only the first time; the server keeps it.
      final name = [credential.givenName, credential.familyName].whereType<String>().join(' ').trim();
      return SocialCredential(idToken: token, name: name);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) throw SignInCancelled();
      throw _notSetUp('Apple');
    } on SignInWithAppleException {
      throw _notSetUp('Apple');
    }
  }

  Future<SocialCredential> google() async {
    // Without a client ID the iOS SDK aborts the app instead of failing, so don't call it.
    final ios = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
    if ((ios && _googleIosClientId.isEmpty) || (!ios && _googleServerClientId.isEmpty)) throw _notSetUp('Google');

    try {
      await (_googleReady ??= GoogleSignIn.instance.initialize(
        clientId: _googleIosClientId.isEmpty ? null : _googleIosClientId,
        serverClientId: _googleServerClientId.isEmpty ? null : _googleServerClientId,
      ));
      if (!GoogleSignIn.instance.supportsAuthenticate()) throw _notSetUp('Google');
      final account = await GoogleSignIn.instance.authenticate();
      final token = account.authentication.idToken;
      if (token == null) throw _failed('Google');
      return SocialCredential(idToken: token, name: account.displayName ?? '');
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) throw SignInCancelled();
      throw e.code == GoogleSignInExceptionCode.clientConfigurationError ? _notSetUp('Google') : _failed('Google');
    }
  }

  static ApiException _notSetUp(String provider) => ApiException(
      -1, 'provider_not_configured', "Sign in with $provider isn't available yet. Use your email for now.");

  static ApiException _failed(String provider) =>
      ApiException(-1, 'social_failed', "Sign in with $provider didn't work. Please try again.");
}
