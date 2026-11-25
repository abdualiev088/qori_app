import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/tokens.dart';
import 'glass.dart';
import 'hifdth_card.dart';
import 'hifdth_mood.dart';
import '../l10n/l10n.dart';

/// Page background with the soft mint glow at the top, like the mockup.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [HColors.bgTop, HColors.bgBottom],
          ),
        ),
        child: Stack(children: [
          Positioned(
            top: -160,
            left: -120,
            right: -40,
            height: 420,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [HColors.mintLight.withValues(alpha: 0.9), HColors.mintLight.withValues(alpha: 0)],
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ]),
      );
}

class GlassBackButton extends StatelessWidget {
  const GlassBackButton({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: context.l10n.back,
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox.square(
            dimension: 46,
            child: LiquidGlass(
              radius: 23,
              blur: 20,
              borderColor: const Color(0xD9FFFFFF),
              shadows: const [
                BoxShadow(color: Color(0x2414462D), offset: Offset(0, 8), blurRadius: 20),
                BoxShadow(color: Color(0x1A14462D), offset: Offset(0, 1), blurRadius: 3),
              ],
              fill: const RadialGradient(
                center: Alignment(-0.4, -0.6),
                radius: 1.1,
                colors: [Color(0xF2FFFFFF), Color(0x59FFFFFF), Color(0x73D6F0E2)],
                stops: [0, .45, 1],
              ),
              child: const Center(child: Icon(Icons.chevron_left_rounded, size: 26, color: HColors.ink)),
            ),
          ),
        ),
      );
}

/// Hifdth, a headline and a supporting line.
class AuthHero extends StatelessWidget {
  const AuthHero({super.key, required this.title, required this.subtitle, this.size = 72, this.speaking = false});
  final String title;
  final String subtitle;
  final double size;
  final bool speaking;

  @override
  Widget build(BuildContext context) => Column(children: [
        HifdthAvatar(mood: HifdthMood.happy, size: size, speaking: speaking),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(title,
              key: ValueKey(title),
              textAlign: TextAlign.center,
              style: HText.inter(size: 26, weight: FontWeight.w700, letterSpacing: -0.5)),
        ),
        const SizedBox(height: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: Text(subtitle,
              key: ValueKey(subtitle),
              textAlign: TextAlign.center,
              style: HText.inter(size: 15, color: HColors.ink2, height: 1.45)),
        ),
      ]);
}

/// The Google "G", in its brand colours.
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.string(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">'
        '<path fill="#FFC107" d="M43.611 20.083H42V20H24v8h11.303c-1.649 4.657-6.08 8-11.303 8-6.627 0-12-5.373-12-12s5.373-12 12-12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 12.955 4 4 12.955 4 24s8.955 20 20 20 20-8.955 20-20c0-1.341-.138-2.65-.389-3.917z"/>'
        '<path fill="#FF3D00" d="M6.306 14.691l6.571 4.819C14.655 15.108 18.961 12 24 12c3.059 0 5.842 1.154 7.961 3.039l5.657-5.657C34.046 6.053 29.268 4 24 4 16.318 4 9.656 8.337 6.306 14.691z"/>'
        '<path fill="#4CAF50" d="M24 44c5.166 0 9.86-1.977 13.409-5.192l-6.19-5.238A11.91 11.91 0 0 1 24 36c-5.202 0-9.619-3.317-11.283-7.946l-6.522 5.025C9.505 39.556 16.227 44 24 44z"/>'
        '<path fill="#1976D2" d="M43.611 20.083H42V20H24v8h11.303a12.04 12.04 0 0 1-4.087 5.571l.003-.002 6.19 5.238C36.971 39.205 44 34 44 24c0-1.341-.138-2.65-.389-3.917z"/>'
        '</svg>',
        width: size,
        height: size,
      );
}

/// A full-width button that shrinks slightly while pressed.
class PressableButton extends StatefulWidget {
  const PressableButton({
    super.key,
    required this.onPressed,
    required this.child,
    required this.background,
    this.border,
    this.gradient,
    this.shadows = const [],
    this.height = PressableButton.fullHeight,
    this.semanticLabel,
    this.disabledBackground,
  });

