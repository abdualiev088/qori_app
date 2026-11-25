import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// What the "33 repetitions" method is, for the explainer and "How it works".
abstract final class Method33 {
  static const name = '33 repetitions';
  static const origin = 'Your Hifz plan';
  static const summary = 'Memorize the new portion in the evening for about an hour and sleep on it. On each of the '
      'next three mornings recite it 33 times from memory. Each lesson ends up with about 100 recitations spread '
      'over three days.';
  static const steps = [
    'Evening: memorize the new portion, about one hour, and make it the last thing you do.',
    'Morning 1: recite it 33 times from memory.',
    'Morning 2: another 33 times from memory.',
    "Morning 3: 33 more. That's about 100 recitations in three days.",
  ];
  static const tips = [
    'Finish the evening lesson before 22:00 so the mornings stay possible.',
    "Friday is a rest day: read the week's lessons once or twice.",
  ];
  static const minutes = 80;
  static const newShare = 50;
}

/// Small caps section label, as on Home ("TODAY'S PROGRESS").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(text, style: HText.inter(size: 12, weight: FontWeight.w600, letterSpacing: 0.6, color: HColors.ink2)),
      );
}

/// How it works, At a glance and Tips, stacked. [playing] runs the diagram.
class MethodDetails extends StatelessWidget {
  const MethodDetails({super.key, required this.playing, this.summary = false});

  final bool playing;

  /// Starts with the summary paragraph (inside "How it works").
  final bool summary;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (summary) ...[
            Text(Method33.summary, style: HText.inter(size: 14, height: 1.5, color: HColors.ink3)),
            const SizedBox(height: 16),
          ] else ...[
            const SectionLabel('HOW IT WORKS'),
            const SizedBox(height: 8),
          ],
          StepPlayer(playing: playing),
          const SizedBox(height: 18),
          const SectionLabel('AT A GLANCE'),
          const SizedBox(height: 8),
          const _Glance(),
          const SizedBox(height: 18),
          const SectionLabel('TIPS'),
          const SizedBox(height: 8),
          for (final (i, t) in Method33.tips.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 8, right: 8),
                decoration: const BoxDecoration(color: HColors.accent, shape: BoxShape.circle),
              ),
              Expanded(child: Text(t, style: HText.inter(size: 14, height: 1.45, color: HColors.ink3))),
            ]),
          ],
        ],
      );
}

// ---------------------------------------------------------------- the stepped diagram

/// The diagram, a numbered caption, dots and previous / play / next. While
/// [playing] it moves on every 2.6 s, never under Reduce Motion. Tapping a
/// control stops it.
class StepPlayer extends StatefulWidget {
  const StepPlayer({super.key, required this.playing});

  final bool playing;

  static const interval = Duration(milliseconds: 2600);

  @override
  State<StepPlayer> createState() => _StepPlayerState();
}

class _StepPlayerState extends State<StepPlayer> {
  int _step = 0;
  Timer? _timer;

