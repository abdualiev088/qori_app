import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/plan.dart';
import '../data/plan_store.dart';
import '../data/surah_index.dart';
import '../theme/tokens.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/method_explainer.dart';
import '../widgets/mushaf_icon.dart';
import '../l10n/plan_text.dart';
import '../l10n/l10n.dart';

/// The My Method tab. The first visit explains "33 repetitions"; every later
/// visit opens on Set your plan, with the explanation folded behind "How it works".
class MethodScreen extends StatefulWidget {
  const MethodScreen({super.key, required this.store, required this.bottomInset, required this.onSaved});

  final PlanStore store;

  /// Space for the floating nav.
  final double bottomInset;

  /// A plan was created or updated; [message] is the toast to show.
  final void Function(String message) onSaved;

  @override
  State<MethodScreen> createState() => _MethodScreenState();
}

class _MethodScreenState extends State<MethodScreen> {
  PlanStore get _store => widget.store;

  /// Showing the full explainer (first visit only).
  late bool _explainer = !_store.howSeen;

  final _scroll = ScrollController();

  // The plan being edited.
  late ReadingOrder _order;
  late Pos _start, _end;
  late int _lines;
  int? _rest;

  /// The saved plan the draft was last read from.
  Plan? _from;

  @override
  void initState() {
    super.initState();
    _readDraft();
    _store.addListener(_storeChanged);
    if (_explainer) WidgetsBinding.instance.addPostFrameCallback((_) => _store.markHowSeen());
  }

  @override
  void dispose() {
    _store.removeListener(_storeChanged);
    _scroll.dispose();
    super.dispose();
  }

  /// A plan saved here or elsewhere replaces the draft; ticking a task doesn't.
  void _storeChanged() {
    if (!identical(_store.plan, _from)) setState(_readDraft);
  }

  void _readDraft() {
    final p = _from = _store.plan;
    _order = p?.order ?? ReadingOrder.fromEnd;
    _start = p?.start ?? const Pos(114, 1);
    _end = p?.end ?? const Pos(78, 40);
    _lines = p?.linesPerDay ?? 5;
    _rest = p == null ? DateTime.friday : p.restWeekday;
  }

  Plan get _draft => Plan(
        order: _order,
        start: _start,
        end: _end,
        linesPerDay: _lines,
        restWeekday: _rest,
        startDate: _store.plan?.startDate ?? DateTime.now(),
      );

  /// Nothing saved yet, or the draft differs from the saved plan. Changing a
  /// value and changing it back counts as no change.
  bool get _dirty {
    final p = _store.plan;
    return p == null ||
        p.order != _order ||
        p.start != _start ||
        p.end != _end ||
        p.linesPerDay != _lines ||
        p.restWeekday != _rest;
  }

