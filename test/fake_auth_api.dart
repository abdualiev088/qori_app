import 'package:flutter/foundation.dart';
import 'package:hifz_app/data/auth_api.dart';

/// Stands in for the server in widget tests: an email counts as known once it
/// has created an account, and [failNext] makes the next call throw.
class FakeAuthApi extends ChangeNotifier implements AuthApi {
  final _accounts = <String>{};

  /// Thrown by the next call, then cleared.
  Object? failNext;

  HifzUser? _user;

  @override
  HifzUser? get user => _user;

  @override
  set user(HifzUser? value) {
    _user = value;
    notifyListeners();
  }

  @override
  Future<void> Function({bool preferAccount})? get onSignedIn => null;

  @override
  Future<void> Function()? get onSignedOut => null;

  Future<void> _maybeFail() async {
    final error = failNext;
    failNext = null;
    if (error != null) throw error;
  }

  @override
  Future<bool> accountExists(String email) async {
    await _maybeFail();
    return _accounts.contains(email.trim().toLowerCase());
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _maybeFail();
    _signInAs(email: email);
  }

  @override
  Future<void> createAccount({required String name, required String email, required String password}) async {
    await _maybeFail();
    _accounts.add(email.trim().toLowerCase());
    _signInAs(email: email, name: name);
  }

  /// What the real AuthApi does on success: [user] becomes a signed-in account.
  void _signInAs({String? email, String name = '', bool hasPassword = true}) =>
      user = HifzUser(id: 'u1', email: email?.trim().toLowerCase(), displayName: name, hasPassword: hasPassword);

  @override
  Future<void> sendPasswordReset(String email) => _maybeFail();

  @override
  bool get signedIn => user != null && !user!.isGuest;

  @override
  Future<bool> loadMe() async => reachable;

  @override
  Future<void> dropUnlessSignedIn() async {
    if (!signedIn) user = null;
  }

  /// What [loadMe] reports: false acts like no internet.
  bool reachable = true;

  @override
  final ValueNotifier<bool> online = ValueNotifier(true);

  @override
  Future<void> updateName(String name) async {
    await _maybeFail();
    final u = user!;
    user = HifzUser(id: u.id, email: u.email, displayName: name.trim(), hasPassword: u.hasPassword);
  }

  @override
  Future<void> signOut() async => user = null;

  @override
  Future<void> deleteAccount() async {
    await _maybeFail();
    user = null;
  }

  @override
  Future<void> signInWithApple() async {
    await _maybeFail();
    _signInAs(hasPassword: false);
  }

  @override
  Future<void> signInWithGoogle() async {
    await _maybeFail();
    _signInAs(hasPassword: false);
  }
}

ApiException wrongPassword() => ApiException(401, 'invalid_credentials', 'Wrong email or password.');
