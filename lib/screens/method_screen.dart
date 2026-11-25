import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/plan.dart';
import '../data/plan_store.dart';
import '../data/surah_index.dart';
import '../theme/tokens.dart';
import '../widgets/auth_widgets.dart';
import '../widgets/method_explainer.dart';
import '../widgets/mushaf_icon.dart';

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
        title: start ? 'Start surah' : 'End surah',
        order: _order,
        selected: (start ? _start : _end).s,
      ),
    ));
    if (s == null || !mounted) return;
    setState(() => start ? _start = Pos(s, 1) : _end = Pos(s, ayahsIn(s)));
  }

  Future<void> _save() async {
    final p = _draft;
    if (!p.valid) return;
    final editing = _store.plan != null;
    await _store.save(p);
    widget.onSaved(editing ? 'Plan updated' : 'Plan created · day 1 of ${p.lessons.length} is on Home');
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 9;
    final editing = _store.plan != null;
    final draft = _draft;
    final ok = draft.valid;
    final button = _explainer
        ? PrimaryButton(label: editing ? 'Edit my plan' : 'Set up my plan', onPressed: _showForm)
        : PrimaryButton(label: editing ? 'Update my plan' : 'Create my plan', onPressed: ok ? _save : null);

    return Stack(children: [
      Positioned.fill(
        child: SingleChildScrollView(
          controller: _scroll,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
              16, top < 56 ? 56 : top, 16, widget.bottomInset + 12 + PressableButton.fullHeight + 24),
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            layoutBuilder: (current, previous) =>
                Stack(alignment: Alignment.topCenter, children: [...previous, if (current != null) current]),
            child: _explainer
                ? const _Explainer(key: ValueKey('explainer'))
                : KeyedSubtree(key: const ValueKey('form'), child: _form(draft, ok)),
          ),
        ),
      ),
      // Pinned above the nav.
      Positioned(left: 16, right: 16, bottom: widget.bottomInset + 12, child: button),
    ]);
  }

  Widget _form(Plan draft, bool ok) {
    final lessons = ok ? draft.lessons : const <List<Pos>>[];
    final all = [for (final l in lessons) ...l];
    final surahs = {for (final p in all) p.s}.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(Method33.name, style: HText.inter(size: 13, weight: FontWeight.w500, color: HColors.ink2)),
        const SizedBox(height: 2),
        Semantics(
          header: true,
          child: Text('Set your plan', style: HText.inter(size: 24, weight: FontWeight.w700, letterSpacing: -0.4)),
        ),
        const SizedBox(height: 4),
        Text(
          "Choose where you'll start and stop and how many lines a day. Each day you'll get a short plan on Home to "
          'tick off.',
          style: HText.inter(size: 14, height: 1.45, color: HColors.ink2),
        ),
        const SizedBox(height: 16),
        // Its own state, so editing the plan below never folds it or restarts the diagram.
        const _HowItWorks(),
        const SizedBox(height: 20),
        const SectionLabel('READING ORDER'),
        const SizedBox(height: 8),
        _OrderControl(order: _order, onChanged: _setOrder),
        const SizedBox(height: 20),
        _PointRow(
          title: 'START',
          pos: _start,
          onPick: () => _pick(true),
          onAyah: (a) => setState(() => _start = Pos(_start.s, a)),
        ),
        const SizedBox(height: 20),
        _PointRow(
          title: 'END',
          pos: _end,
          onPick: () => _pick(false),
          onAyah: (a) => setState(() => _end = Pos(_end.s, a)),
        ),
        // Grows in rather than shoving everything below it down at once.
        AnimatedSize(
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: ok
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _ErrorCard('The end must come after the start when reading '
                      '${_order == ReadingOrder.fromEnd ? 'from the end' : 'from the beginning'}. '
                      'Change the end point or the reading order.'),
                ),
        ),
        const SizedBox(height: 20),
        const SectionLabel('NEW LINES A DAY'),
        const SizedBox(height: 8),
        Row(children: [
          _Book(lines: _lines),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _Stepper(
                label: 'Lines',
                value: _lines,
                min: 1,
                max: Plan.maxLines,
                onChanged: (v) => setState(() => _lines = v),
              ),
              const SizedBox(height: 6),
              Text(paceWord(_lines), style: HText.inter(size: 13, weight: FontWeight.w500, color: HColors.ink2)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (v, label) in const [(3, '3 lines'), (5, '5 lines'), (7, '½ page'), (15, '1 page')])
            _Chip(label: label, selected: _lines == v, onTap: () => setState(() => _lines = v)),
        ]),
        const SizedBox(height: 10),
        Text(
          'About one hour in the evening, usually 5–8 lines. Lines are counted in the 15-line Madani mushaf, and a '
          'lesson always ends on a whole ayah.',
          style: HText.inter(size: 13, height: 1.45, color: HColors.ink2),
        ),
        const SizedBox(height: 20),
        const SectionLabel('REST DAY'),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (v, label) in const [
            (null, 'None'),
            (DateTime.friday, 'Friday'),
            (DateTime.saturday, 'Saturday'),
            (DateTime.sunday, 'Sunday'),
          ])
            _Chip(label: label, selected: _rest == v, radio: true, onTap: () => setState(() => _rest = v)),
        ]),
        if (ok) ...[
          const SizedBox(height: 20),
          _Preview(plan: draft, lessons: lessons, ayahs: all.length, lines: sumLines(all), surahs: surahs),
        ],
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
          Text(Method33.origin, style: HText.inter(size: 13, weight: FontWeight.w500, color: HColors.ink2)),
          const SizedBox(height: 2),
          Semantics(
            header: true,
            child: Text(Method33.name, style: HText.inter(size: 22, weight: FontWeight.w700, letterSpacing: -0.3)),
          ),
          const SizedBox(height: 6),
          Text(Method33.summary, style: HText.inter(size: 14, height: 1.5, color: HColors.ink3)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: HColors.surface, borderRadius: BorderRadius.circular(HRadii.card)),
            child: const MethodDetails(playing: true),
          ),
        ],
      );
}