  void _showForm() {
    setState(() => _explainer = false);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _setOrder(ReadingOrder o) {
    if (o == _order) return;
    setState(() {
      _order = o;
      final (s, e) = (_end.s, _start.s);
      _start = Pos(s, 1);
      _end = Pos(e, ayahsIn(e));
    });
  }

  Future<void> _pick(bool start) async {
    final s = await Navigator.of(context).push<int>(MaterialPageRoute(
      builder: (_) => _SurahPicker(
        title: start ? context.l10n.startSurah : context.l10n.endSurah,
        order: _order,
        selected: (start ? _start : _end).s,
      ),
    ));
    if (s == null || !mounted) return;
    setState(() => start ? _start = Pos(s, 1) : _end = Pos(s, ayahsIn(s)));
  }

  Future<void> _save() async {
    final p = _draft;
    if (!p.valid || !_dirty) return;
    final editing = _store.plan != null;
    await _store.save(p);
    widget.onSaved(editing ? context.l10n.planUpdated : context.l10n.planCreated(p.lessons.length));
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 9;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final editing = _store.plan != null;
    final draft = _draft;
    final ok = draft.valid;
    // Editing: enabled only while there's something new to save, so after a
    // save it greys out again until the next change.
    final button = _explainer
        ? PrimaryButton(label: editing ? context.l10n.editMyPlan : context.l10n.setUpMyPlan, onPressed: _showForm)
        : PrimaryButton(
            label: editing ? context.l10n.updateMyPlan : context.l10n.createMyPlan, onPressed: ok && _dirty ? _save : null);

    return Stack(children: [
      Positioned.fill(
        child: SingleChildScrollView(
          controller: _scroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
              16, top < 56 ? 56 : top, 16, widget.bottomInset + 12 + PressableButton.fullHeight + 24),
          // Explainer → form: the form rises 8 px as it fades in (260 ms); the
          // explainer just fades out, quicker (150 ms).
          child: AnimatedSwitcher(
            duration: reduce ? Duration.zero : const Duration(milliseconds: 260),
            reverseDuration: reduce ? Duration.zero : const Duration(milliseconds: 150),
            switchInCurve: const Cubic(0.32, 0.72, 0, 1),
            switchOutCurve: Curves.easeIn,
            layoutBuilder: (current, previous) =>
                Stack(alignment: Alignment.topCenter, children: [...previous, if (current != null) current]),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: AnimatedBuilder(
                animation: anim,
                builder: (context, c) => Transform.translate(
                  offset: Offset(0, child.key == const ValueKey('form') ? 8 * (1 - anim.value) : 0),
                  child: c,
                ),
                child: child,
              ),
            ),
            child: _explainer
                ? const _Explainer(key: ValueKey('explainer'))
                : KeyedSubtree(key: const ValueKey('form'), child: _form(draft, ok, editing)),
          ),
        ),
      ),
      // Pinned above the nav.
      Positioned(left: 16, right: 16, bottom: widget.bottomInset + 12, child: button),
    ]);
  }

  Widget _form(Plan draft, bool ok, bool editing) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final grow = reduce ? Duration.zero : const Duration(milliseconds: 220);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(editing ? context.l10n.yourPlanTitle : context.l10n.setYourPlan,
              style: HText.inter(size: 28, weight: FontWeight.w700, letterSpacing: -0.5)),
        ),
        const SizedBox(height: 4),
        Text(context.l10n.methodSubtitle(context.l10n.methodName),
            style: HText.inter(size: 14, color: HColors.ink2)),
        const SizedBox(height: 16),
        // Its own state, so editing the plan below never folds it or restarts the diagram.
        const _HowItWorks(),
        const SizedBox(height: 24),
        SectionLabel(context.l10n.whatToMemorizeCaps),
        const SizedBox(height: 8),
        _Group(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _Segmented<ReadingOrder>(
              value: _order,
              onChanged: _setOrder,
              options: [
                (ReadingOrder.fromBeginning, context.l10n.fromBeginning, context.l10n.fatihahFirst),
                (ReadingOrder.fromEnd, context.l10n.fromEnd, context.l10n.nasFirst),
              ],
            ),
            const SizedBox(height: 12),
            _Route(
              start: _start,
              end: _end,
              onPickStart: () => _pick(true),
              onPickEnd: () => _pick(false),
              onStartAyah: (a) => setState(() => _start = Pos(_start.s, a)),
              onEndAyah: (a) => setState(() => _end = Pos(_end.s, a)),
            ),
            // Grows in under the range it's about, instead of shoving the page at once.
            AnimatedSize(
              duration: grow,
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: ok
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _ErrorCard(_order == ReadingOrder.fromEnd
                          ? context.l10n.rangeErrorFromEnd
                          : context.l10n.rangeErrorFromBeginning),
                    ),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        SectionLabel(context.l10n.dailyPaceCaps),
        const SizedBox(height: 8),
        _Group(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              _Book(lines: _lines),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  _Stepper(
                    label: context.l10n.lines,
                    value: _lines,
                    min: 1,
                    max: Plan.maxLines,
                    onChanged: (v) => setState(() => _lines = v),
                  ),
                  const SizedBox(height: 6),
                  Text(paceText(context.l10n, _lines),
                      textAlign: TextAlign.center,
                      style: HText.inter(size: 13, weight: FontWeight.w500, color: HColors.ink2)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              for (final (i, (v, label)) in [
                (3, context.l10n.linesCount(3)),
                (5, context.l10n.linesCount(5)),
                (7, context.l10n.presetHalfPage),
                (15, context.l10n.pagesCount(1)),
              ]
                  .indexed) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(child: _Chip(label: label, selected: _lines == v, onTap: () => setState(() => _lines = v))),
              ],
            ]),
            const SizedBox(height: 10),
            Text(context.l10n.countedInMushaf,
                textAlign: TextAlign.center, style: HText.inter(size: 12, color: HColors.inkMuted)),
          ]),
        ),
        const SizedBox(height: 24),
        SectionLabel(context.l10n.restDayCaps),
        const SizedBox(height: 8),
        _Segmented<int?>(
          value: _rest,
          onChanged: (v) => setState(() => _rest = v),
          options: [
            (null, context.l10n.none, null),
            for (final d in const [DateTime.friday, DateTime.saturday, DateTime.sunday])
              (d, weekdayTitle(context.l10n, d), null),
          ],
        ),
        const SizedBox(height: 24),
        // The result of everything above; swaps to a hint while the range is impossible.
        AnimatedSize(
          duration: grow,
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: AnimatedSwitcher(
            duration: reduce ? Duration.zero : const Duration(milliseconds: 180),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            layoutBuilder: (current, previous) =>
                Stack(alignment: Alignment.topCenter, children: [...previous, if (current != null) current]),
            child: ok
                ? _Summary(key: const ValueKey('summary'), plan: draft)
                : const _SummaryHint(key: ValueKey('hint')),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- explainer

class _Explainer extends StatelessWidget {
  const _Explainer({super.key});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.methodOrigin, style: HText.inter(size: 13, weight: FontWeight.w500, color: HColors.ink2)),
          const SizedBox(height: 2),
          Semantics(
            header: true,
            child: Text(context.l10n.methodName, style: HText.inter(size: 28, weight: FontWeight.w700, letterSpacing: -0.5)),
          ),
          const SizedBox(height: 6),
          Text(context.l10n.methodSummary, style: HText.inter(size: 14, height: 1.5, color: HColors.ink2)),
          const SizedBox(height: 16),
          const _Group(child: MethodDetails(playing: true)),
        ],
      );
}

