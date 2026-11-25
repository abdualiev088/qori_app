import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'hifdth_mood.dart';
import 'hifdth_painter.dart';
import 'progress_indicators.dart';
import 'ribbed_glass.dart';

/// Home's main card: Hifdth, the status pill and today's progress on a ribbed
/// background. Everything follows [mood] and morphs when it changes.
class HifdthCard extends StatefulWidget {
  const HifdthCard({
    super.key,
    required this.mood,
    this.steps = const [],
    this.characterAway = false,
    this.title = "TODAY'S PROGRESS",
    this.subtitle,
    this.status,
    this.onToggle,
    this.empty,
  });

  final HifdthMood mood;
  final List<DayStep> steps;

  /// The white panel's label, and the line under it ("Day 4 of 50").
  final String title;
  final String? subtitle;

  /// Replaces the mood's pill text (no plan, rest day, all done).
  final String? status;

  /// Makes the steps checkboxes.
  final ValueChanged<int>? onToggle;

  /// Shown in place of the steps when there are none (no plan, rest day…).
  final Widget? empty;

  /// Hides the character (keeping its space) while it's somewhere else on screen.
  final bool characterAway;

  /// How far the character's top edge sits below the card's top (border and padding).
  static const characterTop = 1 + 25.0;

  /// The character's box; it's centered horizontally in the card.
  static const characterSize = _Hifdth._box;

  @override
  State<HifdthCard> createState() => _HifdthCardState();
}

class _HifdthCardState extends State<HifdthCard> with TickerProviderStateMixin {
  late final _morph = AnimationController(vsync: this, duration: const Duration(milliseconds: 500), value: 1);
  late final _idle = AnimationController(vsync: this);
  late final _shimmer = AnimationController(vsync: this, duration: const Duration(seconds: 7));

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
    if (MediaQuery.disableAnimationsOf(context)) {
      _shimmer.stop();
    } else if (!_shimmer.isAnimating) {
      _shimmer.repeat();
    }
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
    _shimmer.dispose();
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
        if (widget.characterAway) hifdth = Opacity(opacity: 0, child: ExcludeSemantics(child: hifdth));

