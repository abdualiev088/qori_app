import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/learned_store.dart';
import '../data/surahs.dart';
import '../theme/tokens.dart';
import 'quran_progress_card.dart' show PercentRing;
import 'star.dart';
import 'toast.dart';

const _tabular = [FontFeature.tabularFigures()];
const _discardRed = Color(0xFFA23B26);

String _ayahs(int n) => n == 1 ? 'ayah' : 'ayahs';

/// Opens the sheet for marking [surah]'s ayahs learned. Edits stay in a draft
/// until the user saves them in the "Save changes?" dialog.
Future<void> showLearnedSheet(BuildContext context, {required LearnedStore store, required int surah}) {
  final media = MediaQuery.of(context);
  return Navigator.of(context).push(_GuardedSheetRoute(
    builder: (_) => _LearnedSheet(store: store, surah: surah),
    isScrollControlled: true,
    useSafeArea: true,
    enableDrag: true,
    backgroundColor: HColors.surface,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
    modalBarrierColor: const Color(0x570A140F),
    barrierLabel: MaterialLocalizations.of(context).scrimLabel,
    sheetAnimationStyle: media.disableAnimations
        ? AnimationStyle.noAnimation
        : const AnimationStyle(
            duration: Duration(milliseconds: 300),
            curve: Cubic(0.32, 0.72, 0, 1),
            reverseDuration: Duration(milliseconds: 200),
            reverseCurve: Curves.easeIn,
          ),
  ));
}

/// A modal bottom sheet that won't close while there are unsaved edits.
///
/// The scrim, back and Escape go through the sheet's [PopScope], but a drag
/// down closes the sheet with [Navigator.pop], which [PopScope] can't stop. So
/// the route refuses that pop, slides back up and asks the sheet what to do.
class _GuardedSheetRoute extends ModalBottomSheetRoute<void> {
  _GuardedSheetRoute({
    required super.builder,
    required super.isScrollControlled,
    super.useSafeArea,
    super.enableDrag,
    super.backgroundColor,
    super.clipBehavior,
    super.shape,
    super.constraints,
    super.modalBarrierColor,
    super.barrierLabel,
    super.sheetAnimationStyle,
  });

  bool Function()? hasChanges;
  VoidCallback? onBlockedClose;

  /// Set once the sheet has decided to close.
  bool allowPop = false;

  @override
  bool didPop(void result) {
    if (!allowPop && (hasChanges?.call() ?? false)) {
      controller?.forward();
      // didPop runs while the navigator is busy; ask once it's done.
      WidgetsBinding.instance.addPostFrameCallback((_) => onBlockedClose?.call());
      return false;
    }
    return super.didPop(result);
  }
}

enum _Choice { save, keep, discard }

class _LearnedSheet extends StatefulWidget {
  const _LearnedSheet({required this.store, required this.surah});

  final LearnedStore store;
  final int surah;

  @override
  State<_LearnedSheet> createState() => _LearnedSheetState();
}

class _LearnedSheetState extends State<_LearnedSheet> {
  late final Set<int> _saved = widget.store.ayahsOf(widget.surah);
  late Set<int> _draft = {..._saved};
  final _doneFocus = FocusNode(debugLabel: 'Done');
  bool _dialogOpen = false;

