import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/surahs.dart';
import '../theme/tokens.dart';
import 'star.dart';

const _cols = 10;
const _gap = 4.0;
const _ease = Cubic(0.23, 1, 0.32, 1);
const _tabular = [FontFeature.tabularFigures()];

TextStyle _num({required double size, required FontWeight weight, Color color = HColors.ink, double? letterSpacing}) =>
    HText.inter(size: size, weight: weight, color: color, letterSpacing: letterSpacing)
        .copyWith(fontFeatures: _tabular);

String _status(SurahProgress s) {
  if (s.notStarted) return 'Not started · ${s.ayahs} ayahs';
  if (s.isMemorized) return 'Memorized · ${s.ayahs} ayahs';
  return '${s.memorized} of ${s.ayahs} ayahs · ${s.ayahs - s.memorized} to go';
}

String _label(SurahProgress s) => 'Surah ${s.number}, ${s.name}. ${_status(s)}';

int _percent(SurahProgress s) => (s.fraction * 100).round();

/// Memorization across all 114 surahs: a 10-column tile grid, a hint, and a
/// detail row for the selected surah. Tap a tile, or press and hold then slide
/// to browse with a loupe above the finger. The parent owns [selected].
class QuranProgressCard extends StatefulWidget {
  const QuranProgressCard({super.key, required this.surahs, required this.selected, required this.onSelect})
      : assert(surahs.length == 114);

  final List<SurahProgress> surahs;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  State<QuranProgressCard> createState() => _QuranProgressCardState();
}

class _QuranProgressCardState extends State<QuranProgressCard> {
  final _gridKey = GlobalKey();

  /// Tile shown pressed (pointer down, or under the finger while browsing).
  int? _pressed;
  Offset? _downAt;
  bool _browsing = false;

  OverlayEntry? _loupe;
  final _loupeData = ValueNotifier<_LoupeData?>(null);

  double _tileSize(double width) => (width - _gap * (_cols - 1)) / _cols;

  /// The tile under [p] (grid coordinates). With [clamp], points outside the
  /// grid or in the empty end of the last row snap to the nearest tile.
  int? _tileAt(Offset p, {bool clamp = false}) {
    final box = _gridKey.currentContext!.findRenderObject()! as RenderBox;
    final step = _tileSize(box.size.width) + _gap;
    var col = (p.dx / step).floor();
    var row = (p.dy / step).floor();
    final rows = (widget.surahs.length / _cols).ceil();
    if (clamp) {
      col = col.clamp(0, _cols - 1);
      row = row.clamp(0, rows - 1);
    } else if (col < 0 || col >= _cols || row < 0 || row >= rows) {
      return null;
    }
    final i = row * _cols + col;
    if (i < widget.surahs.length) return i;
    return clamp ? widget.surahs.length - 1 : null;
  }

  Rect _tileRect(int i) {
    final box = _gridKey.currentContext!.findRenderObject()! as RenderBox;
    final size = _tileSize(box.size.width);
    final topLeft = Offset((i % _cols) * (size + _gap), (i ~/ _cols) * (size + _gap));
    return box.localToGlobal(topLeft) & Size.square(size);
  }

  void _onPointerDown(PointerDownEvent e) => setState(() {
        _downAt = e.localPosition;
        _pressed = _tileAt(e.localPosition);
      });

  void _onPointerMove(PointerMoveEvent e) {
    final from = _downAt;
    if (_browsing || from == null || _pressed == null) return;
    if ((e.localPosition - from).distance > 8) setState(() => _pressed = null);
  }

  void _onPointerEnd(PointerEvent _) {
    if (_browsing) return;
    setState(() {
      _pressed = null;
      _downAt = null;
    });
  }

  void _onTapUp(TapUpDetails d) {
    final i = _tileAt(d.localPosition);
    if (i != null && i != widget.selected) widget.onSelect(i);
  }

  void _browseStart(LongPressStartDetails d) {
    final i = _tileAt(d.localPosition, clamp: true)!;
    _browsing = true;
    HapticFeedback.selectionClick();
    setState(() => _pressed = i);
    if (i != widget.selected) widget.onSelect(i);
    _showLoupe(i);
  }

  void _browseMove(LongPressMoveUpdateDetails d) {
    final i = _tileAt(d.localPosition, clamp: true)!;
    if (i == _pressed) return;
    HapticFeedback.selectionClick();
    setState(() => _pressed = i);
    widget.onSelect(i);
    _loupeData.value = _LoupeData(widget.surahs[i], _tileRect(i));
  }

  void _browseEnd() {
    _browsing = false;
    _hideLoupe();
    setState(() {
      _pressed = null;
      _downAt = null;
    });
  }

  void _showLoupe(int i) {
    _loupeData.value = _LoupeData(widget.surahs[i], _tileRect(i));
    _loupe ??= OverlayEntry(builder: (_) => _LoupeLayer(data: _loupeData));
    Overlay.of(context).insert(_loupe!);
  }

