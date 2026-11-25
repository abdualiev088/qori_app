import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../l10n/l10n.dart';

/// What the "33 repetitions" method is, for the explainer and "How it works".
/// The words come from the app's language; only the numbers live here.
abstract final class Method33 {
  static List<String> steps(AppLocalizations l) => [l.step1, l.step2, l.step3, l.step4];
  static List<String> tips(AppLocalizations l) => [l.tip1, l.tip2];
  static const stepCount = 4;
  static const minutes = 80;
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

/// The stepped diagram, At a glance (three facts) and Tips. [playing] runs
/// the diagram; [heading] puts "HOW IT WORKS" above it (the first-visit explainer).
class MethodDetails extends StatelessWidget {
  const MethodDetails({super.key, required this.playing, this.heading = true});

  final bool playing;
  final bool heading;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (heading) ...[
            SectionLabel(context.l10n.howItWorksCaps),
            const SizedBox(height: 8),
          ],
          StepPlayer(playing: playing),
          const SizedBox(height: 20),
          SectionLabel(context.l10n.atAGlanceCaps),
          const SizedBox(height: 8),
          const _Glance(),
          const SizedBox(height: 20),
          SectionLabel(context.l10n.tipsCaps),
          const SizedBox(height: 8),
          for (final (i, t) in Method33.tips(context.l10n).indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 8, right: 10),
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

  int get _count => Method33.stepCount;
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
          label: context.l10n.stepLabel(context.l10n.methodName, _step + 1, Method33.steps(context.l10n)[_step]),
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
                  child: Text(Method33.steps(context.l10n)[_step],
                      key: ValueKey(_step), style: HText.inter(size: 14, height: 1.45)),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _SquareButton(
            label: context.l10n.previousStep,
            onTap: _step == 0 && !playing ? null : () => _go(_step - 1),
            icon: Icons.chevron_left_rounded,
          ),
          Expanded(
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < _count; i++)
                Semantics(
                  button: true,
                  selected: i == _step,
                  label: context.l10n.stepNOfM(i + 1, _count),
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
              label: playing ? context.l10n.pauseSteps : context.l10n.playSteps,
              onTap: playing ? _stop : _start,
              icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            ),
            const SizedBox(width: 6),
          ],
          _SquareButton(label: context.l10n.nextStep, onTap: () => _go(_step + 1), icon: Icons.chevron_right_rounded),
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
            day(context.l10n.evening, context.l10n.learnAboutHour, const Icon(Icons.nightlight_round, size: 26, color: HColors.accentDeep),
                true),
            for (var m = 1; m <= 3; m++) ...[
              const SizedBox(width: 8),
              day(context.l10n.morningN(m), context.l10n.fromMemory, _Ring(on: step >= m), step >= m),
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
                child: Text(context.l10n.about100,
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

/// Three facts side by side: time a day, effort, and no teacher needed.
class _Glance extends StatelessWidget {
  const _Glance();

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String value, String label) => Expanded(
          child: Semantics(
            container: true,
            label: '$value, $label',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              decoration: BoxDecoration(color: HColors.bgTop, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(color: HColors.mintWash, borderRadius: BorderRadius.circular(9)),
                  child: Icon(icon, size: 16, color: HColors.accentDeep),
                ),
                const SizedBox(height: 8),
                Text(value, maxLines: 1, style: HText.inter(size: 14, weight: FontWeight.w700, tabular: true)),
                Text(label, maxLines: 1, style: HText.inter(size: 11, weight: FontWeight.w500, color: HColors.inkMuted)),
              ]),
            ),
          ),
        );
    return Row(children: [
      tile(Icons.schedule_rounded, context.l10n.minutesShort(Method33.minutes), context.l10n.aDay),
      const SizedBox(width: 8),
      tile(Icons.bolt_rounded, context.l10n.demanding, context.l10n.effort),
      const SizedBox(width: 8),
      tile(Icons.person_outline_rounded, context.l10n.solo, context.l10n.noTeacher),
    ]);
  }
}