  int get _count => surahAyahCounts[widget.surah - 1];
  String get _name => surahNames[widget.surah - 1];
  bool get _changed => !setEquals(_draft, _saved);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is _GuardedSheetRoute) {
      route
        ..hasChanges = (() => _changed)
        ..onBlockedClose = _attemptClose;
    }
  }

  @override
  void dispose() {
    _doneFocus.dispose();
    super.dispose();
  }

  void _setDraft(Set<int> draft) => setState(() => _draft = draft);

  void _setWhole(bool on) {
    final before = _draft;
    _setDraft(on ? {for (var a = 1; a <= _count; a++) a} : {});
    Toast.show(
      context,
      on ? 'All $_count ${_ayahs(_count)} marked' : 'All ayahs cleared',
      onUndo: () {
        if (mounted) _setDraft(before);
      },
    );
  }

  void _close() {
    final route = ModalRoute.of(context);
    if (route is _GuardedSheetRoute) route.allowPop = true;
    Navigator.of(context).pop();
  }

  Future<void> _attemptClose() async {
    if (_dialogOpen || !mounted) return;
    if (!_changed) return _close();
    _dialogOpen = true;
    final choice = await _showSaveDialog(context, name: _name, count: _count, saved: _saved, draft: _draft);
    _dialogOpen = false;
    if (!mounted) return;
    switch (choice) {
      case _Choice.save:
        final learned = _draft.length;
        await widget.store.commit(widget.surah, _draft);
        if (!mounted) return;
        Toast.show(context, 'Saved · $_name, $learned of $_count ${_ayahs(_count)} learned');
        _close();
      case _Choice.discard:
        Toast.show(context, 'Changes discarded');
        _close();
      case _Choice.keep || null:
        _doneFocus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final learned = _draft.length;
    final fraction = learned / _count;
    final status = learned == 0
        ? 'Not started · $_count ${_ayahs(_count)}'
        : learned == _count
            ? 'Learned · all $_count ${_ayahs(_count)}'
            : '$learned of $_count ${_ayahs(_count)} learned';
    final (Color stroke, Color? fill, Color numColor) = learned == 0
        ? (HColors.inkMuted, null, HColors.ink2)
        : learned == _count
            ? (HColors.accentDeep, HColors.accentDeep.withValues(alpha: 0.16), HColors.accentDeep)
            : (HColors.accentDeep, HColors.mintWash, HColors.accentDeep);
    final next = [for (var a = 1; a <= _count; a++) a].where((a) => !_draft.contains(a)).firstOrNull;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _attemptClose();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 26,
            child: Center(
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(color: HColors.track, borderRadius: BorderRadius.circular(3)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Focus(
              autofocus: true,
              child: Semantics(
                header: true,
                container: true,
                label: 'Surah ${widget.surah}, $_name. $status',
                excludeSemantics: true,
                child: Row(
                  children: [
                    StarBadge(
                      size: 34,
                      stroke: stroke,
                      fill: fill,
                      label: Text('${widget.surah}',
                          style: HText.inter(size: 11, weight: FontWeight.w700, color: numColor)
                              .copyWith(fontFeatures: _tabular)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: HText.inter(size: 16, weight: FontWeight.w600)),
                          const SizedBox(height: 1),
                          Text(status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: HText.inter(size: 13, color: HColors.ink2).copyWith(fontFeatures: _tabular)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    PercentRing(value: fraction),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _WholeSurahRow(count: _count, on: learned == _count, onChanged: _setWhole),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Tap an ayah to mark it, or slide across ayahs to mark several. The dashed one is next.',
                style: HText.inter(size: 12, color: HColors.inkMuted)),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _AyahGrid(count: _count, learned: _draft, next: next, onChanged: _setDraft),
            ),
          ),
          const SizedBox(height: 14),
          const ColoredBox(color: HColors.divider, child: SizedBox(height: 1)),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
            child: FilledButton(
              focusNode: _doneFocus,
              onPressed: _attemptClose,
              style: _primaryButton,
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }
}

final _primaryButton = FilledButton.styleFrom(
  backgroundColor: HColors.accentDeep,
  foregroundColor: Colors.white,
  minimumSize: const Size.fromHeight(50),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  textStyle: HText.inter(size: 15, weight: FontWeight.w600, color: Colors.white),
);

class _WholeSurahRow extends StatelessWidget {
  const _WholeSurahRow({required this.count, required this.on, required this.onChanged});

  final int count;
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: on,
      label: 'Whole surah learned. Marks all $count ${_ayahs(count)} at once',
      excludeSemantics: true,
      child: Material(
        color: HColors.bgTop,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onChanged(!on),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Whole surah learned', style: HText.inter(size: 15, weight: FontWeight.w600)),
                        const SizedBox(height: 1),
                        Text('Marks all $count ${_ayahs(count)} at once',
                            style: HText.inter(size: 12, color: HColors.ink2)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _Switch(on: on),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 46×28 switch; the row around it handles taps.
class _Switch extends StatelessWidget {
  const _Switch({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final duration = MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 160);
    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOut,
      width: 46,
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: on ? HColors.accent : HColors.track,
        borderRadius: BorderRadius.circular(14),
      ),
      child: AnimatedAlign(
        duration: duration,
        curve: Curves.easeOut,
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0x2914462D), offset: Offset(0, 2), blurRadius: 4)],
          ),
        ),
      ),
    );
  }
}

/// 8-column ayah grid. Tap toggles one ayah; sliding marks every ayah the
/// finger passes with the opposite of the first one's state.
///
/// When every ayah fits, any slide marks. When the grid scrolls, a sideways
/// slide marks right away (then can go in any direction), an up/down swipe
/// scrolls, and press-and-hold then slide still marks in any direction.
class _AyahGrid extends StatefulWidget {
  const _AyahGrid({required this.count, required this.learned, required this.next, required this.onChanged});

  final int count;
  final Set<int> learned;
  final int? next;
  final ValueChanged<Set<int>> onChanged;

  @override
  State<_AyahGrid> createState() => _AyahGridState();
}

class _AyahGridState extends State<_AyahGrid> {
  static const _cols = 8;
  static const _gap = 4.0;

  final _gridKey = GlobalKey();
  final _scroll = ScrollController();

  int? _pressed; // 0-based index shown pressed
  Offset? _downAt;
  bool _marking = false;
  bool _markValue = false;
  int _last = 0;

  /// The marks so far in this slide. Several moves can land before the parent
  /// rebuilds with a new [_AyahGrid.learned], so build on this, not on that.
  Set<int> _working = {};

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  double _tile(double width) => (width - _gap * (_cols - 1)) / _cols;

  int? _indexAt(Offset p, {bool clamp = false}) {
    final box = _gridKey.currentContext!.findRenderObject()! as RenderBox;
    final step = _tile(box.size.width) + _gap;
    var col = (p.dx / step).floor();
    var row = ((p.dy + (_scroll.hasClients ? _scroll.offset : 0)) / step).floor();
    final rows = (widget.count / _cols).ceil();
    if (clamp) {
      col = col.clamp(0, _cols - 1);
      row = row.clamp(0, rows - 1);
    } else if (col < 0 || col >= _cols || row < 0 || row >= rows || p.dy < 0 || p.dy > box.size.height) {
      return null;
    }
    final i = row * _cols + col;
    if (i < widget.count) return i;
    return clamp ? widget.count - 1 : null;
  }

  void _toggle(int i) {
    final next = {...widget.learned};
    next.contains(i + 1) ? next.remove(i + 1) : next.add(i + 1);
    widget.onChanged(next);
  }

  void _markStart(Offset p) {
    final i = _indexAt(p, clamp: true)!;
    _marking = true;
    _working = {...widget.learned};
    _markValue = !_working.contains(i + 1);
    _last = i;
    setState(() => _pressed = i);
    _apply(i, i);
  }

  void _markMove(Offset p) {
    if (!_marking) return;
    final i = _indexAt(p, clamp: true)!;
    if (i == _last) return;
    // Fill the ayahs a fast slide skipped over.
    final from = i > _last ? _last + 1 : i;
    final to = i > _last ? i : _last - 1;
    _last = i;
    setState(() => _pressed = i);
    _apply(from, to);
  }

  void _apply(int from, int to) {
    var changed = false;
    for (var k = from; k <= to; k++) {
      changed |= _markValue ? _working.add(k + 1) : _working.remove(k + 1);
    }
    if (!changed) return;
    HapticFeedback.selectionClick();
    widget.onChanged({..._working});
  }

  void _markEnd() => setState(() {
        _marking = false;
        _pressed = null;
        _downAt = null;
      });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final tile = _tile(box.maxWidth);
      final rows = (widget.count / _cols).ceil();
      final full = rows * tile + (rows - 1) * _gap;
      final fits = full <= box.maxHeight;
      final height = math.min(full, box.maxHeight);
      return SizedBox(
        height: height,
        child: Listener(
          onPointerDown: (e) => setState(() {
            _downAt = e.localPosition;
            _pressed = _indexAt(e.localPosition);
          }),
          onPointerMove: (e) {
            final from = _downAt;
            if (_marking || from == null || _pressed == null) return;
            if ((e.localPosition - from).distance > 8) setState(() => _pressed = null);
          },
          onPointerUp: (_) {
            if (!_marking) setState(() => _pressed = null);
          },
          onPointerCancel: (_) {
            if (!_marking) setState(() => _pressed = null);
          },
          child: RawGestureDetector(
            key: _gridKey,
            behavior: HitTestBehavior.opaque,
            gestures: {
              TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                () => TapGestureRecognizer(debugOwner: this),
                (r) => r.onTapUp = (d) {
                  final i = _indexAt(d.localPosition);
                  if (i != null) _toggle(i);
                },
              ),
              if (fits)
                PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                  () => PanGestureRecognizer(debugOwner: this),
                  (r) => r
                    ..dragStartBehavior = DragStartBehavior.down
                    ..gestureSettings = _slideSettings
                    ..onStart = ((d) => _markStart(d.localPosition))
                    ..onUpdate = ((d) => _markMove(d.localPosition))
                    ..onEnd = ((_) => _markEnd())
                    ..onCancel = _markEnd,
                )
              else ...{
                HorizontalDragGestureRecognizer:
                    GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
                  () => HorizontalDragGestureRecognizer(debugOwner: this),
                  (r) => r
                    ..dragStartBehavior = DragStartBehavior.down
                    ..gestureSettings = _sidewaysSettings
                    ..onStart = ((d) => _markStart(d.localPosition))
                    ..onUpdate = ((d) => _markMove(d.localPosition))
                    ..onEnd = ((_) => _markEnd())
                    ..onCancel = _markEnd,
                ),
                _HoldRecognizer: GestureRecognizerFactoryWithHandlers<_HoldRecognizer>(
                  () => _HoldRecognizer(debugOwner: this),
                  (r) => r
                    ..onLongPressStart = ((d) => _markStart(d.localPosition))
                    ..onLongPressMoveUpdate = ((d) => _markMove(d.localPosition))
                    ..onLongPressEnd = ((_) => _markEnd())
                    ..onLongPressCancel = _markEnd,
                ),
              },
            },
            child: GridView.builder(
              controller: _scroll,
              padding: EdgeInsets.zero,
              physics: fits
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _cols,
                mainAxisSpacing: _gap,
                crossAxisSpacing: _gap,
              ),
              itemCount: widget.count,
              itemBuilder: (context, i) => _AyahTile(
                number: i + 1,
                learned: widget.learned.contains(i + 1),
                next: widget.next == i + 1,
                pressed: _pressed == i,
                onToggle: () => _toggle(i),
              ),
            ),
          ),
        ),
      );
    });
  }
}