/// A white 26 px card for one group of settings, with a soft two-layer shadow.
/// Its controls use 14 px corners (26 − 12 padding).
class _Group extends StatelessWidget {
  const _Group({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: HColors.surface,
          borderRadius: BorderRadius.circular(HRadii.panel),
          boxShadow: const [
            BoxShadow(color: Color(0x0A14281E), offset: Offset(0, 1), blurRadius: 2),
            BoxShadow(color: Color(0x0F14281E), offset: Offset(0, 8), blurRadius: 20),
          ],
        ),
        child: child,
      );
}

/// A card that unfolds the diagram (playing), At a glance and Tips.
class _HowItWorks extends StatefulWidget {
  const _HowItWorks();

  @override
  State<_HowItWorks> createState() => _HowItWorksState();
}

class _HowItWorksState extends State<_HowItWorks> with SingleTickerProviderStateMixin {
  bool _open = false;

  /// Unfolds in 300 ms, folds back quicker (200 ms); the content stays while it folds, clipped.
  late final _fold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
    reverseDuration: const Duration(milliseconds: 200),
  );
  late final _size = CurvedAnimation(parent: _fold, curve: const Cubic(0.32, 0.72, 0, 1), reverseCurve: Curves.easeIn);

  /// The content fades in once the card has started opening, and is gone in
  /// the first half of the fold so it never shows squashed.
  late final _fade = CurvedAnimation(
      parent: _fold,
      curve: const Interval(0.25, 1, curve: Curves.easeOut),
      reverseCurve: const Interval(0.5, 1, curve: Curves.easeIn));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    _fold
      ..duration = reduce ? Duration.zero : const Duration(milliseconds: 300)
      ..reverseDuration = reduce ? Duration.zero : const Duration(milliseconds: 200);
  }

  @override
  void dispose() {
    _size.dispose();
    _fade.dispose();
    _fold.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    setState(() => _open = !_open);
    _open ? _fold.forward() : _fold.reverse();
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(HRadii.panel));
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(color: Color(0x143B8EF0), offset: Offset(0, 1), blurRadius: 2),
          BoxShadow(color: Color(0x243B8EF0), offset: Offset(0, 10), blurRadius: 24),
        ],
      ),
      // The hairline sits on top of everything, so the clip never cuts it at the corners.
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: ColoredBox(
            color: HColors.surface,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Semantics(
                button: true,
                expanded: _open,
                label: context.l10n.howItWorksLabel(context.l10n.methodName, Method33.stepCount),
                excludeSemantics: true,
                child: _Pressable(
                  onTap: _toggle,
                  // Blue behind the icon, fading to white across the card.
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 76),
                    padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF5FA6F7), Color(0xFFBFDDFF), Color(0xFFFFFFFF)],
                        stops: [0, .5, 1],
                      ),
                    ),
                    child: Row(children: [
                      const MushafPlayIcon(size: 52),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(context.l10n.howItWorks,
                              style: HText.inter(size: 16, weight: FontWeight.w600, color: const Color(0xFF0E2A52))),
                          const SizedBox(height: 2),
                          Text(context.l10n.howItWorksSub(Method33.stepCount),
                              style: HText.inter(size: 13, color: const Color(0xFF3D5A80))),
                        ]),
                      ),
                      // Turns with the panel, on the same clock.
                      RotationTransition(
                        turns: Tween(begin: 0.0, end: 0.5).animate(_size),
                        child: const Icon(Icons.keyboard_arrow_down_rounded, size: 24, color: Color(0xFF3D5A80)),
                      ),
                    ]),
                  ),
                ),
              ),
              ClipRect(
                child: SizeTransition(
                  sizeFactor: _size,
                  alignment: Alignment.topCenter,
                  child: FadeTransition(
                    opacity: _fade,
                    child: ExcludeSemantics(
                      excluding: !_open,
                      child: IgnorePointer(
                        ignoring: !_open,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                          child: MethodDetails(playing: _open, heading: false),
                        ),
                      ),
                    ),
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

// ---------------------------------------------------------------- form controls

/// Two to four options on a gray track, with a white thumb that slides under
/// the chosen one. Each option is a title and an optional line under it.
class _Segmented<T> extends StatelessWidget {
  const _Segmented({required this.value, required this.options, required this.onChanged});

  final T value;
  final List<(T, String, String?)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final n = options.length;
    final i = options.indexWhere((o) => o.$1 == value);
    Widget option((T, String, String?) o) {
      final (v, title, sub) = o;
      final on = v == value;
      return Expanded(
        child: Semantics(
          inMutuallyExclusiveGroup: true,
          checked: on,
          button: true,
          label: sub == null ? title : '$title, $sub',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!on) HapticFeedback.selectionClick();
              onChanged(v);
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  AnimatedDefaultTextStyle(
                    duration: reduce ? Duration.zero : const Duration(milliseconds: 150),
                    curve: Curves.easeOut,
                    style: HText.inter(
                        size: sub == null ? 13 : 14,
                        weight: on ? FontWeight.w600 : FontWeight.w500,
                        color: on ? HColors.ink : HColors.ink2),
                    child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                  ),
                  if (sub != null)
                    Text(sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: HText.inter(size: 11, weight: FontWeight.w500, color: HColors.inkMuted)),
                ]),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: HColors.track.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(14)),
      child: Stack(children: [
        // Already on screen, so it moves with ease-in-out, 240 ms.
        Positioned.fill(
          child: AnimatedAlign(
            alignment: Alignment(n == 1 ? 0 : -1 + 2 * (i < 0 ? 0 : i) / (n - 1), 0),
            duration: reduce ? Duration.zero : const Duration(milliseconds: 240),
            curve: const Cubic(0.65, 0, 0.35, 1),
            child: FractionallySizedBox(
              widthFactor: 1 / n,
              heightFactor: 1,
              child: AnimatedOpacity(
                opacity: i < 0 ? 0 : 1,
                duration: reduce ? Duration.zero : const Duration(milliseconds: 150),
                child: Container(
                  decoration: BoxDecoration(
                    color: HColors.surface,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1414281E), offset: Offset(0, 1), blurRadius: 2),
                      BoxShadow(color: Color(0x0F14281E), offset: Offset(0, 3), blurRadius: 8),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [for (final o in options) option(o)]),
        ),
      ]),
    );
  }
}

/// Start and end as two stops on a line: a hollow dot for the start, a filled
/// one for the end. Each stop is a surah button and an ayah stepper.
class _Route extends StatelessWidget {
  const _Route({
    required this.start,
    required this.end,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onStartAyah,
    required this.onEndAyah,
  });

  final Pos start, end;
  final VoidCallback onPickStart, onPickEnd;
  final ValueChanged<int> onStartAyah, onEndAyah;

  static const _row = 52.0, _gap = 8.0;

  @override
  Widget build(BuildContext context) {
    Widget dot(bool filled) => Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: filled ? HColors.accent : HColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: HColors.accent, width: 2.5),
          ),
        );
    return Stack(children: [
      // The line between the two dots.
      Positioned(
        left: 5,
        top: _row / 2,
        height: _row + _gap,
        child: Container(width: 2, color: HColors.mintRing),
      ),
      Column(children: [
        _PointRow(isStart: true, pos: start, dot: dot(false), onPick: onPickStart, onAyah: onStartAyah),
        const SizedBox(height: _gap),
        _PointRow(isStart: false, pos: end, dot: dot(true), onPick: onPickEnd, onAyah: onEndAyah),
      ]),
    ]);
  }
}

