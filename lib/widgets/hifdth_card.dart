import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'hifdth_mood.dart';
import 'hifdth_painter.dart';
import 'progress_indicators.dart';

/// Home's main card: Hifdth, the status pill and today's progress on a ribbed
/// background. Everything follows [mood] and morphs when it changes.
class HifdthCard extends StatefulWidget {
  const HifdthCard({super.key, required this.mood, required this.steps});

  final HifdthMood mood;
  final List<DayStep> steps;

  @override
  State<HifdthCard> createState() => _HifdthCardState();
}

class _HifdthCardState extends State<HifdthCard> with TickerProviderStateMixin {
  late final _morph = AnimationController(vsync: this, duration: const Duration(milliseconds: 500), value: 1);
  late final _idle = AnimationController(vsync: this);

  late MoodStyle _from = MoodStyle.of(widget.mood);
  late MoodStyle _to = _from;

  /// Debug builds only: long-press Hifdth to preview the other moods.
  HifdthMood? _preview;

  HifdthMood get _mood => _preview ?? widget.mood;

  MoodStyle get _style {
    final t = _morph.value;
    return MoodStyle.lerp(_from, _to, Curves.easeInOut.transform(t), shapeT: Curves.easeOutBack.transform(t));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncIdle();
  }

  @override
  void didUpdateWidget(HifdthCard old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) {
      _preview = null;
      _morphTo(widget.mood);
    }
  }

  void _morphTo(HifdthMood mood) {
    final target = MoodStyle.of(mood);
    if (identical(target, _to)) return;
    _from = _style;
    _to = target;
    _morph.forward(from: 0);
    _syncIdle();
  }

  /// Loops the idle motion of the current mood; one pass there and back is the mood's period.
  void _syncIdle() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _idle.stop();
      return;
    }
    final half = _to.idle.period ~/ 2;
    if (_idle.duration == half && _idle.isAnimating) return;
    _idle
      ..duration = half
      ..repeat(reverse: true);
  }

  void _cycleMood() => setState(() {
        _preview = HifdthMood.values[(_mood.index + 1) % HifdthMood.values.length];
        _morphTo(_mood);
      });

  @override
  void dispose() {
    _morph.dispose();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(HRadii.homeCard));
    final done = widget.steps.where((s) => s.done).length;

    return AnimatedBuilder(
      animation: _morph,
      builder: (context, _) {
        final style = _style;
        Widget hifdth = _Hifdth(style: style, from: _from.idle, to: _to.idle, morph: _morph.value, idle: _idle);
        if (kDebugMode) hifdth = GestureDetector(onLongPress: _cycleMood, child: hifdth);

        return ClipRRect(
          borderRadius: radius,
          child: CustomPaint(
            painter: style.background,
            child: Container(
              decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: style.border)),
              padding: const EdgeInsets.fromLTRB(13, 25, 13, 13), // design padding minus the 1 px border
              child: Column(
                children: [
                  hifdth,
                  const SizedBox(height: 16),
                  _StatusPill(text: style.status, dot: style.accent),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: HColors.surface,
                      borderRadius: BorderRadius.circular(HRadii.card),
                    ),
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text("TODAY'S PROGRESS",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: HText.inter(
                                      size: 12, weight: FontWeight.w600, letterSpacing: 0.6, color: HColors.ink2)),
                            ),
                            Semantics(
                              label: '$done of ${widget.steps.length} sessions done',
                              excludeSemantics: true,
                              child: Text.rich(TextSpan(
                                style: HText.inter(size: 14, weight: FontWeight.w700),
                                children: [
                                  TextSpan(text: '$done'),
                                  TextSpan(
                                    text: '/${widget.steps.length}',
                                    style: HText.inter(size: 14, weight: FontWeight.w500, color: HColors.inkMuted),
                                  ),
                                ],
                              )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        ExcludeSemantics(
                          child: SegmentedProgressBar(
                            fills: [for (final s in widget.steps) s.done ? 1 : 0],
                            color: style.accent,
                          ),
                        ),
                        const SizedBox(height: 14),
                        StepTimeline(steps: widget.steps),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The character with its glow. The idle motion blends from the old mood's to
/// the new one's while the morph runs.
class _Hifdth extends StatelessWidget {
  const _Hifdth({
    required this.style,
    required this.from,
    required this.to,
    required this.morph,
    required this.idle,
  });

  static const _box = 112.0;

  final MoodStyle style;
  final IdleMotion from, to;
  final double morph;
  final AnimationController idle;

  /// Vertical shift, rotation (radians) and vertical scale for [motion] at loop position [v] (0–1).
  static (double, double, double) _pose(IdleMotion motion, double v) => switch (motion) {
        IdleMotion.bounce => (-6 * v, 0, 1),
        IdleMotion.sway => (0, (2 * v - 1) * 3 * math.pi / 180, 1),
        IdleMotion.droop => (4 * v, 0, 1 - 0.03 * v),
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Hifdth assistant',
      child: SizedBox.square(
        dimension: _box,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -18,
              top: -18,
              right: -18,
              bottom: -18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [style.accent.withAlpha(0x47), const Color(0x00FFFFFF)], // 28%
                    stops: const [0, .7],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: idle,
                builder: (context, child) {
                  if (!idle.isAnimating) return child!;
                  final v = Curves.easeInOut.transform(idle.value);
                  final a = _pose(from, v), b = _pose(to, v);
                  final dy = lerpDouble(a.$1, b.$1, morph)!;
                  final turn = lerpDouble(a.$2, b.$2, morph)!;
                  final sy = lerpDouble(a.$3, b.$3, morph)!;
                  // Scale from the bottom so the droop sags instead of shrinking.
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.translationValues(0, dy + (1 - sy) * _box / 2, 0)
                      ..rotateZ(turn)
                      ..scaleByDouble(1, sy, 1, 1),
                    child: child,
                  );
                },
                child: CustomPaint(painter: HifdthPainter(style)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.dot});

  final String text;
  final Color dot;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(text, style: HText.inter(size: 13, weight: FontWeight.w500, color: HColors.pillInk)),
            ),
          ],
        ),
      );
}