/// Slides start marking after 8 px, before the sheet's own drag (18 px) can claim them.
const _slideSettings = DeviceGestureSettings(touchSlop: 4); // pan slop is twice this

/// In a scrolling grid, 12 px sideways starts marking; 18 px up or down scrolls.
const _sidewaysSettings = DeviceGestureSettings(touchSlop: 12);

/// A long press that fires after 220 ms and gives up to scrolling after 8 px.
class _HoldRecognizer extends LongPressGestureRecognizer {
  _HoldRecognizer({super.debugOwner}) : super(duration: const Duration(milliseconds: 220));

  @override
  double? get preAcceptSlopTolerance => 8;
}

class _AyahTile extends StatelessWidget {
  const _AyahTile({
    required this.number,
    required this.learned,
    required this.next,
    required this.pressed,
    required this.onToggle,
  });

  final int number;
  final bool learned;
  final bool next;
  final bool pressed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      toggled: learned,
      label: 'Ayah $number, ${learned ? 'learned' : 'not learned'}',
      excludeSemantics: true,
      onTap: onToggle,
      child: AnimatedScale(
        scale: pressed ? 0.94 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: learned ? HColors.accentDeep : HColors.divider,
            borderRadius: BorderRadius.circular(10),
          ),
          child: CustomPaint(
            foregroundPainter: next ? const _DashedOutline() : null,
            child: Center(
              child: Text('$number',
                  maxLines: 1,
                  softWrap: false,
                  style: HText.inter(size: 13, weight: FontWeight.w600, color: learned ? Colors.white : HColors.inkMuted)
                      .copyWith(fontFeatures: _tabular)),
            ),
          ),
        ),
      ),
    );
  }
}

