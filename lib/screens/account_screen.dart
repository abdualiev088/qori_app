import 'package:flutter/material.dart';

import '../data/auth_api.dart';
import '../theme/tokens.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/hifdth_card.dart';
import '../widgets/hifdth_mood.dart';
import '../widgets/toast.dart';
import '../l10n/l10n.dart';

/// Shown when the account page opens without internet.

/// The signed-in account: name, email, password reset, and log out.
/// Pops after logging out or deleting the account.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key, required this.api});

  final AuthApi api;

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _busy = false;

  /// Kept here so the page can still draw while it closes after logging out.
  late QoriUser _user = widget.api.user!;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  /// Brings the account up to date. Offline, the remembered account stays on
  /// screen and a notice asks to turn the internet on.
  Future<void> _refresh() async {
    final online = await widget.api.loadMe();
    if (!mounted) return;
    if (!online) {
      _toast(context.l10n.accountOffline);
      return;
    }
    final user = widget.api.user;
    if (user == null || user.isGuest) {
      // The server ended this session (signed out elsewhere, or deleted).
      _toast(context.l10n.signedOutResync);
      Navigator.of(context).pop();
      return;
    }
    setState(() => _user = user);
  }

  String get _name {
    final n = _user.displayName.trim();
    return n.isNotEmpty ? n : (_user.email ?? context.l10n.yourAccount);
  }

  void _toast(String text) => Toast.show(context, text);

  Future<void> _editName() async {
    final saved = await showAppSheet<bool>(
      context,
      (_) => _NameSheet(initial: _user.displayName, save: widget.api.updateName),
    );
    if (saved == true && mounted) setState(() => _user = widget.api.user ?? _user);
  }

  Future<void> _resetPassword() async {
    final email = _user.email;
    if (email == null) return;
    try {
      await widget.api.sendPasswordReset(email);
      _toast(context.l10n.resetLinkSent(email));
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<bool> _confirm({required String title, required String body, required String action, IconData? icon}) async =>
      await showAppSheet<bool>(context, (_) => _ConfirmSheet(title: title, body: body, action: action, icon: icon)) ??
      false;

  Future<void> _logOut() async {
    final ok = await _confirm(
      title: context.l10n.logOutQ,
      body: context.l10n.logOutBody,
      action: context.l10n.logOut,
      icon: Icons.logout_rounded,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    await widget.api.signOut();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await _confirm(
      title: context.l10n.deleteAccountQ,
      body: context.l10n.deleteAccountBody,
      action: context.l10n.deleteAccount,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.api.deleteAccount();
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _user.email;
    return Scaffold(
      body: AuthBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            children: [
              Align(alignment: Alignment.centerLeft, child: GlassBackButton(onTap: () => Navigator.of(context).pop())),
              const SizedBox(height: 8),
              const Center(child: HifdthAvatar(mood: HifdthMood.happy, size: 72)),
              const SizedBox(height: 14),
              Text(_name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: HText.inter(size: 24, weight: FontWeight.w700, letterSpacing: -0.4)),
              if (email != null && email != _name) ...[
                const SizedBox(height: 4),
                Text(email,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: HText.inter(size: 15, color: HColors.ink2)),
              ],
              const SizedBox(height: 28),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(context.l10n.accountSettingsCaps,
                    style: HText.inter(size: 12, weight: FontWeight.w600, color: HColors.inkMuted, letterSpacing: 0.8)),
              ),
              _Section(children: [
                _Row(
                  icon: Icons.person_outline_rounded,
                  label: context.l10n.name,
                  value: _user.displayName.isEmpty ? context.l10n.addYourName : _user.displayName,
                  onTap: _editName,
                ),
                _Row(icon: Icons.mail_outline_rounded, label: context.l10n.email, value: email ?? context.l10n.notSet),
                if (_user.hasPassword)
                  _Row(
                    icon: Icons.lock_outline_rounded,
                    label: context.l10n.password,
                    value: context.l10n.sendResetLink,
                    onTap: _resetPassword,
                  ),
                _Row(
                  icon: Icons.delete_outline_rounded,
                  label: context.l10n.deleteAccount,
                  danger: true,
                  onTap: _busy ? null : _delete,
                ),
              ]),
              const SizedBox(height: 28),
              PressableButton(
                onPressed: _busy ? null : _logOut,
                background: Colors.white,
                border: const Color(0xFFF0C9C9),
                child: _busy
                    ? const SizedBox.square(
                        dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Color(0xFFC03535)))
                    : Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.logout_rounded, size: 21, color: Color(0xFFC03535)),
                        const SizedBox(width: 10),
                        Text(context.l10n.logOut, style: HText.button(color: const Color(0xFFC03535))),
                      ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens [builder] in the app's bottom sheet: white, rounded, with a grabber,
/// lifted above the keyboard.
Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x5917202A),
      elevation: 0,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(24, 10, 24, 20 + MediaQuery.paddingOf(context).bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(color: const Color(0xFFDCE2E8), borderRadius: BorderRadius.circular(3)),
              ),
            ),
            const SizedBox(height: 20),
            builder(context),
          ]),
        ),
      ),
    );

