import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/auth_api.dart';
import '../data/learned_store.dart';
import '../data/locale_store.dart';
import '../data/plan_store.dart';
import '../data/surahs.dart' show surahAyahCounts;
import '../l10n/l10n.dart';
import '../player/player_controller.dart';
import '../theme/tokens.dart';
import '../widgets/glass.dart';
import '../widgets/method_explainer.dart' show SectionLabel;
import 'account_screen.dart';
import 'auth_screen.dart';

/// The version shown in About; keep in step with `version:` in pubspec.yaml.
const appVersion = '1.0.0 (1)';

/// The Settings tab: Account, Language, Playback and About, as grouped white cards.
///
/// Language applies at once (the whole app redraws in the new language).
/// Playback edits the same repeat count and auto-next the player uses.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.locale,
    required this.player,
    required this.bottomInset,
    this.auth,
    this.learned,
    this.plans,
  });

  final LocaleStore locale;

  /// For the profile card's numbers; null in tests that don't need them.
  final LearnedStore? learned;
  final PlanStore? plans;

  /// Signed-in state; null in tests without an account connection.
  final AuthApi? auth;
  final PlayerController player;

  /// Space for the floating nav.
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final top = MediaQuery.paddingOf(context).top + 9;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, top < 56 ? 56 : top, 16, bottomInset + 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
          header: true,
          child: Text(l.tabSettings, style: HText.inter(size: 28, weight: FontWeight.w700, letterSpacing: -0.5)),
        ),
        if (auth case final auth?) ...[
          const SizedBox(height: 20),
          ListenableBuilder(
            listenable: Listenable.merge([auth, if (learned != null) learned, if (plans != null) plans]),
            builder: (context, _) => _ProfileCard(auth: auth, learned: learned, plans: plans),
          ),
        ],
        const SizedBox(height: 24),
        SectionLabel(l.languageCaps),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: locale,
          builder: (context, _) => _Group(children: [
            for (final lang in AppLanguage.values)
              _LanguageRow(
                language: lang,
                selected: locale.language == lang,
                onTap: () {
                  HapticFeedback.selectionClick();
                  locale.set(lang);
                },
              ),
          ]),
        ),
        const SizedBox(height: 24),
        SectionLabel(l.playbackCaps),
        const SizedBox(height: 8),
        ListenableBuilder(
          listenable: player,
          builder: (context, _) => _Group(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(l.repeatEachAyah, style: HText.inter(size: 15, weight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(l.repeatEachAyahNote, style: HText.inter(size: 13, color: HColors.ink2)),
                const SizedBox(height: 12),
                Row(children: [
                  for (final (i, r) in repeatOptions.indexed) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: _RepeatChip(
                        value: r,
                        selected: player.repeat == r,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          player.setRepeat(r);
                        },
                      ),
                    ),
                  ],
                ]),
              ]),
            ),
            _SwitchRow(
              title: l.thenNextAyah,
              subtitle: l.thenNextAyahNote,
              value: player.autoNext,
              onChanged: player.setAutoNext,
            ),
          ]),
        ),
        const SizedBox(height: 24),
        SectionLabel(l.aboutCaps),
        const SizedBox(height: 8),
        _Group(children: [
          _InfoRow(icon: Icons.info_outline_rounded, title: l.version, value: appVersion),
          _InfoRow(icon: Icons.record_voice_over_outlined, title: l.reciter, value: reciterName),
          _InfoRow(icon: Icons.shield_outlined, title: l.privacyPolicyTitle, soon: true),
          _InfoRow(icon: Icons.mail_outline_rounded, title: l.contactUs, soon: true),
        ]),
        const SizedBox(height: 16),
        Center(
          child: Text(l.madeWithCare, style: HText.inter(size: 12, color: HColors.inkMuted)),
        ),
      ]),
    );
  }
}

/// A white 26 px card whose rows are split by hairlines inset past the icon column.
class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: HColors.surface,
          borderRadius: BorderRadius.circular(HRadii.panel),
          boxShadow: const [
            BoxShadow(color: Color(0x0A14281E), offset: Offset(0, 1), blurRadius: 2),
            BoxShadow(color: Color(0x0F14281E), offset: Offset(0, 8), blurRadius: 20),
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (final (i, c) in children.indexed) ...[
            if (i > 0) const Padding(padding: EdgeInsets.only(left: 14), child: Divider(height: 1, color: HColors.divider)),
            c,
          ],
        ]),
      );
}