/// 1.5 px dashed accent outline, inset 4 px, marking the next ayah to learn.
class _DashedOutline extends CustomPainter {
  const _DashedOutline();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(4);
    final outline = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = HColors.accent;
    for (final PathMetric m in outline.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 7) {
        canvas.drawPath(m.extractPath(d, math.min(d + 4, m.length)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutline old) => false;
}

// ── "Save changes?" dialog ─────────────────────────────────────────────

Future<_Choice?> _showSaveDialog(
  BuildContext context, {
  required String name,
  required int count,
  required Set<int> saved,
  required Set<int> draft,
}) {
  final reduce = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<_Choice>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0x4D0A140F),
    transitionDuration: reduce ? Duration.zero : const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondary) => _SaveDialog(name: name, count: count, saved: saved, draft: draft),
    transitionBuilder: (context, animation, _, child) {
      if (reduce) return child;
      final double opacity, scale;
      if (animation.status == AnimationStatus.reverse) {
        // Exit: 150 ms of the 200 ms route, easing in to 98%.
        final t = Curves.easeIn.transform(const Interval(0.25, 1).transform(animation.value));
        opacity = t;
        scale = 0.98 + 0.02 * t;
      } else {
        final t = Curves.easeOut.transform(animation.value);
        opacity = t;
        scale = 0.96 + 0.04 * t;
      }
      return Opacity(opacity: opacity, child: Transform.scale(scale: scale, child: child));
    },
  );
}