  /// Full-width buttons, and compact ones (two side by side, or inside a card).
  static const fullHeight = 52.0;
  static const compactHeight = 48.0;

  final VoidCallback? onPressed;
  final Widget child;
  final Color background;
  final Color? border;
  final Gradient? gradient;
  final List<BoxShadow> shadows;
  final double height;
  final String? semanticLabel;

  /// A flat fill while disabled, in place of dimming the whole button.
  final Color? disabledBackground;

  @override
  State<PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<PressableButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _down ? 0.97 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: enabled || widget.disabledBackground != null ? 1 : 0.6,
            duration: const Duration(milliseconds: 150),
            // Between enabled and disabled the fill cross-fades rather than snapping.
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: widget.height,
              decoration: !enabled && widget.disabledBackground != null
                  ? BoxDecoration(
                      color: widget.disabledBackground,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [for (final s in widget.shadows) s.copyWith(color: s.color.withValues(alpha: 0))],
                    )
                  : BoxDecoration(
                      color: widget.gradient == null ? widget.background : null,
                      gradient: widget.gradient,
                      borderRadius: BorderRadius.circular(18),
                      border: widget.border == null ? null : Border.all(color: widget.border!),
                      boxShadow: widget.shadows,
                    ),
              alignment: Alignment.center,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class AppleButton extends StatelessWidget {
  const AppleButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => PressableButton(
        onPressed: onPressed,
        background: Colors.black,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.apple, color: Colors.white, size: 22),
          const SizedBox(width: 10),
          Flexible(
            child: Text(label, overflow: TextOverflow.ellipsis, style: HText.button(color: Colors.white)),
          ),
        ]),
      );
}

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => PressableButton(
        onPressed: onPressed,
        background: Colors.white,
        border: const Color(0xFFE1E6EC),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const GoogleLogo(size: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Text(label, overflow: TextOverflow.ellipsis, style: HText.button()),
          ),
        ]),
      );
}

/// The green primary action, with a spinner while [loading].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
      {super.key, required this.label, required this.onPressed, this.loading = false, this.compact = false});
  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  /// Smaller, for two buttons side by side or a button inside a card.
  final bool compact;

  @override
  Widget build(BuildContext context) => PressableButton(
        onPressed: loading ? null : onPressed,
        height: compact ? PressableButton.compactHeight : PressableButton.fullHeight,
        background: HColors.accent,
        semanticLabel: loading ? context.l10n.working(label) : null,
        // Disabled reads as gray, not as a paler green that still looks tappable.
        disabledBackground: loading ? null : HColors.track,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2CC774), Color(0xFF169A55)],
        ),
        shadows: const [BoxShadow(color: Color(0x4022B567), offset: Offset(0, 10), blurRadius: 24)],
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: loading
              ? const SizedBox.square(
                  key: ValueKey('spin'),
                  dimension: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                )
              : AnimatedDefaultTextStyle(
                  key: ValueKey(label),
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  style: HText.button(color: onPressed == null ? HColors.inkMuted : Colors.white, compact: compact),
                  child: Text(label),
                ),
        ),
      );
}

/// "or with email" divider.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Row(children: [
        const Expanded(child: Divider(color: Color(0xFFDCE2E8), height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(text, style: HText.inter(size: 13, color: HColors.inkMuted)),
        ),
        const Expanded(child: Divider(color: Color(0xFFDCE2E8), height: 1)),
      ]);
}