  void _hideLoupe() {
    _loupe?.remove();
    _loupe = null;
    _loupeData.value = null;
  }

  @override
  void dispose() {
    _hideLoupe();
    _loupeData.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surahs = widget.surahs;
    final memorized = surahs.where((s) => s.isMemorized).length;
    final current = surahs[widget.selected];

    return Container(
      decoration: BoxDecoration(color: HColors.surface, borderRadius: BorderRadius.circular(HRadii.card)),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text('QURAN PROGRESS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HText.inter(size: 12, weight: FontWeight.w600, letterSpacing: 0.6, color: HColors.ink2)),
              ),
              Semantics(
                label: '$memorized of ${surahs.length} surahs memorized',
                excludeSemantics: true,
                child: Text.rich(TextSpan(
                  style: _num(size: 14, weight: FontWeight.w700),
                  children: [
                    TextSpan(text: '$memorized'),
                    TextSpan(
                      text: '/${surahs.length}',
                      style: _num(size: 14, weight: FontWeight.w500, color: HColors.inkMuted),
                    ),
                  ],
                )),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Semantics(
            container: true,
            label: '${surahs.length} surahs',
            child: Listener(
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerEnd,
              onPointerCancel: _onPointerEnd,
              child: RawGestureDetector(
                key: _gridKey,
                behavior: HitTestBehavior.opaque,
                gestures: {
                  TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                    () => TapGestureRecognizer(debugOwner: this),
                    (r) => r.onTapUp = _onTapUp,
                  ),
                  _HoldRecognizer: GestureRecognizerFactoryWithHandlers<_HoldRecognizer>(
                    () => _HoldRecognizer(debugOwner: this),
                    (r) => r
                      ..onLongPressStart = _browseStart
                      ..onLongPressMoveUpdate = _browseMove
                      ..onLongPressEnd = ((_) => _browseEnd())
                      ..onLongPressCancel = _browseEnd,
                  ),
                },
                child: LayoutBuilder(builder: (context, box) {
                  final size = _tileSize(box.maxWidth);
                  return Column(
                    children: [
                      for (var row = 0; row * _cols < surahs.length; row++) ...[
                        if (row > 0) const SizedBox(height: _gap),
                        Row(
                          children: [
                            for (var col = 0; col < _cols && row * _cols + col < surahs.length; col++) ...[
                              if (col > 0) const SizedBox(width: _gap),
                              _Tile(
                                surah: surahs[row * _cols + col],
                                size: size,
                                selected: row * _cols + col == widget.selected,
                                pressed: row * _cols + col == _pressed,
                                onTap: () => widget.onSelect(row * _cols + col),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text('Tap a surah. Press and hold, then slide, to browse.',
              style: HText.inter(size: 12, color: HColors.inkMuted)),
          const SizedBox(height: 14),
          const ColoredBox(color: HColors.divider, child: SizedBox(height: 1)),
          const SizedBox(height: 12),
          _Detail(surah: current),
        ],
      ),
    );
  }
}

/// A long press that fires after 220 ms and gives up to the page's scroll after 8 px.
class _HoldRecognizer extends LongPressGestureRecognizer {
  _HoldRecognizer({super.debugOwner}) : super(duration: const Duration(milliseconds: 220));

  @override
  double? get preAcceptSlopTolerance => 8;
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.surah,
    required this.size,
    required this.selected,
    required this.pressed,
    required this.onTap,
  });

  final SurahProgress surah;
  final double size;
  final bool selected;
  final bool pressed;
  final VoidCallback onTap;

  static const _radius = BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    final s = surah;
    final numColor = s.isMemorized ? Colors.white : (s.inProgress ? HColors.numOnMint : HColors.inkMuted);
    return Semantics(
      button: true,
      selected: selected,
      label: _label(s),
      excludeSemantics: true,
      onTap: onTap,
      child: AnimatedScale(
        scale: pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: SizedBox.square(
          dimension: size,
          child: ClipRRect(
            borderRadius: _radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: s.isMemorized ? HColors.accentDeep : HColors.divider),
                if (s.inProgress)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: math.max(0.12, s.fraction),
                      widthFactor: 1,
                      child: const ColoredBox(color: Color(0xFF8FDDB4)),
                    ),
                  ),
                Center(
                  child: Text('${s.number}',
                      maxLines: 1, softWrap: false, style: _num(size: 11, weight: FontWeight.w600, color: numColor)),
                ),
                if (selected)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: _radius,
                      border: Border.fromBorderSide(BorderSide(color: HColors.ink, width: 2)),
                    ),
                  ),
                if (selected && s.isMemorized)
                  const Padding(
                    padding: EdgeInsets.all(2),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                        border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 1.5)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.surah});

  final SurahProgress surah;

  @override
  Widget build(BuildContext context) {
    final s = surah;
    final (Color stroke, Color? fill, Color numColor) = s.notStarted
        ? (HColors.inkMuted, null, HColors.ink2)
        : s.isMemorized
            ? (HColors.accentDeep, HColors.accentDeep.withValues(alpha: 0.16), HColors.accentDeep)
            : (HColors.accentDeep, HColors.mintWash, HColors.accentDeep);

    return Semantics(
      liveRegion: true,
      container: true,
      label: '${_label(s)}. ${_percent(s)} percent memorized',
      excludeSemantics: true,
      child: Row(
        children: [
          StarBadge(
            size: 34,
            stroke: stroke,
            fill: fill,
            label: Text('${s.number}', style: _num(size: 11, weight: FontWeight.w700, color: numColor)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: HText.inter(size: 15, weight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text(_status(s),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HText.inter(size: 13, color: HColors.ink2).copyWith(fontFeatures: _tabular)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PercentRing(value: s.fraction),
        ],
      ),
    );
  }
}

/// 46 px ring: 19 px radius, 4 px stroke, percentage in the middle. Animates to
/// a new value over 300 ms (instantly with reduced motion).
class PercentRing extends StatelessWidget {
  const PercentRing({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Semantics(
      label: '$pct percent memorized',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: 46,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value),
          duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 300),
          curve: _ease,
          builder: (context, v, child) => CustomPaint(painter: _RingPainter(v), child: child),
          child: Center(
            child: Text('$pct%',
                style: _num(
                    size: 11,
                    weight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: pct == 0 ? HColors.inkMuted : HColors.ink)),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value);

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    const r = 19.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(c, r, paint..color = HColors.track);
    if (value <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      2 * math.pi * value.clamp(0.0, 1.0),
      false,
      paint
        ..color = HColors.accent
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

class _LoupeData {
  const _LoupeData(this.surah, this.tile);

  final SurahProgress surah;

  /// The tile's rect in global coordinates.
  final Rect tile;
}

/// Fills the overlay and places the loupe above (or below) the tile under the finger.
class _LoupeLayer extends StatelessWidget {
  const _LoupeLayer({required this.data});

  final ValueNotifier<_LoupeData?> data;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return IgnorePointer(
      child: ValueListenableBuilder<_LoupeData?>(
        valueListenable: data,
        builder: (context, d, _) {
          if (d == null) return const SizedBox.shrink();
          final overlay = context.findRenderObject() as RenderBox?;
          final origin = overlay != null && overlay.hasSize ? overlay.localToGlobal(Offset.zero) : Offset.zero;
          return CustomSingleChildLayout(
            delegate: _LoupePosition(d.tile.shift(-origin), top),
            child: _Loupe(surah: d.surah),
          );
        },
      ),
    );
  }
}

class _LoupePosition extends SingleChildLayoutDelegate {
  _LoupePosition(this.tile, this.safeTop);

  final Rect tile;
  final double safeTop;

  bool _above(Size child) => tile.top - 26 - child.height >= safeTop + 8;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) => constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size child) {
    final x = (tile.center.dx - child.width / 2).clamp(8.0, math.max(8.0, size.width - 8 - child.width)).toDouble();
    final y = _above(child) ? tile.top - 26 - child.height : tile.bottom + 26;
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_LoupePosition old) => old.tile != tile || old.safeTop != safeTop;
}

class _Loupe extends StatefulWidget {
  const _Loupe({required this.surah});

  final SurahProgress surah;

  @override
  State<_Loupe> createState() => _LoupeState();
}

class _LoupeState extends State<_Loupe> with SingleTickerProviderStateMixin {
  late final _enter = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_enter.isDismissed) {
      MediaQuery.disableAnimationsOf(context) ? _enter.value = 1 : _enter.forward();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.surah;
    final t = CurvedAnimation(parent: _enter, curve: Curves.easeOut);
    return FadeTransition(
      opacity: t,
      child: ScaleTransition(
        scale: Tween(begin: 0.96, end: 1.0).animate(t),
        alignment: Alignment.bottomCenter,
        child: Container(
          constraints: const BoxConstraints(minWidth: 132),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
          decoration: BoxDecoration(
            color: HColors.ink,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Color(0x470A140F), offset: Offset(0, 10), blurRadius: 24),
              BoxShadow(color: Color(0x2E0A140F), offset: Offset(0, 2), blurRadius: 6),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${s.number}', style: _num(size: 20, weight: FontWeight.w700, color: Colors.white)),
              Text(s.name, style: HText.inter(size: 13, weight: FontWeight.w600, color: Colors.white)),
              Text(_status(s),
                  style: HText.inter(size: 12, color: Colors.white.withValues(alpha: 0.7))
                      .copyWith(fontFeatures: _tabular)),
            ],
          ),
        ),
      ),
    );
  }
}