  int get _count => Method33.steps.length;
  bool get _reduce => MediaQuery.disableAnimationsOf(context);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduce) {
      _stop();
    } else if (widget.playing && _timer == null) {
      _start();
    }
  }

  @override
  void didUpdateWidget(StepPlayer old) {
    super.didUpdateWidget(old);
    if (widget.playing == old.playing) return;
    widget.playing ? _start() : _stop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    if (_reduce || _timer != null) return;
    _timer = Timer.periodic(StepPlayer.interval, (_) => setState(() => _step = (_step + 1) % _count));
    setState(() {});
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    if (mounted) setState(() {});
  }

  void _go(int i) {
    _stop();
    setState(() => _step = (i + _count) % _count);
  }

  @override
  Widget build(BuildContext context) {
    final playing = _timer != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          image: true,
          label: '${Method33.name}, step ${_step + 1}: ${Method33.steps[_step]}',
          excludeSemantics: true,
          child: _Diagram(step: _step),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 42),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: HColors.accentDeep, shape: BoxShape.circle),
              child: Text('${_step + 1}',
                  style: HText.inter(size: 12, weight: FontWeight.w700, color: Colors.white, tabular: true)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: AnimatedSwitcher(
                  duration: _reduce ? Duration.zero : const Duration(milliseconds: 180),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  layoutBuilder: (current, previous) =>
                      Stack(alignment: Alignment.topLeft, children: [...previous, if (current != null) current]),
                  child: Text(Method33.steps[_step],
                      key: ValueKey(_step), style: HText.inter(size: 14, height: 1.45)),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _SquareButton(
            label: 'Previous step',
            onTap: _step == 0 && !playing ? null : () => _go(_step - 1),
            icon: Icons.chevron_left_rounded,
          ),
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < _count; i++)
                Semantics(
                  button: true,
                  selected: i == _step,
                  label: 'Step ${i + 1} of $_count',
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _go(i),
                    child: SizedBox(
                      width: 30,
                      height: 44,
                      child: Center(
                        child: AnimatedContainer(
                          duration: _reduce ? Duration.zero : const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          width: i == _step ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _step ? HColors.accentDeep : HColors.track,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
          if (!_reduce) ...[
            _SquareButton(
              label: playing ? 'Pause steps' : 'Play steps',
              onTap: playing ? _stop : _start,
              icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            const SizedBox(width: 6),
          ],
          _SquareButton(label: 'Next step', onTap: () => _go(_step + 1), icon: Icons.chevron_right_rounded),
        ]),
      ],
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.label, required this.onTap, required this.icon});

  final String label;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        enabled: onTap != null,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: HColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: HColors.track),
            ),
            child: Icon(icon, size: 22, color: onTap == null ? const Color(0xFFC3CAD1) : HColors.ink),
          ),
        ),
      );
}

