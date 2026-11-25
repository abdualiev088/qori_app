import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/tokens.dart';
import 'icons.dart';
import '../l10n/l10n.dart';

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
      label: context.l10n.dailyGoal(pct),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(value, stroke),
          // Three digits get a size smaller, so "100%" clears the ring.
          child: Center(
              child: Text('$pct%',
                  style: HText.inter(size: pct >= 100 ? 12 : 14, weight: FontWeight.w700, tabular: true))),
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
  const DayStep(
      {required this.title, required this.subtitle, required this.done, this.time, this.morning, this.tags = const []});

  final String title;

  /// Read aloud (and shown on read-only steps).
  final String subtitle;
  final bool done;

  /// "Morning", "Evening": read aloud with the step.
  final String? time;

  /// Plan tasks: true for the morning (sun tile), false for the evening (moon tile).
  final bool? morning;

  /// Short facts under the title of a plan task; the first takes the time of day's color.
  final List<String> tags;
}

/// The day's steps. Read-only steps show a 34 px icon (check when done,
/// sparkle when pending) joined by connectors. With [onToggle] they're plan
/// tasks: a sun or moon tile, the ayahs, a few tags and a checkbox, and the
/// whole row ticks and unticks.
class StepTimeline extends StatelessWidget {
  const StepTimeline({super.key, required this.steps, this.onToggle});

  final List<DayStep> steps;
  final ValueChanged<int>? onToggle;

  @override
  Widget build(BuildContext context) {
    final toggle = onToggle;
    if (toggle != null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        for (final (i, s) in steps.indexed) ...[
          if (i > 0) const Divider(height: 1, thickness: 1, color: HColors.divider),
          _TaskRow(
              step: s,
              onTap: () {
                if (!s.done) HapticFeedback.lightImpact();
                toggle(i);
              }),
        ],
      ]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, s) in steps.indexed) ...[
          if (i > 0) const SizedBox(height: 4),
          Semantics(
            label: '${s.title}, ${s.done ? context.l10n.taskDone : context.l10n.taskPending}. ${s.subtitle}',
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
                      Container(width: 2, height: 14, color: steps[i + 1].done ? HColors.mintLight : HColors.divider),
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

/// One plan task: [time tile] ayahs / tags [checkbox].
class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.step, required this.onTap});

  final DayStep step;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = step;
    final morning = s.morning ?? false;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final fade = reduce ? Duration.zero : const Duration(milliseconds: 160);
    return Semantics(
      button: true,
      checked: s.done,
      label: '${s.time == null ? '' : '${s.time}. '}${s.title}. ${s.subtitle}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(children: [
            AnimatedOpacity(
              opacity: s.done ? 0.55 : 1,
              duration: fade,
              curve: Curves.easeOut,
              child: TimeTile(morning: morning),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                AnimatedDefaultTextStyle(
                  duration: fade,
                  curve: Curves.easeOut,
                  style: HText.inter(size: 15, weight: FontWeight.w600, color: s.done ? HColors.inkMuted : HColors.ink),
                  // Non-breaking hyphens keep names like "Al-Falaq" on one line.
                  child: Text(s.title.replaceAll('-', '\u2011')),
                ),
                if (s.tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    for (final (i, t) in s.tags.indexed) _Tag(t, tone: i == 0 ? morning : null),
                  ]),
                ],
              ]),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: fade,
              curve: Curves.easeOut,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: s.done ? HColors.accentDeep : HColors.surface,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: s.done ? HColors.accentDeep : const Color(0xFFC9D2CC), width: 1.5),
              ),
              alignment: Alignment.center,
              child: AnimatedScale(
                scale: s.done ? 1 : 0.6,
                duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                child: AnimatedOpacity(
                  opacity: s.done ? 1 : 0,
                  duration: fade,
                  child: HIcon.check(Colors.white, size: 16, width: 2.6),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

/// A small tag. With a [tone] (true morning, false evening) it takes that
/// time of day's colors; otherwise it's neutral.
class _Tag extends StatelessWidget {
  const _Tag(this.text, {this.tone});

  final String text;
  final bool? tone;

  @override
  Widget build(BuildContext context) {
    final (bg, ink) = switch (tone) {
      true => (HColors.morningSoft, HColors.morningInk),
      false => (HColors.eveningSoft, HColors.eveningInk),
      null => (HColors.bgTop, HColors.ink2),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text,
          style: HText.inter(
              size: 12, weight: tone == null ? FontWeight.w500 : FontWeight.w600, color: ink, tabular: true)),
    );
  }
}

/// The time of day as a glossy 40 px tile: a sun on a sunrise gradient, or a
/// moon and a star on a night one.
class TimeTile extends StatelessWidget {
  const TimeTile({super.key, required this.morning, this.size = 40});

  final bool morning;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = morning ? HColors.morning : HColors.evening;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
          stops: const [0, .5, 1],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        boxShadow: [BoxShadow(color: colors.last.withValues(alpha: 0.28), offset: const Offset(0, 4), blurRadius: 10)],
      ),
      child: Stack(alignment: Alignment.center, children: [
        Icon(morning ? Icons.wb_sunny_rounded : Icons.nightlight_round, size: size * 0.5, color: Colors.white),
        if (!morning)
          Positioned(
            right: size * 0.18,
            top: size * 0.16,
            child: Icon(Icons.star_rounded, size: size * 0.2, color: Colors.white.withValues(alpha: 0.85)),
          ),
      ]),
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
      label: context.l10n.weekComplete(done, days.length),
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
                  // Always as tall as a done day's bar, so the card keeps its height
                  // in a week with nothing done yet.
                  SizedBox(
                    height: 28,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: d.done ? 28 : 10,
                        decoration: BoxDecoration(
                          color: d.done ? HColors.accent : HColors.track,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(d.label,
                      style: HText.inter(size: 12, height: 1.1, weight: FontWeight.w500, color: HColors.ink2)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