/// START or END: its dot, a surah button and an ayah stepper.
class _PointRow extends StatelessWidget {
  const _PointRow(
      {required this.isStart, required this.pos, required this.dot, required this.onPick, required this.onAyah});

  final bool isStart;
  final Pos pos;
  final Widget dot;
  final VoidCallback onPick;
  final ValueChanged<int> onAyah;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: _Route._row,
        child: Row(children: [
          SizedBox(width: 12, child: Center(child: dot)),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              button: true,
              label: isStart
                  ? context.l10n.startSurahLabel(pos.s, nameOf(pos.s))
                  : context.l10n.endSurahLabel(pos.s, nameOf(pos.s)),
              excludeSemantics: true,
              child: _Pressable(
                onTap: onPick,
                child: Container(
                  height: _Route._row,
                  padding: const EdgeInsets.only(left: 8, right: 6),
                  decoration: BoxDecoration(color: HColors.bgTop, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    _NumberBadge(pos.s),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isStart ? context.l10n.start : context.l10n.end,
                              style: HText.inter(size: 11, weight: FontWeight.w500, color: HColors.inkMuted)),
                          Text(nameOf(pos.s),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: HText.inter(size: 15, weight: FontWeight.w600, height: 1.2)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 20, color: HColors.inkMuted),
                  ]),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: _Stepper(label: context.l10n.ayah, value: pos.a, min: 1, max: ayahsIn(pos.s), onChanged: onAyah, side: 36),
          ),
        ]),
      );
}

