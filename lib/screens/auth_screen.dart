import 'package:flutter/material.dart';

import '../data/auth_api.dart';
import '../theme/tokens.dart';
import '../widgets/auth_widgets.dart';
import 'account_screen.dart';

enum _Step { email, password, create }

/// Sign in or create an account, email first: one field, then the app shows
/// the password step for a known email or the sign-up step for a new one,
/// so nobody has to pick between "sign in" and "create account".
///
/// Once signed in, the account page takes this screen's place (so Back
/// from it returns to where sign-in was opened), and the route completes with `true`.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.api});

  final AuthApi api;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _Step _step = _Step.email;
  final _email = TextEditingController();
  final _name = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _tried = false;
  bool _loading = false;

  /// What the server rejected, shown under that field until the user types again.
  ({String field, String message})? _server;

  String? _serverError(String field) => _server?.field == field ? _server!.message : null;

  String? get _emailError => (_tried ? validateEmail(_email.text) : null) ?? _serverError('email');
  String? get _nameError => (_tried && _name.text.trim().isEmpty ? 'Enter your name' : null) ?? _serverError('name');
  String? get _passwordError {
    if (_tried && _password.text.isEmpty) return 'Enter your password';
    if (_tried && _step == _Step.create && _password.text.length < 8) return 'Use at least 8 characters';
    return _serverError('password');
  }

  void _edited(String _) => setState(() => _server = null);

  /// Runs a server call with the spinner on. A rejected field gets its message
  /// next to it; anything else (offline, server down) shows a snackbar.
  /// Returns whether the call succeeded.
  Future<bool> _call(Future<void> Function() call) async {
    setState(() {
      _loading = true;
      _server = null;
    });
    try {
      await call();
      return true;
    } on SignInCancelled {
      return false;
    } on ApiException catch (e) {
      if (!mounted) return false;
      final field = ['name', 'email', 'password'].where((f) => e.field(f) != null).firstOrNull;
      if (field != null) {
        setState(() => _server = (field: field, message: e.field(field)!));
      } else if (e.code == 'invalid_credentials') {
        setState(() => _server = (field: 'password', message: e.message));
      } else {
        _snack(e.message);
      }
      return false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));

  Future<void> _continue() async {
    if (_loading) return;
    setState(() => _tried = true);
    if (_emailError != null) return;
    late bool exists;
    if (!await _call(() async => exists = await widget.api.accountExists(_email.text.trim())) || !mounted) return;
    setState(() {
      _tried = false;
      _step = exists ? _Step.password : _Step.create;
    });
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _tried = true);
    if (_passwordError != null || (_step == _Step.create && _nameError != null)) return;
    FocusScope.of(context).unfocus();
    final email = _email.text.trim();
    final ok = await _call(() => _step == _Step.create
        ? widget.api.createAccount(name: _name.text.trim(), email: email, password: _password.text)
        : widget.api.signIn(email: email, password: _password.text));
    if (ok && mounted) _signedIn();
  }

  Future<void> _social(Future<void> Function() call) async {
    if (_loading) return;
    if (await _call(call) && mounted) _signedIn();
  }

  void _signedIn() {
    final navigator = Navigator.of(context);
    if (!widget.api.signedIn) {
      navigator.pop(true);
      return;
    }
    navigator.pushReplacement(MaterialPageRoute<void>(builder: (_) => AccountScreen(api: widget.api)), result: true);
  }

  Future<void> _forgot() async {
    if (_loading) return;
    final email = _email.text.trim();
    if (await _call(() => widget.api.sendPasswordReset(email)) && mounted) _snack('We sent a reset link to $email');
  }

  void _back() => setState(() {
        _step = _Step.email;
        _tried = false;
        _server = null;
        _password.clear();
      });

  @override
  void dispose() {
    for (final c in [_email, _name, _password]) {
      c.dispose();
    }
    _passwordFocus.dispose();
    super.dispose();
  }

  /// The email, shown as a chip with a way to change it.
  Widget _emailChip() => Container(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE1E6EC)),
        ),
        child: Row(children: [
          const Icon(Icons.mail_outline_rounded, size: 20, color: HColors.inkMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_email.text.trim(),
                overflow: TextOverflow.ellipsis, style: HText.inter(size: 16, weight: FontWeight.w500)),
          ),
          TextButton(
            onPressed: _back,
            style: TextButton.styleFrom(foregroundColor: HColors.accentDeep, minimumSize: const Size(44, 40)),
            child: Text('Change', style: HText.inter(size: 14, weight: FontWeight.w600, color: HColors.accentDeep)),
          ),
        ]),
      );

  Widget _emailStep() => Column(key: const ValueKey(_Step.email), children: [
        AutofillGroup(
          child: AuthField(
            label: 'Email',
            hint: 'you@example.com',
            icon: Icons.mail_outline_rounded,
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email, AutofillHints.username],
            textInputAction: TextInputAction.go,
            error: _emailError,
            onChanged: _edited,
            onSubmitted: (_) => _continue(),
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: 'Continue', loading: _loading, onPressed: _continue),
        const SizedBox(height: 28),
        const OrDivider(text: 'or'),
        const SizedBox(height: 20),
        AppleButton(label: 'Continue with Apple', onPressed: () => _social(widget.api.signInWithApple)),
        const SizedBox(height: 12),
        GoogleButton(label: 'Continue with Google', onPressed: () => _social(widget.api.signInWithGoogle)),
      ]);

  Widget _passwordStep() {
    final create = _step == _Step.create;
    return AutofillGroup(
      key: ValueKey(_step),
      child: Column(children: [
        _emailChip(),
        const SizedBox(height: 20),
        if (create) ...[
          AuthField(
            label: 'Name',
            hint: 'Your name',
            icon: Icons.person_outline_rounded,
            controller: _name,
            autofocus: true,
            autofillHints: const [AutofillHints.name],
            capitalization: TextCapitalization.words,
            error: _nameError,
            onChanged: _edited,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 16),
        ],
        AuthField(
          label: 'Password',
          hint: create ? 'Create a password' : 'Your password',
          icon: Icons.lock_outline_rounded,
          controller: _password,
          focusNode: _passwordFocus,
          autofocus: !create,
          password: true,
          autofillHints: [create ? AutofillHints.newPassword : AutofillHints.password],
          textInputAction: TextInputAction.go,
          error: _passwordError,
          onChanged: _edited,
          onSubmitted: (_) => _submit(),
          trailingLabel: create
              ? null
              : GestureDetector(
                  onTap: _forgot,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('Forgot password?',
                        style: HText.inter(size: 14, weight: FontWeight.w600, color: HColors.accentDeep)),
                  ),
                ),
        ),
        if (create && _passwordError == null) PasswordRules(password: _password.text),
        const SizedBox(height: 24),
        PrimaryButton(label: create ? 'Create account' : 'Sign in', loading: _loading, onPressed: _submit),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = switch (_step) {
      _Step.email => ('Sign in or sign up', 'Enter your email and Hifdth will take it from there.'),
      _Step.password => ('Welcome back', 'Enter your password to pick up where you left off.'),
      _Step.create => ('Nice to meet you', 'Two more things and your progress is saved everywhere.'),
    };
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 110),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GlassBackButton(onTap: _step == _Step.email ? () => Navigator.of(context).pop() : _back),
                ),
                const SizedBox(height: 16),
                AuthHero(title: title, subtitle: subtitle, speaking: _step != _Step.email),
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: const Cubic(0.32, 0.72, 0, 1),
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (child, a) => FadeTransition(
                    opacity: a,
                    child: SlideTransition(
                      position: Tween(begin: const Offset(0.06, 0), end: Offset.zero).animate(a),
                      child: child,
                    ),
                  ),
                  child: _step == _Step.email ? _emailStep() : _passwordStep(),
                ),
                const SizedBox(height: 28),
                const TermsFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