/// A labelled text field with a leading icon, 16 px text, a visible focus ring,
/// an optional show/hide toggle for passwords, and an error or hint below.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    required this.controller,
    this.focusNode,
    this.password = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.onChanged,
    this.error,
    this.helper,
    this.trailingLabel,
    this.capitalization = TextCapitalization.none,
    this.autofocus = false,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool password;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? error;
  final String? helper;
  final Widget? trailingLabel;
  final TextCapitalization capitalization;
  final bool autofocus;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final error = widget.error;
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c, width: w),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(widget.label, style: HText.inter(size: 14, weight: FontWeight.w600)),
        const Spacer(),
        if (widget.trailingLabel != null) widget.trailingLabel!,
      ]),
      const SizedBox(height: 8),
      TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        obscureText: widget.password && _obscured,
        enableSuggestions: !widget.password,
        autocorrect: false,
        keyboardType: widget.keyboardType,
        autofillHints: widget.autofillHints,
        textInputAction: widget.textInputAction,
        textCapitalization: widget.capitalization,
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
        style: HText.inter(size: 16),
        cursorColor: HColors.accentDeep,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: HText.inter(size: 16, color: const Color(0xFF9AA3AD)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 17),
          prefixIcon: Icon(widget.icon, size: 20, color: error != null ? const Color(0xFFD14343) : HColors.inkMuted),
          suffixIcon: widget.password
              ? IconButton(
                  tooltip: _obscured ? context.l10n.showPassword : context.l10n.hidePassword,
                  onPressed: () => setState(() => _obscured = !_obscured),
                  icon: Icon(_obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      size: 21, color: HColors.ink2),
                )
              : null,
          enabledBorder: border(error != null ? const Color(0xFFE59A9A) : const Color(0xFFE1E6EC)),
          focusedBorder: border(error != null ? const Color(0xFFD14343) : HColors.accent, 1.6),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        alignment: Alignment.topLeft,
        child: error != null || widget.helper != null
            ? Padding(
                padding: const EdgeInsets.only(top: 6, left: 4),
                child: Row(children: [
                  if (error != null) ...[
                    const Icon(Icons.error_outline_rounded, size: 15, color: Color(0xFFD14343)),
                    const SizedBox(width: 5),
                  ],
                  Flexible(
                    child: Text(error ?? widget.helper!,
                        style:
                            HText.inter(size: 13, color: error != null ? const Color(0xFFC03535) : HColors.inkMuted)),
                  ),
                ]),
              )
            : const SizedBox(width: double.infinity),
      ),
    ]);
  }
}

/// Live password rules, each ticking green as it's met.
class PasswordRules extends StatelessWidget {
  const PasswordRules({super.key, required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    Widget rule(String text, bool ok) => Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              child: Icon(ok ? Icons.check_circle_rounded : Icons.circle_outlined,
                  key: ValueKey(ok), size: 15, color: ok ? HColors.accent : const Color(0xFFB4BCC5)),
            ),
            const SizedBox(width: 5),
            Text(text, style: HText.inter(size: 13, color: ok ? HColors.accentDeep : HColors.inkMuted)),
          ]),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Wrap(runSpacing: 4, children: [
        rule(context.l10n.rule8chars, password.length >= 8),
        rule(context.l10n.ruleNumber, password.contains(RegExp(r'\d'))),
      ]),
    );
  }
}

class TermsFooter extends StatelessWidget {
  const TermsFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final link = HText.inter(size: 13, weight: FontWeight.w600, color: HColors.accentDeep);
    // The sentence comes whole from the translation; the two links are cut out
    // of it by their markers, so each language keeps its own word order.
    final l = context.l10n;
    final parts = l.termsSentence('\u0001', '\u0002').split(RegExp('(?=[\u0001\u0002])|(?<=[\u0001\u0002])'));
    return Text.rich(
      TextSpan(children: [
        for (final p in parts)
          switch (p) {
            '\u0001' => TextSpan(text: l.terms, style: link),
            '\u0002' => TextSpan(text: l.privacyPolicy, style: link),
            _ => TextSpan(text: p),
          },
      ]),
      textAlign: TextAlign.center,
      style: HText.inter(size: 13, color: HColors.inkMuted, height: 1.5),
    );
  }
}

String? validateEmail(AppLocalizations l, String v) {
  final s = v.trim();
  if (s.isEmpty) return l.enterEmail;
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(s)) return l.emailIncomplete;
  return null;
}