class _NumberBadge extends StatelessWidget {
  const _NumberBadge(this.n, {this.selected = false, this.muted = false});
  final int n;
  final bool selected;

  /// Gray instead of mint (the picker's unselected rows).
  final bool muted;

  @override
  Widget build(BuildContext context) => Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? HColors.accentDeep : (muted ? HColors.bgTop : HColors.mintWash),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text('$n',
            style: HText.inter(
                size: 12,
                weight: FontWeight.w700,
                tabular: true,
                color: selected ? Colors.white : (muted ? HColors.ink2 : HColors.accentDeep))),
      );
}

/// − / number / +. The number can be typed; it's checked when the field is
/// left or submitted, not on every keystroke.
class _Stepper extends StatefulWidget {
  const _Stepper({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.side = 44,
  });

  final String label;

  /// Width of the − and + targets; narrower (36) beside a surah button.
  final double side;
  final int value, min, max;
  final ValueChanged<int> onChanged;

  @override
  State<_Stepper> createState() => _StepperState();
}

class _StepperState extends State<_Stepper> {
  late final _text = TextEditingController(text: '${widget.value}');
  final _focus = FocusNode();

  /// The side being pressed: -1, 1, or null.
  int? _down;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
      setState(() {});
    });
  }

  @override
  void didUpdateWidget(_Stepper old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && _text.text != '${widget.value}') _text.text = '${widget.value}';
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _commit() {
    final v = int.tryParse(_text.text.trim());
    final next = v == null ? widget.value : v.clamp(widget.min, widget.max);
    _text.text = '$next';
    if (next != widget.value) widget.onChanged(next);
  }

  void _step(int d) {
    _focus.unfocus();
    final next = (widget.value + d).clamp(widget.min, widget.max);
    if (next != widget.value) widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    Widget side(String glyph, String name, int d, bool enabled) => Semantics(
          button: true,
          enabled: enabled,
          label: '$name ${label.toLowerCase()}',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled ? (_) => setState(() => _down = d) : null,
            onTapUp: (_) => setState(() => _down = null),
            onTapCancel: () => setState(() => _down = null),
            onTap: enabled ? () => _step(d) : null,
            // An instant tint while pressed; no motion, since it's tapped many times in a row.
            child: Container(
              width: widget.side,
              color: _down == d ? HColors.divider : Colors.transparent,
              child: Center(
                child: Text(glyph,
                    style: HText.inter(
                        size: 20, weight: FontWeight.w500, color: enabled ? HColors.ink2 : const Color(0xFFC9CFD6))),
              ),
            ),
          ),
        );

    return Container(
      height: 52,
      clipBehavior: Clip.antiAlias,
      // Gray like the other controls in its card; a dark ring while typing.
      decoration: BoxDecoration(
        color: HColors.bgTop,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _focus.hasFocus ? HColors.ink : HColors.bgTop, width: 2),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        side('−', context.l10n.decrease, -1, widget.value > widget.min),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ExcludeSemantics(
              child: Text(label.toUpperCase(),
                  maxLines: 1,
                  softWrap: false,
                  style: HText.inter(size: 10, weight: FontWeight.w600, letterSpacing: 0.4, color: HColors.inkMuted)),
            ),
            Semantics(
              label: context.l10n.rangeLabel(label, widget.min, widget.max),
              child: TextField(
                controller: _text,
                focusNode: _focus,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(3)],
                onSubmitted: (_) => _commit(),
                textAlign: TextAlign.center,
                style: HText.inter(size: 16, weight: FontWeight.w700, tabular: true, height: 1.2),
                cursorColor: HColors.accentDeep,
                decoration: const InputDecoration(isCollapsed: true, border: InputBorder.none),
              ),
            ),
          ]),
        ),
        side('+', context.l10n.increase, 1, widget.value < widget.max),
      ]),
    );
  }
}