class _SaveDialog extends StatelessWidget {
  const _SaveDialog({required this.name, required this.count, required this.saved, required this.draft});

  final String name;
  final int count;
  final Set<int> saved;
  final Set<int> draft;

  @override
  Widget build(BuildContext context) {
    final marked = draft.difference(saved).length;
    final unmarked = saved.difference(draft).length;
    final changes = [
      if (marked > 0) '$marked ${_ayahs(marked)} marked learned',
      if (unmarked > 0) marked > 0 ? '$unmarked unmarked' : '$unmarked ${_ayahs(unmarked)} unmarked',
    ].join(', ');
    final summary = '$changes. You\'ll have ${draft.length} of $count ${_ayahs(count)} learned.';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: HColors.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(color: Color(0x2E0A140F), offset: Offset(0, 24), blurRadius: 48),
                BoxShadow(color: Color(0x1A0A140F), offset: Offset(0, 4), blurRadius: 12),
              ],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: _SaveIcon()),
                    const SizedBox(height: 12),
                    Semantics(
                      header: true,
                      child: Text('Save changes?',
                          textAlign: TextAlign.center,
                          style: HText.inter(size: 20, weight: FontWeight.w700, letterSpacing: -0.3)),
                    ),
                    const SizedBox(height: 8),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: name, style: HText.inter(size: 14, weight: FontWeight.w600, height: 1.45)),
                        TextSpan(text: ': $summary'),
                      ]),
                      textAlign: TextAlign.center,
                      style: HText.inter(size: 14, height: 1.45, color: HColors.ink2).copyWith(fontFeatures: _tabular),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      autofocus: true,
                      onPressed: () => Navigator.of(context).pop(_Choice.save),
                      style: _primaryButton,
                      child: const Text('Save changes'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(_Choice.keep),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: HColors.ink,
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(color: HColors.track),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        textStyle: HText.inter(size: 15, weight: FontWeight.w600),
                      ),
                      child: const Text('Keep editing'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(_Choice.discard),
                      style: TextButton.styleFrom(
                        foregroundColor: _discardRed,
                        minimumSize: const Size.fromHeight(44),
                        textStyle: HText.inter(size: 14, weight: FontWeight.w600, color: _discardRed),
                      ),
                      child: const Text('Discard changes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 88 px icon: a mint circle grows, a star outline draws itself and fills,
/// then a white check is drawn while the whole icon pops. About 1.3 s.
class _SaveIcon extends StatefulWidget {
  const _SaveIcon();

  @override
  State<_SaveIcon> createState() => _SaveIconState();
}

class _SaveIconState extends State<_SaveIcon> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isDismissed) {
      MediaQuery.disableAnimationsOf(context) ? _controller.value = 1 : _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SizedBox.square(dimension: 88, child: CustomPaint(painter: _SaveIconPainter(_controller))),
      );
}