/// Evening, then three mornings whose rings fill as each is reached.
class _Diagram extends StatelessWidget {
  const _Diagram({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    Widget day(String title, String sub, Widget inner, bool on) => Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 76),
            child: AnimatedOpacity(
              opacity: on ? 1 : 0.4,
              duration: reduce ? Duration.zero : const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                decoration: BoxDecoration(color: HColors.surface, borderRadius: BorderRadius.circular(14)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: HText.inter(size: 11, weight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  SizedBox.square(dimension: 46, child: inner),
                  const SizedBox(height: 6),
                  // Two lines' room, so every card is the same height.
                  SizedBox(
                    height: 26,
                    child: Text(sub,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: HText.inter(size: 10, height: 1.25, color: HColors.inkMuted)),
                  ),
                ]),
              ),
            ),
          ),
        );

    return Container(
      height: 178,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: HColors.bgTop, borderRadius: BorderRadius.circular(16)),
      child: Stack(children: [
        Align(
          alignment: Alignment.topCenter,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            day('Evening', 'learn · ~1 h', const Icon(Icons.nightlight_round, size: 26, color: HColors.accentDeep),
                true),
            for (var m = 1; m <= 3; m++) ...[
              const SizedBox(width: 8),
              day('Morning $m', 'from memory', _Ring(on: step >= m), step >= m),
            ],
          ]),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          // Rises in over 300 ms; leaves quicker (150 ms) when the steps loop back.
          child: AnimatedSlide(
            offset: step >= 3 ? Offset.zero : const Offset(0, 0.25),
            duration: reduce ? Duration.zero : Duration(milliseconds: step >= 3 ? 300 : 150),
            curve: step >= 3 ? Curves.easeOut : Curves.easeIn,
            child: AnimatedOpacity(
              opacity: step >= 3 ? 1 : 0,
              duration: reduce ? Duration.zero : Duration(milliseconds: step >= 3 ? 300 : 150),
              curve: step >= 3 ? Curves.easeOut : Curves.easeIn,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: HColors.mintWash, borderRadius: BorderRadius.circular(999)),
                child: Text('≈ 100 recitations',
                    style: HText.inter(size: 12, weight: FontWeight.w600, color: HColors.accentDeep)),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

/// A 46 px ring that fills over 700 ms when its morning is reached.
class _Ring extends StatelessWidget {
  const _Ring({required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: on ? 1 : 0),
        duration: !on || MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 700),
        curve: Curves.easeOut,
        builder: (context, v, _) => CustomPaint(
          painter: _RingPainter(v),
          child: Center(
            child: Text(on ? '33×' : '–', style: HText.inter(size: 11, weight: FontWeight.w700, tabular: true)),
          ),
        ),
      );
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
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, 2 * math.pi * value, false,
        paint
          ..color = HColors.accentDeep
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.value != value;
}

// ---------------------------------------------------------------- at a glance

class _Glance extends StatelessWidget {
  const _Glance();

  @override
  Widget build(BuildContext context) {
    Widget tile(String k, List<Widget> body, {String? label}) => Semantics(
          container: true,
          label: label,
          excludeSemantics: label != null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: HColors.bgTop, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(k, style: HText.inter(size: 11, weight: FontWeight.w600, letterSpacing: 0.4, color: HColors.inkMuted)),
              const SizedBox(height: 6),
              ...body,
            ]),
          ),
        );
    Widget value(String v) => Text(v, style: HText.inter(size: 13, weight: FontWeight.w600, height: 1.3));
    Widget bar(double share, Color color) => ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: ColoredBox(
              color: HColors.track,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: share,
                child: ColoredBox(color: color),
              ),
            ),
          ),
        );
    Widget pair(Widget a, Widget b) => IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(child: a),
            const SizedBox(width: 8),
            Expanded(child: b),
          ]),
        );

    const n = Method33.newShare;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      pair(
        tile('DAILY TIME', [value('${Method33.minutes} min'), const SizedBox(height: 6), bar(Method33.minutes / 120, HColors.accent)],
            label: 'Daily time: about ${Method33.minutes} minutes'),
        tile('EFFORT', [
          value('Demanding'),
          const SizedBox(height: 6),
          Row(children: [
            for (var i = 0; i < 3; i++)
              Container(
                width: 18,
                height: 6,
                margin: const EdgeInsets.only(right: 3),
                decoration: BoxDecoration(color: HColors.accentDeep, borderRadius: BorderRadius.circular(3)),
              ),
          ]),
        ], label: 'Effort: demanding'),
      ),
      const SizedBox(height: 8),
      tile('NEW VS REVISION', [
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: SizedBox(
            height: 6,
            child: Row(children: [
              const Expanded(flex: n, child: ColoredBox(color: HColors.accent)),
              const SizedBox(width: 2),
              const Expanded(flex: 100 - n, child: ColoredBox(color: HColors.revision)),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: '$n%', style: HText.inter(size: 11, weight: FontWeight.w600, color: HColors.accentDeep)),
            TextSpan(text: ' new', style: HText.inter(size: 11, weight: FontWeight.w500, color: HColors.ink2)),
          ])),
          Text.rich(TextSpan(children: [
            TextSpan(text: 'revision ', style: HText.inter(size: 11, weight: FontWeight.w500, color: HColors.ink2)),
            TextSpan(text: '${100 - n}%', style: HText.inter(size: 11, weight: FontWeight.w600, color: HColors.revision)),
          ])),
        ]),
      ], label: '$n% new memorizing, ${100 - n}% revision'),
      const SizedBox(height: 8),
      pair(
        tile('TEACHER', [
          Row(children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: HColors.surface, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.person_outline_rounded, size: 18, color: HColors.inkMuted),
            ),
            const SizedBox(width: 8),
            Flexible(child: value('On your own')),
          ]),
        ], label: 'Teacher: on your own'),
        tile('BEST FOR', [value('Disciplined learners with free evenings')]),
      ),
      const SizedBox(height: 8),
      tile('WHAT YOU USE', [
        Row(children: [
          for (final (label, icon, on) in const [
            ('Listening', Icons.headphones_rounded, false),
            ('Seeing', Icons.visibility_outlined, false),
            ('Reciting', Icons.record_voice_over_outlined, true),
            ('Writing', Icons.edit_outlined, false),
          ])
            Expanded(
              child: Column(children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: on ? HColors.mintWash : HColors.surface,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, size: 18, color: on ? HColors.accentDeep : const Color(0xFFB4BCC5)),
                ),
                const SizedBox(height: 3),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HText.inter(size: 10, weight: FontWeight.w500, color: on ? HColors.ink : HColors.inkMuted)),
              ]),
            ),
        ]),
      ], label: 'Uses reciting'),
    ]);
  }
}