/// An open mushaf page: 15 thin lines, the day's lines in green from the top.
/// Past 15 a second page appears beside it.
class _Book extends StatelessWidget {
  const _Book({required this.lines});
  final int lines;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    Widget page(int from) => Container(
          width: 46,
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
          decoration: BoxDecoration(
            color: HColors.surface,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [BoxShadow(color: Color(0x1F14281E), offset: Offset(0, 1), blurRadius: 2)],
          ),
          child: Column(children: [
            for (var i = 0; i < 15; i++) ...[
              if (i > 0) const SizedBox(height: 2),
              AnimatedContainer(
                duration: reduce ? Duration.zero : const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                height: 2.4,
                decoration: BoxDecoration(
                  color: from + i < lines ? HColors.accent : HColors.track,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ]),
        );
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: HColors.bgTop, borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          page(0),
          if (lines > 15) ...[const SizedBox(width: 3), page(15)],
        ]),
      ),
    );
  }
}

/// A line-count preset in the Daily pace card: gray, or mint when it matches.
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2), // 44 pt to tap
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: selected ? HColors.mintWash : HColors.bgTop,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? HColors.mintRing : HColors.bgTop),
              ),
              // Longer labels ("½ саҳифа") shrink to fit the quarter-width chip instead of being cut off.
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(label,
                      maxLines: 1,
                      style: HText.inter(
                          size: 14,
                          weight: selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected ? HColors.accentDeep : HColors.ink2)),
                ),
              ),
            ),
          ),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(color: HColors.warnSoft, borderRadius: BorderRadius.circular(12)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: HColors.warn, shape: BoxShape.circle),
              child: ExcludeSemantics(
                child: Text('!', style: HText.inter(size: 12, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: HText.inter(size: 13, height: 1.4, color: HColors.warn))),
          ]),
        ),
      );
}