/// Edits the name in place: prefilled, Done saves, the error sits under the
/// field, and Save shows a spinner while the server answers. Pops `true` once saved.
class _NameSheet extends StatefulWidget {
  const _NameSheet({required this.initial, required this.save});
  final String initial;
  final Future<void> Function(String name) save;

  @override
  State<_NameSheet> createState() => _NameSheetState();
}

class _NameSheetState extends State<_NameSheet> {
  late final _controller = TextEditingController(text: widget.initial);
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.l10n.enterName);
      return;
    }
    if (name == widget.initial.trim()) {
      Navigator.pop(context, false);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.save(name);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.field('display_name') ?? e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(context.l10n.yourName, style: HText.inter(size: 20, weight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(context.l10n.nameGreeting, style: HText.inter(size: 15, color: HColors.ink2)),
        const SizedBox(height: 20),
        AutofillGroup(
          child: AuthField(
            label: context.l10n.name,
            hint: context.l10n.yourName,
            icon: Icons.person_outline_rounded,
            controller: _controller,
            // The sheet exists only to type a name, so the keyboard opening with it is expected.
            autofocus: true,
            autofillHints: const [AutofillHints.name],
            capitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            error: _error,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: 20),
        PrimaryButton(label: context.l10n.save, loading: _saving, onPressed: _submit),
        const SizedBox(height: 4),
        _TextAction(label: context.l10n.cancel, onTap: _saving ? null : () => Navigator.pop(context, false)),
      ]);
}

/// Asks before something that can't be quietly undone. Pops `true` to go ahead.
class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({required this.title, required this.body, required this.action, this.icon});
  final String title;
  final String body;
  final String action;
  final IconData? icon;

  static const _red = Color(0xFFC03535);

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (icon != null) ...[
          Center(
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(color: Color(0xFFFCEBEB), shape: BoxShape.circle),
              child: Icon(icon, color: _red, size: 26),
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text(title, textAlign: TextAlign.center, style: HText.inter(size: 20, weight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(body, textAlign: TextAlign.center, style: HText.inter(size: 15, color: HColors.ink2, height: 1.45)),
        const SizedBox(height: 24),
        PressableButton(
          onPressed: () => Navigator.pop(context, true),
          background: _red,
          child: Text(action, style: HText.button(color: Colors.white)),
        ),
        const SizedBox(height: 4),
        _TextAction(label: context.l10n.cancel, onTap: () => Navigator.pop(context, false)),
      ]);
}

/// A quiet full-width text button, 48 px tall so it's easy to hit.
class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Center(child: Text(label, style: HText.button(color: HColors.ink2))),
          ),
        ),
      );
}

/// A white rounded card of rows separated by hairlines.
class _Section extends StatelessWidget {
  const _Section({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(HRadii.card),
          border: Border.all(color: const Color(0xFFE6EBF0)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 56, color: HColors.divider),
            children[i],
          ],
        ]),
      );
}

class _Row extends StatefulWidget {
  const _Row({required this.icon, required this.label, this.value, this.onTap, this.danger = false});
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool danger;

  @override
  State<_Row> createState() => _RowState();
}

/// Rows tint while pressed, like an iOS list, instead of a Material ripple.
class _RowState extends State<_Row> {
  bool _down = false;

  void _press(bool down) {
    if (widget.onTap != null && _down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.danger ? const Color(0xFFC03535) : HColors.ink;
    return Semantics(
      button: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: _down ? 0 : 200),
          color: _down ? const Color(0xFFF1F4F7) : Colors.white,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Icon(widget.icon, size: 22, color: widget.danger ? color : HColors.ink2),
            const SizedBox(width: 18),
            Text(widget.label, style: HText.inter(size: 16, weight: FontWeight.w500, color: color)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(widget.value ?? '',
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: HText.inter(size: 15, color: HColors.inkMuted)),
            ),
            if (widget.onTap != null && !widget.danger) ...[
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFFB4BCC5)),
            ],
          ]),
        ),
      ),
    );
  }
}