/// The profile card that heads Settings: a soft sky banner with an Edit (or
/// Sign in) glass pill, the initial in a ringed 60 px circle overlapping it, a
/// segmented bar of how much of the Quran is memorized, the name and email,
/// and three numbers: surahs learned, evening lessons learned, best streak.
/// Tapping it opens the account page, or sign-in when signed out.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.auth, this.learned, this.plans});

  final AuthApi auth;
  final LearnedStore? learned;
  final PlanStore? plans;

  static const _banner = 78.0, _avatar = 60.0;
  static final _totalAyahs = surahAyahCounts.fold(0, (a, b) => a + b);

  void _open(BuildContext context) => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => auth.signedIn ? AccountScreen(api: auth) : AuthScreen(api: auth),
      ));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final user = auth.signedIn ? auth.user : null;
    final name = user == null ? l.signIn : (user.displayName.isNotEmpty ? user.displayName : (user.email ?? l.yourAccount));
    final sub = user == null ? l.signInSubtitle : (user.displayName.isNotEmpty ? user.email : null);
    final initial = user == null || name.isEmpty ? null : name.characters.first.toUpperCase();
    final ayahs = learned?.ayahsLearned ?? 0;
    final share = ayahs / _totalAyahs;

    Widget stat(int value, String label) => Expanded(
          child: Semantics(
            label: '$value $label',
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(children: [
                Text('$value', style: HText.inter(size: 16, weight: FontWeight.w700, tabular: true)),
                const SizedBox(height: 1),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HText.inter(size: 12, color: HColors.ink2)),
              ]),
            ),
          ),
        );
    const line = ColoredBox(color: HColors.divider, child: SizedBox(width: 1, height: 40));

    return Semantics(
      button: true,
      label: [name, if (sub != null) sub].join(', '),
      child: GestureDetector(
        onTap: () => _open(context),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: HColors.surface,
            borderRadius: BorderRadius.circular(HRadii.panel),
            boxShadow: const [
              BoxShadow(color: Color(0x0A14281E), offset: Offset(0, 1), blurRadius: 2),
              BoxShadow(color: Color(0x1414281E), offset: Offset(0, 14), blurRadius: 30),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Banner, with the avatar hanging over its bottom edge.
            SizedBox(
              height: _banner + 8 + _avatar / 2,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned(
                  left: 8,
                  right: 8,
                  top: 8,
                  height: _banner,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(HRadii.panel - 8),
                    child: const CustomPaint(painter: _SkyPainter()),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: _GlassPill(
                    label: user == null ? l.signIn : l.editProfile,
                    icon: user == null ? Icons.arrow_forward_rounded : Icons.edit_rounded,
                    onTap: () => _open(context),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 8 + _banner - _avatar / 2,
                  child: Container(
                    width: _avatar,
                    height: _avatar,
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: HColors.surface,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Color(0x1A14281E), offset: Offset(0, 4), blurRadius: 12)],
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFDDF5E8), Color(0xFFB8EBCF)],
                        ),
                      ),
                      child: initial == null
                          ? const Icon(Icons.person_outline_rounded, size: 26, color: HColors.accentDeep)
                          : Text(initial,
                              style: HText.inter(size: 22, weight: FontWeight.w700, color: HColors.accentDeep)),
                    ),
                  ),
                ),
                // How much of the Quran is memorized, beside the avatar.
                Positioned(
                  left: 16 + _avatar + 12,
                  right: 16,
                  bottom: 4,
                  child: Semantics(
                    label: l.ayahsOfQuran(ayahs, _totalAyahs),
                    excludeSemantics: true,
                    child: Row(children: [
                      Text(l.quranWord, style: HText.inter(size: 12, color: HColors.inkMuted)),
                      const SizedBox(width: 8),
                      Expanded(child: _Ticks(value: share)),
                    ]),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HText.inter(size: 18, weight: FontWeight.w700, letterSpacing: -0.2)),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(sub, style: HText.inter(size: 13, height: 1.35, color: HColors.ink2)),
                ],
              ]),
            ),
            const ColoredBox(color: HColors.divider, child: SizedBox(height: 1)),
            Row(children: [
              stat(learned?.surahsLearned ?? 0, l.statSurahs),
              line,
              stat(plans?.lessonsLearned ?? 0, l.statLessons),
              line,
              stat(plans?.longestStreak(DateTime.now()) ?? 0, l.statBestStreak),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// A frosted white pill on the banner ("Edit ✎"), like the reference's Follow +.
class _GlassPill extends StatelessWidget {
  const _GlassPill({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: SizedBox(
            height: 32,
            child: LiquidGlass(
              radius: 16,
              blur: 16,
              borderColor: const Color(0xD9FFFFFF),
              shadows: const [BoxShadow(color: Color(0x1F14462D), offset: Offset(0, 6), blurRadius: 14)],
              fill: const LinearGradient(colors: [Color(0xF2FFFFFF), Color(0xD9F4F8FC)]),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 11),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(label, style: HText.inter(size: 13, weight: FontWeight.w600)),
                  const SizedBox(width: 5),
                  Icon(icon, size: 14, color: HColors.ink),
                ]),
              ),
            ),
          ),
        ),
      );
}

/// 30 thin ticks; the filled share runs lilac → indigo → green, the rest is track.
class _Ticks extends StatelessWidget {
  const _Ticks({required this.value});
  final double value;