class _SaveIconPainter extends CustomPainter {
  _SaveIconPainter(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  static const _center = Offset(44, 44);
  static const _starEase = Cubic(0.65, 0, 0.35, 1);

  static final Path _star = () {
    const big = 30.0, small = big * 0.7654;
    final p = Path();
    for (var k = 0; k < 16; k++) {
      final a = -math.pi / 2 + k * math.pi / 8;
      final r = k.isOdd ? small : big;
      final pt = _center + Offset(r * math.cos(a), r * math.sin(a));
      k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }();

  static final Path _check = Path()
    ..moveTo(32, 45)
    ..relativeLineTo(8, 8)
    ..relativeLineTo(16.5, -17);

  /// Progress through [startMs]–[endMs] of the 1300 ms timeline, 0–1.
  double _span(double ms, double startMs, double endMs) => ((ms - startMs) / (endMs - startMs)).clamp(0.0, 1.0);

  static Path _partial(Path path, double t) {
    final out = Path();
    if (t <= 0) return out;
    for (final m in path.computeMetrics()) {
      out.addPath(m.extractPath(0, m.length * t), Offset.zero);
    }
    return out;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final ms = progress.value * 1300;
    canvas.scale(size.width / 88, size.height / 88);

    final pop = _span(ms, 860, 1280);
    final popScale = 1 + 0.06 * math.sin(math.pi * pop);
    canvas
      ..translate(_center.dx, _center.dy)
      ..scale(popScale)
      ..translate(-_center.dx, -_center.dy);

    final circle = Curves.easeOut.transform(_span(ms, 0, 320));
    canvas.drawCircle(
      _center,
      42 * (0.6 + 0.4 * circle),
      Paint()..color = HColors.mintWash.withValues(alpha: circle),
    );

    final fill = _span(ms, 680, 920);
    if (fill > 0) canvas.drawPath(_star, Paint()..color = HColors.accentDeep.withValues(alpha: fill));

    canvas.drawPath(
      _partial(_star, _starEase.transform(_span(ms, 120, 740))),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = HColors.accentDeep,
    );

    canvas.drawPath(
      _partial(_check, Curves.easeOut.transform(_span(ms, 860, 1160))),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_SaveIconPainter old) => old.progress != progress;
}