/// A card that unfolds the summary, the diagram (playing), At a glance and Tips.
class _HowItWorks extends StatefulWidget {
  const _HowItWorks();

  @override
  State<_HowItWorks> createState() => _HowItWorksState();
}

class _HowItWorksState extends State<_HowItWorks> with SingleTickerProviderStateMixin {
  bool _open = false;

  /// Unfolds in 280 ms, folds back quicker (200 ms); the content stays while it folds, clipped.
  late final _fold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 200),
  );
  late final _size = CurvedAnimation(parent: _fold, curve: const Cubic(0.32, 0.72, 0, 1), reverseCurve: Curves.easeIn);
  late final _fade = CurvedAnimation(
      parent: _fold, curve: const Interval(0.2, 1, curve: Curves.easeOut), reverseCurve: const Interval(0.4, 1));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    _fold
      ..duration = reduce ? Duration.zero : const Duration(milliseconds: 280)
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
    setState(() => _open = !_open);
    _open ? _fold.forward() : _fold.reverse();
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(HRadii.card));
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: radius,
        boxShadow: [BoxShadow(color: Color(0x293B8EF0), offset: Offset(0, 8), blurRadius: 22)],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: ColoredBox(
          color: HColors.surface,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Semantics(
              button: true,
              expanded: _open,
              label: 'How it works, ${Method33.name} in ${Method33.steps.length} steps',
              excludeSemantics: true,
              child: _Pressable(
                onTap: _toggle,
                // Blue behind the icon, fading to white across the card.
                child: Container(
                  constraints: const BoxConstraints(minHeight: 80),
                  padding: const EdgeInsets.fromLTRB(12, 10, 14, 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Color(0xFF5FA6F7), Color(0xFFBFDDFF), Color(0xFFFFFFFF)],
                      stops: [0, .5, 1],
                    ),
                    borderRadius: _open ? const BorderRadius.vertical(top: Radius.circular(HRadii.card)) : radius,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
                  ),
                  child: Row(children: [
                    const MushafPlayIcon(size: 56),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('How it works',
                            style: HText.inter(size: 16, weight: FontWeight.w600, color: const Color(0xFF0E2A52))),
                        const SizedBox(height: 2),
                        Text('${Method33.name} in ${Method33.steps.length} steps',
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
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
                        child: MethodDetails(playing: _open, summary: true),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- form controls

class _OrderControl extends StatelessWidget {
  const _OrderControl({required this.order, required this.onChanged});

  final ReadingOrder order;
  final ValueChanged<ReadingOrder> onChanged;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final fast = reduce ? Duration.zero : const Duration(milliseconds: 150);
    final left = order == ReadingOrder.fromBeginning;
    Widget option(ReadingOrder o, String title, String sub) {
      final on = o == order;
      return Expanded(
        child: Semantics(
          inMutuallyExclusiveGroup: true,
          checked: on,
          button: true,
          label: '$title, $sub',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(o),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  AnimatedDefaultTextStyle(
                    duration: fast,
                    curve: Curves.easeOut,
                    style: HText.inter(size: 14, weight: FontWeight.w600, color: on ? HColors.ink : HColors.ink2),
                    child: Text(title, textAlign: TextAlign.center),
                  ),
                  Text(sub,
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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: HColors.track, borderRadius: BorderRadius.circular(14)),
      child: Stack(children: [
        // The white thumb slides under the chosen option (it's already on screen, so ease-in-out).
        Positioned.fill(
          child: AnimatedAlign(
            alignment: left ? Alignment.centerLeft : Alignment.centerRight,
            duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: HColors.surface,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: const [BoxShadow(color: Color(0x1F14281E), offset: Offset(0, 1), blurRadius: 3)],
                ),
              ),
            ),
          ),
        ),
        IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            option(ReadingOrder.fromBeginning, 'From the beginning', 'Al-Fatihah first'),
            option(ReadingOrder.fromEnd, 'From the end', 'An-Nas first, Juz ʿAmma'),
          ]),
        ),
      ]),
    );
  }
}