  static const _n = 30;
  static const _hues = [Color(0xFFB79CF2), Color(0xFF7C8CF0), Color(0xFF4FB3E8), Color(0xFF3CC48A), Color(0xFF22B567)];

  @override
  Widget build(BuildContext context) {
    // Anything learned shows at least one tick.
    final filled = value <= 0 ? 0 : (value * _n).ceil().clamp(1, _n);
    return SizedBox(
      height: 9,
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (var i = 0; i < _n; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: i < filled ? _hue(i / (_n - 1)) : HColors.track,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  static Color _hue(double t) {
    final x = t * (_hues.length - 1);
    final i = x.floor().clamp(0, _hues.length - 2);
    return Color.lerp(_hues[i], _hues[i + 1], x - i)!;
  }
}

/// A pale sky with a few soft clouds, drawn so it stays crisp at any size.
class _SkyPainter extends CustomPainter {
  const _SkyPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB9CFE8), Color(0xFFD3E2F2), Color(0xFFE4EEF7)],
        ).createShader(rect),
    );
    final cloud = Paint()
      ..color = const Color(0xD9FFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    void puff(double x, double y, double rx, double ry) =>
        canvas.drawOval(Rect.fromCenter(center: Offset(size.width * x, size.height * y), width: rx, height: ry), cloud);
    puff(0.42, 0.42, 120, 46);
    puff(0.55, 0.30, 90, 50);
    puff(0.30, 0.58, 100, 34);
    puff(0.64, 0.66, 130, 36);
    puff(0.92, 0.85, 70, 30);
  }

  @override
  bool shouldRepaint(_SkyPainter old) => false;
}

/// A language by its own name and script ("Oʻzbekcha (lotin)"), and a check
/// that pops in on the chosen one.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.language, required this.selected, required this.onTap});

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: language.nativeName,
      excludeSemantics: true,
      child: _PressTint(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Expanded(
                child: Text(language.nativeName,
                    style: HText.inter(size: 15, weight: selected ? FontWeight.w600 : FontWeight.w500)),
              ),
              // Pops in from 0.6, never from nothing; fades out quicker than it arrives.
              AnimatedScale(
                scale: selected ? 1 : 0.6,
                duration: reduce ? Duration.zero : Duration(milliseconds: selected ? 220 : 120),
                curve: selected ? const Cubic(0.34, 1.4, 0.64, 1) : Curves.easeIn,
                child: AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: reduce ? Duration.zero : Duration(milliseconds: selected ? 160 : 120),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(color: HColors.accent, shape: BoxShape.circle),
                    child: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// One repeat option: "1×" … "10×" or "∞", mint when chosen.
class _RepeatChip extends StatelessWidget {
  const _RepeatChip({required this.value, required this.selected, required this.onTap});

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: value == 0 ? l.repeatForever : l.repeatTimes(value),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          height: 40,
          decoration: BoxDecoration(
            color: selected ? HColors.mintWash : HColors.bgTop,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? HColors.mintRing : HColors.bgTop),
          ),
          alignment: Alignment.center,
          child: Text(value == 0 ? '∞' : '$value×',
              style: HText.inter(
                  size: 14,
                  weight: selected ? FontWeight.w700 : FontWeight.w500,
                  tabular: true,
                  color: selected ? HColors.accentDeep : HColors.ink2)),
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.subtitle, required this.value, required this.onChanged});

  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: _PressTint(
          onTap: () => onChanged(!value),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: HText.inter(size: 15, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: HText.inter(size: 13, color: HColors.ink2)),
                ]),
              ),
              const SizedBox(width: 10),
              Switch.adaptive(value: value, onChanged: onChanged, activeTrackColor: HColors.playerSwitchOn),
            ]),
          ),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, this.value, this.soon = false});

  final IconData icon;
  final String title;
  final String? value;

  /// Not available yet: a muted "Soon" tag instead of a value.
  final bool soon;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: HColors.mintWash, borderRadius: BorderRadius.circular(9)),
                child: Icon(icon, size: 17, color: HColors.accentDeep),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: HText.inter(size: 15, weight: FontWeight.w500))),
              if (soon)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: HColors.bgTop, borderRadius: BorderRadius.circular(999)),
                  child: Text(context.l10n.soon,
                      style: HText.inter(size: 12, weight: FontWeight.w600, color: HColors.inkMuted)),
                )
              else if (value != null)
                Text(value!, style: HText.inter(size: 14, color: HColors.ink2, tabular: true)),
            ]),
          ),
        ),
      );
}

/// A row that tints gray while pressed: instant on, 150 ms off, so taps feel answered.
class _PressTint extends StatefulWidget {
  const _PressTint({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressTint> createState() => _PressTintState();
}

class _PressTintState extends State<_PressTint> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: _down || MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 150),
          color: _down ? HColors.bgTop : HColors.surface,
          child: widget.child,
        ),
      );
}