/// How the draft plays out: the number of days and the finish date, a strip
/// of days with day 1 marked, three facts, and what day 1 is.
class _Summary extends StatelessWidget {
  const _Summary({super.key, required this.plan});

  final Plan plan;

  @override
  Widget build(BuildContext context) {
    final lessons = plan.lessons;
    final all = [for (final l in lessons) ...l];
    final surahs = {for (final p in all) p.s}.length;
    final n = lessons.length;
    final same = plan.start.s == plan.end.s;
    final small = HText.inter(size: 11, weight: FontWeight.w500, color: HColors.ink2);
    Widget fact(String text) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: HColors.surface.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(text, style: HText.inter(size: 12, weight: FontWeight.w600, color: HColors.accentDeep)),
        );
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HColors.mintWash,
          borderRadius: BorderRadius.circular(HRadii.panel),
          border: Border.all(color: HColors.mintRing.withValues(alpha: 0.5)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            _RollingNumber(n, style: HText.inter(size: 34, weight: FontWeight.w700, letterSpacing: -0.8, tabular: true)),
            const SizedBox(width: 6),
            Text(context.l10n.dayWord(n), style: HText.inter(size: 16, weight: FontWeight.w600, color: HColors.ink2)),
            const SizedBox(width: 12),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: HColors.surface, borderRadius: BorderRadius.circular(999)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.flag_rounded, size: 15, color: HColors.accentDeep),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(dateShort(context.l10n, plan.finishDate(n)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HText.inter(size: 13, weight: FontWeight.w600, tabular: true)),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: SizedBox(
              height: 8,
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (var i = 0; i < (n < 60 ? n : 60); i++) ...[
                  if (i > 0) const SizedBox(width: 2),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: i == 0 ? HColors.accentDeep : HColors.accentDeep.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ),
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(
              child: Text(same ? '${nameOf(plan.start.s)} ${plan.start.a}' : nameOf(plan.start.s),
                  overflow: TextOverflow.ellipsis, style: small),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(same ? '${plan.end.a}' : nameOf(plan.end.s), overflow: TextOverflow.ellipsis, style: small),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: [
            fact(context.l10n.ayahsCount(all.length)),
            fact(context.l10n.surahsCount(surahs)),
            fact(linesText(context.l10n, sumLines(all))),
          ]),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0x2622B567)),
          const SizedBox(height: 10),
          Text.rich(TextSpan(children: [
            TextSpan(text: '${context.l10n.day1}  ', style: HText.inter(size: 13, weight: FontWeight.w500, color: HColors.ink2)),
            TextSpan(text: seg(lessons.first), style: HText.inter(size: 13, weight: FontWeight.w600)),
            TextSpan(
                text: ' · ${linesText(context.l10n, sumLines(lessons.first))}',
                style: HText.inter(size: 13, color: HColors.ink2)),
          ])),
        ]),
      ),
    );
  }
}

