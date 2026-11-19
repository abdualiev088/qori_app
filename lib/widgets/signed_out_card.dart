import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'auth_widgets.dart';
import 'hifdth_card.dart';
import 'hifdth_mood.dart';

/// Home's Quran progress card for someone who isn't signed in: a faded,
/// locked grid, the guide asking them to sign in, and the two buttons.
/// Progress belongs to an account, so nothing here can be changed.
class SignedOutCard extends StatelessWidget {
  const SignedOutCard({super.key, required this.onSignIn, required this.onRegister, this.hintKey});

  final VoidCallback onSignIn;
  final VoidCallback onRegister;

  /// Key for the hint line at the bottom, so Home can line Hifdth up with it.
  final Key? hintKey;

  /// The guide: a man holding the Quran, cut out of its background.
  static const guideAsset = 'assets/images/hifz_guide.png';

  static const bubbleText = 'Sign in to save your Quran progress';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: HColors.surface, borderRadius: BorderRadius.circular(HRadii.list)),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text('QURAN PROGRESS',
              style: HText.inter(size: 12, weight: FontWeight.w600, color: HColors.ink2, letterSpacing: 0.8)),
          const Spacer(),
          Text.rich(TextSpan(children: [
            TextSpan(text: '0', style: HText.inter(size: 16, weight: FontWeight.w700, tabular: true)),
            TextSpan(text: '/114', style: HText.inter(size: 16, color: HColors.inkMuted)),
          ])),
        ]),
        const SizedBox(height: 14),
        // Tapping anywhere in the art asks to sign in, like the buttons.
        Semantics(
          button: true,
          label: bubbleText,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSignIn,
            child: SizedBox(
              height: 300,
              child: LayoutBuilder(
                builder: (context, box) => Stack(clipBehavior: Clip.none, children: [
                  const Positioned.fill(child: _FadedGrid()),
                  const Positioned(left: 22, bottom: 30, child: _ArabicLetters()),
                  // Bigger, standing right on the Register button, a little left of its centre.
                  Positioned(
                    right: box.maxWidth * -0.03,
                    bottom: -14, // the gap down to the buttons
                    width: box.maxWidth * 0.66,
                    height: 330,
                    child: const _Guide(),
                  ),
                  const Positioned(left: 0, top: 78, child: _Bubble(text: bubbleText)),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: PrimaryButton(label: 'Sign in', onPressed: onSignIn, compact: true)),
          const SizedBox(width: 12),
          Expanded(
            child: PressableButton(
              onPressed: onRegister,
              height: PressableButton.compactHeight,
              background: Colors.white,
              border: const Color(0xFFDCE2E8),
              child: Text('Register', style: HText.button(compact: true)),
            ),
          ),
        ]),
        const SizedBox(height: 18),
        Text('Sign in, then tap a surah to mark its ayahs.',
            key: hintKey, style: HText.inter(size: 13, color: HColors.ink2)),
      ]),
    );
  }
}

/// The first rows of the surah grid, fading away toward the bottom right.
class _FadedGrid extends StatelessWidget {
  const _FadedGrid();

  @override
  Widget build(BuildContext context) => ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // Faint from the start and gone well before the guide, so the numbers don't compete with it.
          colors: [Color(0x8CFFFFFF), Color(0x33FFFFFF), Color(0x00FFFFFF)],
          stops: [0, .4, .7],
        ).createShader(rect),
        child: GridView.count(
          crossAxisCount: 10,
          mainAxisSpacing: 7,
          crossAxisSpacing: 7,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            for (var n = 1; n <= 70; n++)
              DecoratedBox(
                decoration: BoxDecoration(color: const Color(0xFFEFF2F6), borderRadius: BorderRadius.circular(8)),
                child: Center(
                  child: Text('$n', style: HText.inter(size: 12, weight: FontWeight.w500, color: HColors.inkMuted)),
                ),
              ),
          ],
        ),
      );
}

/// A few faint Arabic letters drifting behind the guide.
class _ArabicLetters extends StatelessWidget {
  const _ArabicLetters();

  @override
  Widget build(BuildContext context) {
    TextStyle letter(double size) => HText.arabic(size: size, color: const Color(0xFFC9D1DA));
    return SizedBox(
      width: 150,
      height: 110,
      child: Stack(children: [
        Positioned(left: 30, top: 0, child: Text('ح', style: letter(46))),
        Positioned(left: 96, top: 18, child: Text('ي', style: letter(40))),
        Positioned(left: 0, top: 54, child: Text('ذ', style: letter(30))),
        Positioned(left: 70, top: 66, child: Text('ف', style: letter(30))),
      ]),
    );
  }
}

/// The guide's picture (Hifdth stands in if it ever fails to load).
class _Guide extends StatelessWidget {
  const _Guide();

  @override
  Widget build(BuildContext context) => Image.asset(
        SignedOutCard.guideAsset,
        fit: BoxFit.contain,
        alignment: Alignment.bottomCenter,
        errorBuilder: (context, error, stack) =>
            const Align(alignment: Alignment(0.2, 0.1), child: HifdthAvatar(mood: HifdthMood.happy, size: 130)),
      );
}

/// The blue speech bubble, its tail toward the guide.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 170),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4A9AF2), Color(0xFF2F80E8)],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(14),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(4),
          ),
          boxShadow: [BoxShadow(color: Color(0x332A6FD6), offset: Offset(0, 6), blurRadius: 16)],
        ),
        child: Text(text, style: HText.inter(size: 13, weight: FontWeight.w600, color: Colors.white, height: 1.3)),
      );
}