/// START or END: a surah button and an ayah stepper.
class _PointRow extends StatelessWidget {
  const _PointRow({required this.title, required this.pos, required this.onPick, required this.onAyah});

  final String title;
  final Pos pos;
  final VoidCallback onPick;
  final ValueChanged<int> onAyah;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(title),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: Semantics(
                button: true,
                label: '$title surah: ${pos.s}, ${nameOf(pos.s)}. Change',
                excludeSemantics: true,
                child: _Pressable(
                  onTap: onPick,
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: HColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: HColors.track),
                    ),
                    child: Row(children: [
                      _NumberBadge(pos.s),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nameOf(pos.s),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: HText.inter(size: 15, weight: FontWeight.w600, height: 1.2)),
                            Text('${ayahsIn(pos.s)} ayahs',
                                maxLines: 1,
                                style: HText.inter(size: 11, weight: FontWeight.w500, color: HColors.inkMuted)),
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
              width: 136,
              child: _Stepper(label: 'Ayah', value: pos.a, min: 1, max: ayahsIn(pos.s), onChanged: onAyah),
            ),
          ]),
        ],
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
  const _Stepper(
      {required this.label, required this.value, required this.min, required this.max, required this.onChanged});

  final String label;
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
              width: 44,
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
      decoration: BoxDecoration(
        color: HColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _focus.hasFocus ? HColors.ink : HColors.track, width: _focus.hasFocus ? 2 : 1),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        side('−', 'Decrease', -1, widget.value > widget.min),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            ExcludeSemantics(
              child: Text(label.toUpperCase(),
                  style: HText.inter(size: 10, weight: FontWeight.w600, letterSpacing: 0.4, color: HColors.inkMuted)),
            ),
            Semantics(
              label: '$label, ${widget.min} to ${widget.max}',
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
        side('+', 'Increase', 1, widget.value < widget.max),
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
        decoration:
            BoxDecoration(color: HColors.surface.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(10)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          page(0),
          if (lines > 15) ...[const SizedBox(width: 3), page(15)],
        ]),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap, this.radio = false});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// One of a group (rest day) rather than a shortcut (line presets).
  final bool radio;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        inMutuallyExclusiveGroup: radio,
        checked: radio ? selected : null,
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
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? HColors.mintWash : HColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: selected ? HColors.mintRing : HColors.track),
              ),
              child: Align(
                widthFactor: 1,
                child: Text(label,
                    style: HText.inter(
                        size: 14,
                        weight: selected ? FontWeight.w600 : FontWeight.w500,
                        color: selected ? HColors.accentDeep : HColors.ink2)),
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

/// How the draft plays out: days, finish date, a strip of days, and Day 1.
class _Preview extends StatelessWidget {
  const _Preview(
      {required this.plan, required this.lessons, required this.ayahs, required this.lines, required this.surahs});

  final Plan plan;
  final List<List<Pos>> lessons;
  final int ayahs, surahs;
  final double lines;

  @override
  Widget build(BuildContext context) {
    final n = lessons.length;
    final same = plan.start.s == plan.end.s;
    final ink = HText.inter(size: 13, height: 1.45, color: HColors.ink2);
    final bold = HText.inter(size: 13, height: 1.45, weight: FontWeight.w600);
    final rest = plan.restWeekday;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: HColors.mintWash, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text('$n', style: HText.inter(size: 30, weight: FontWeight.w700, letterSpacing: -0.6, tabular: true)),
            const SizedBox(width: 6),
            Expanded(
              child: Text('${n == 1 ? 'day' : 'days'} · finishes ${fmtDate(plan.finishDate(n))}',
                  style: HText.inter(size: 14, weight: FontWeight.w500, color: HColors.ink2)),
            ),
          ]),
          const SizedBox(height: 10),
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
                  overflow: TextOverflow.ellipsis,
                  style: HText.inter(size: 11, weight: FontWeight.w500, color: HColors.ink2)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(same ? '${plan.end.a}' : nameOf(plan.end.s),
                  overflow: TextOverflow.ellipsis,
                  style: HText.inter(size: 11, weight: FontWeight.w500, color: HColors.ink2)),
            ),
          ]),
          const SizedBox(height: 10),
          Text.rich(TextSpan(style: ink, children: [
            TextSpan(text: '$ayahs', style: bold),
            const TextSpan(text: ' ayahs, about '),
            TextSpan(text: fmtLines(lines), style: bold),
            const TextSpan(text: ', across '),
            TextSpan(text: '$surahs', style: bold),
            TextSpan(text: ' ${surahs == 1 ? 'surah' : 'surahs'}'),
            if (rest != null) TextSpan(text: ', resting on ${weekdayNames[rest - 1]}s'),
            const TextSpan(text: '.\nDay 1: '),
            TextSpan(text: seg(lessons.first), style: bold),
            TextSpan(text: ' · ${fmtLines(sumLines(lessons.first))}'),
          ])),
        ]),
      ),
    );
  }
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
                hintText: 'Name or number',
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
                    child: Text('No surah matches “${_query.trim()}”.',
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
                        label: '$s, ${nameOf(s)}, ${ayahsIn(s)} ayahs',
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