/// In place of the summary while the range can't make a plan.
class _SummaryHint extends StatelessWidget {
  const _SummaryHint({super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(HRadii.panel),
          border: Border.all(color: HColors.track, width: 1.5),
        ),
        child: Row(children: [
          const Icon(Icons.event_note_outlined, size: 20, color: HColors.inkMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(context.l10n.summaryHint,
                style: HText.inter(size: 13, color: HColors.inkMuted)),
          ),
        ]),
      );
}

/// A number that rolls to its new value: the new one rises in from below
/// (180 ms, ease-out) while the old one fades. Still under Reduce Motion.
class _RollingNumber extends StatelessWidget {
  const _RollingNumber(this.value, {required this.style});
  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) {
          final incoming = child.key == ValueKey(value);
          return ClipRect(
            child: SlideTransition(
              position: Tween(begin: Offset(0, incoming ? 0.5 : -0.5), end: Offset.zero).animate(anim),
              child: FadeTransition(opacity: anim, child: child),
            ),
          );
        },
        child: Text('$value', key: ValueKey(value), style: style),
      );
}

/// Shrinks a little while pressed.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      );
}

// ---------------------------------------------------------------- surah picker

/// A searchable surah list in the plan's reading order. Pops with the surah picked.
class _SurahPicker extends StatefulWidget {
  const _SurahPicker({required this.title, required this.order, required this.selected});

  final String title;
  final ReadingOrder order;
  final int selected;

  @override
  State<_SurahPicker> createState() => _SurahPickerState();
}

class _SurahPickerState extends State<_SurahPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 9;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final all = [for (var i = 1; i <= 114; i++) widget.order == ReadingOrder.fromBeginning ? i : 115 - i];
    final q = _query.replaceAll(RegExp("['ʿ‘’]"), '');
    final shown = [
      for (final s in all)
        if (surahMatches(s, q)) s
    ];

    return Scaffold(
      backgroundColor: HColors.bgTop,
      body: Padding(
        padding: EdgeInsets.fromLTRB(16, top < 56 ? 56 : top, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            GlassBackButton(onTap: () => Navigator.of(context).maybePop()),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(widget.title, style: HText.inter(size: 22, weight: FontWeight.w700, letterSpacing: -0.3)),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            height: 48,
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              autocorrect: false,
              enableSuggestions: false,
              style: HText.inter(size: 16),
              cursorColor: HColors.accentDeep,
              decoration: InputDecoration(
                hintText: context.l10n.nameOrNumber,
                hintStyle: HText.inter(size: 16, color: const Color(0xFF9AA3AD)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                prefixIcon: const Icon(Icons.search_rounded, size: 21, color: HColors.inkMuted),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: HColors.track),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: HColors.ink, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: shown.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                    child: Text(context.l10n.noSurahMatchesDot(_query.trim()),
                        style: HText.inter(size: 14, color: HColors.inkMuted)),
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: bottom + 16),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final s = shown[i];
                      final on = s == widget.selected;
                      return Semantics(
                        button: true,
                        selected: on,
                        label: '$s, ${nameOf(s)}, ${context.l10n.ayahsCount(ayahsIn(s))}',
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.of(context).pop(s),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 52),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              border: i == 0 ? null : const Border(top: BorderSide(color: HColors.divider)),
                            ),
                            child: Row(children: [
                              _NumberBadge(s, selected: on, muted: true),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(nameOf(s),
                                    style: HText.inter(size: 15, weight: on ? FontWeight.w600 : FontWeight.w500)),
                              ),
                              Text('${ayahsIn(s)}',
                                  style: HText.inter(size: 12, color: HColors.inkMuted, tabular: true)),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }
}
