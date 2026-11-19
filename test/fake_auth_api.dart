import 'package:qori_app/data/auth_api.dart';

/// Stands in for the server in widget tests: an email counts as known once it
/// has created an account, and [failNext] makes the next call throw.
class FakeAuthApi implements AuthApi {
  final _accounts = <String>{};

  /// Thrown by the next call, then cleared.
  Object? failNext;

  @override
  QoriUser? user;

  @override
  Future<void> Function()? get onSignedIn => null;

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
      user = QoriUser(id: 'u1', email: email?.trim().toLowerCase(), displayName: name, hasPassword: hasPassword);

  @override
  Future<void> sendPasswordReset(String email) => _maybeFail();

  @override
  bool get signedIn => user != null && !user!.isGuest;

  @override
  Future<void> loadMe() async {}

  @override
  Future<void> updateName(String name) async {
    await _maybeFail();
    final u = user!;
    user = QoriUser(id: u.id, email: u.email, displayName: name.trim(), hasPassword: u.hasPassword);
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
