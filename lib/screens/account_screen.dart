import 'package:flutter/material.dart';

import '../data/auth_api.dart';
import '../theme/tokens.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/hifdth_card.dart';
import '../widgets/hifdth_mood.dart';

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

  String get _name {
    final n = _user.displayName.trim();
    return n.isNotEmpty ? n : (_user.email ?? 'Your account');
  }

  void _toast(String text) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));

  Future<void> _editName() async {
    final name = await showDialog<String>(context: context, builder: (_) => _NameDialog(initial: _user.displayName));
    if (name == null || name.trim().isEmpty || name.trim() == _user.displayName) return;
    try {
      await widget.api.updateName(name);
      if (mounted) setState(() => _user = widget.api.user ?? _user);
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<void> _resetPassword() async {
    final email = _user.email;
    if (email == null) return;
    try {
      await widget.api.sendPasswordReset(email);
      _toast('We sent a reset link to $email');
    } on ApiException catch (e) {
      _toast(e.message);
    }
  }

  Future<bool> _confirm({required String title, required String body, required String action}) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFC03535)),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _logOut() async {
    final ok = await _confirm(
      title: 'Log out?',
      body: 'Your progress stays on this phone. Sign in again to sync it with your account.',
      action: 'Log out',
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    await widget.api.signOut();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final ok = await _confirm(
      title: 'Delete your account?',
      body: 'Your account and its synced progress are deleted for good. This can\'t be undone.',
      action: 'Delete',
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
                child: Text('ACCOUNT SETTINGS',
                    style: HText.inter(size: 12, weight: FontWeight.w600, color: HColors.inkMuted, letterSpacing: 0.8)),
              ),
              _Section(children: [
                _Row(
                  icon: Icons.person_outline_rounded,
                  label: 'Name',
                  value: _user.displayName.isEmpty ? 'Add your name' : _user.displayName,
                  onTap: _editName,
                ),
                _Row(icon: Icons.mail_outline_rounded, label: 'Email', value: email ?? 'Not set'),
                if (_user.hasPassword)
                  _Row(
                    icon: Icons.lock_outline_rounded,
                    label: 'Password',
                    value: 'Send reset link',
                    onTap: _resetPassword,
                  ),
                _Row(
                  icon: Icons.delete_outline_rounded,
                  label: 'Delete account',
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
                        Text('Log out',
                            style: HText.inter(size: 17, weight: FontWeight.w600, color: const Color(0xFFC03535))),
                      ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Edits the name; owns its text controller so it outlives the closing animation.
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
          style: HText.inter(size: 16),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, _controller.text), child: const Text('Save')),
        ],
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

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, this.value, this.onTap, this.danger = false});
  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? const Color(0xFFC03535) : HColors.ink;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              Icon(icon, size: 22, color: danger ? color : HColors.ink2),
              const SizedBox(width: 18),
              Text(label, style: HText.inter(size: 16, weight: FontWeight.w500, color: color)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(value ?? '',
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: HText.inter(size: 15, color: HColors.inkMuted)),
              ),
              if (onTap != null && !danger) ...[
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFFB4BCC5)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
