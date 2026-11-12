import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'icons.dart';

/// A row of equal segments, each filled 0–1. Used for today's sessions (6 px)
/// and the player's per-repetition progress (4 px).
class SegmentedProgressBar extends StatelessWidget {
  const SegmentedProgressBar({
    super.key,
    required this.fills,
    this.height = 6,
    this.gap = 6,
    this.color = HColors.accent,
    this.trackColor = HColors.track,
  });

  final List<double> fills;
  final double height;
  final double gap;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    return Row(
      children: [
        for (final (i, f) in fills.indexed) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: ClipRRect(
              borderRadius: radius,
              child: SizedBox(
                height: height,
                child: ColoredBox(
                  color: trackColor,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: f.clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: ColoredBox(color: color),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Circular goal ring: 60 px, 6 px stroke, rounded cap, starting at 12 o'clock.
class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, this.size = 60, this.stroke = 6});

  final double value;
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final pct = (value * 100).round();
    return Semantics(
      label: 'Daily goal $pct percent',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(value, stroke),
          child: Center(child: Text('$pct%', style: HText.inter(size: 14, weight: FontWeight.w700))),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.value, this.stroke);

  final double value;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (size.shortestSide - stroke) / 2 - 1; // r = 26 in a 60 px box
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
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
  bool shouldRepaint(_RingPainter old) => old.value != value || old.stroke != stroke;
}

class DayStep {
  const DayStep({required this.title, required this.subtitle, required this.done});

  final String title;
  final String subtitle;
  final bool done;
}

/// Vertical list of steps: 34 px rounded icon (check when done, sparkle when
/// pending) joined by 2 px connectors.
class StepTimeline extends StatelessWidget {
  const StepTimeline({super.key, required this.steps});

  final List<DayStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, s) in steps.indexed) ...[
          if (i > 0) const SizedBox(height: 4),
          Semantics(
            label: '${s.title}, ${s.done ? 'done' : 'pending'}. ${s.subtitle}',
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: s.done ? HColors.mintLight : HColors.divider,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: s.done ? HIcon.check(HColors.accentDeep) : HIcon.sparkle(HColors.ink2),
                    ),
                    if (i < steps.length - 1)
                      Container(
                        width: 2,
                        height: 14,
                        color: steps[i + 1].done ? HColors.mintLight : HColors.divider,
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title, style: HText.inter(size: 15, weight: FontWeight.w600)),
                        const SizedBox(height: 3),
                        Text(s.subtitle, style: HText.inter(size: 13, color: HColors.ink2)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class StreakDay {
  const StreakDay(this.label, this.done);

  final String label;
  final bool done;
}

/// Seven day bars: 28 px accent when done, 10 px track when not.
class StreakBars extends StatelessWidget {
  const StreakBars({super.key, required this.days});

  final List<StreakDay> days;

  @override
  Widget build(BuildContext context) {
    final done = days.where((d) => d.done).length;
    return Semantics(
      label: 'This week: $done of ${days.length} days complete',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (i, d) in days.indexed) ...[
            if (i > 0) const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: d.done ? 28 : 10,
                    decoration: BoxDecoration(
                      color: d.done ? HColors.accent : HColors.track,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(d.label, style: HText.inter(size: 10, weight: FontWeight.w500, color: HColors.ink2)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