        return ClipRRect(
          borderRadius: radius,
          child: CustomPaint(
            painter: RibbedShimmerPainter(fill: style.background, phase: _shimmer),
            child: Container(
              decoration: BoxDecoration(borderRadius: radius, border: Border.all(color: style.border)),
              padding: const EdgeInsets.fromLTRB(13, 25, 13, 13), // design padding minus the 1 px border
              child: Column(
                children: [
                  hifdth,
                  const SizedBox(height: 16),
                  _StatusPill(text: widget.status ?? style.status, dot: style.accent),
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
                          children: [
                            Expanded(
                              child: Text(widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: HText.inter(
                                      size: 12, weight: FontWeight.w600, letterSpacing: 0.6, color: HColors.ink2)),
                            ),
                            // "Day 4/50" as a small chip; the bar and the ticks show today's progress.
                            if (widget.subtitle case final sub?)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration:
                                    BoxDecoration(color: HColors.bgTop, borderRadius: BorderRadius.circular(999)),
                                child: Text(sub,
                                    style: HText.inter(
                                        size: 12, weight: FontWeight.w600, color: HColors.ink2, tabular: true)),
                              ),
                          ],
                        ),
                        if (widget.steps.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Semantics(
                            label: '$done of ${widget.steps.length} done',
                            excludeSemantics: true,
                            child: SegmentedProgressBar(
                              fills: [for (final s in widget.steps) s.done ? 1 : 0],
                              color: style.accent,
                            ),
                          ),
                          SizedBox(height: widget.onToggle == null ? 14 : 4),
                          StepTimeline(steps: widget.steps, onToggle: widget.onToggle),
                        ] else if (widget.empty case final empty?) ...[
                          const SizedBox(height: 12),
                          empty,
                        ],
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

/// Hifdth on its own at [size], with the mood's idle motion. Used for the
/// small Hifdth that follows the screen on Home.
class HifdthAvatar extends StatefulWidget {
  const HifdthAvatar({super.key, required this.mood, this.size = 56, this.look = 0, this.speaking = false});

  final HifdthMood mood;
  final double size;

  /// Where Hifdth looks: -1 left, 0 ahead. Changes glide over 320 ms.
  final double look;

  /// Blue while it talks to the user; the color shifts over 280 ms.
  final bool speaking;

  @override
  State<HifdthAvatar> createState() => _HifdthAvatarState();
}

class _HifdthAvatarState extends State<HifdthAvatar> with SingleTickerProviderStateMixin {
  late final _idle = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncIdle();
  }

  @override
  void didUpdateWidget(HifdthAvatar old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) _syncIdle();
  }

  void _syncIdle() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _idle.stop();
      return;
    }
    final half = MoodStyle.of(widget.mood).idle.period ~/ 2;
    if (_idle.duration == half && _idle.isAnimating) return;
    _idle
      ..duration = half
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = MoodStyle.of(widget.mood);
    final reduce = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: widget.size,
      child: FittedBox(
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: widget.speaking ? 1 : 0),
          duration: reduce ? Duration.zero : const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          builder: (context, blue, _) {
            final style = blue == 0 ? mood : MoodStyle.lerp(mood, mood.speaking(), blue);
            return TweenAnimationBuilder<double>(
              tween: Tween(end: widget.look),
              duration: reduce ? Duration.zero : const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              builder: (context, look, _) =>
                  _Hifdth(style: style, from: style.idle, to: style.idle, morph: 1, idle: _idle, look: look),
            );
          },
        ),
      ),
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
    this.look = 0,
  });

  static const _box = 112.0;

  final MoodStyle style;
  final IdleMotion from, to;
  final double morph;
  final AnimationController idle;
  final double look;

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
                child: CustomPaint(painter: HifdthPainter(style, look: look)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The status line under Hifdth. When the text changes (a task ticked, the
/// mood shifting) the new words stream in one after another, like the speech
/// bubble's, and the pill eases to its new width. The first text just shows.
class _StatusPill extends StatefulWidget {
  const _StatusPill({required this.text, required this.dot});

  final String text;
  final Color dot;

  @override
  State<_StatusPill> createState() => _StatusPillState();
}

class _StatusPillState extends State<_StatusPill> with SingleTickerProviderStateMixin {
  /// A new word starts this often; each one fades in over [_fade] (the bubble's timing).
  static const _step = 55;
  static const _fade = 160;

  List<String> get _words => widget.text.split(' ');
  int get _total => (_words.length - 1) * _step + _fade;

  late final _typing = AnimationController(vsync: this, duration: Duration(milliseconds: _total), value: 1);

  @override
  void didUpdateWidget(_StatusPill old) {
    super.didUpdateWidget(old);
    if (old.text == widget.text) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _typing.value = 1;
    } else {
      _typing
        ..duration = Duration(milliseconds: _total)
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    _typing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final style = HText.inter(size: 13, weight: FontWeight.w500, color: HColors.pillInk);
    return Semantics(
      liveRegion: true,
      label: widget.text,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(999),
        ),
        child: AnimatedSize(
          duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: widget.dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: AnimatedBuilder(
                  animation: _typing,
                  builder: (context, _) {
                    final ms = _typing.value * _total;
                    final words = _words;
                    // Words not written yet are laid out but clear, so nothing reflows while it types.
                    return Text.rich(
                      TextSpan(style: style, children: [
                        for (var i = 0; i < words.length; i++)
                          TextSpan(
                            text: i < words.length - 1 ? '${words[i]} ' : words[i],
                            style: TextStyle(
                              color: HColors.pillInk.withValues(
                                alpha: Curves.easeOut.transform(((ms - i * _step) / _fade).clamp(0.0, 1.0)),
                              ),
                            ),
                          ),
                      ]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
