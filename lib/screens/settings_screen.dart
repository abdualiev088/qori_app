import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/locale_store.dart';
import '../l10n/l10n.dart';
import '../player/player_controller.dart';
import '../theme/tokens.dart';
import '../widgets/method_explainer.dart' show SectionLabel;

/// The version shown in About; keep in step with `version:` in pubspec.yaml.
const appVersion = '1.0.0 (1)';

/// The Settings tab: Language, Playback and About, as grouped white cards.
///
/// Language applies at once (the whole app redraws in the new language).
/// Playback edits the same repeat count and auto-next the player uses.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.locale, required this.player, required this.bottomInset});

  final LocaleStore locale;
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
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(l.languageNote, style: HText.inter(size: 12, height: 1.4, color: HColors.inkMuted)),
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

/// A language in its own name and script, with its name in the current language
/// under it; a check that pops in on the chosen one.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.language, required this.selected, required this.onTap});

  final AppLanguage language;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final translated = switch (language) {
      AppLanguage.en => l.langEnglish,
      AppLanguage.ru => l.langRussian,
      AppLanguage.uzLatn => l.langUzbekLatin,
      AppLanguage.uzCyrl => l.langUzbekCyrillic,
    };
    return Semantics(
      button: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: '${language.nativeName}, $translated',
      excludeSemantics: true,
      child: _PressTint(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(language.nativeName,
                      style: HText.inter(size: 15, weight: selected ? FontWeight.w600 : FontWeight.w500)),
                  if (translated != language.nativeName)
                    Text(translated, style: HText.inter(size: 12, color: HColors.inkMuted)),
                ]),
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
