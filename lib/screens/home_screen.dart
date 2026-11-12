import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/glass.dart';
import '../widgets/progress_indicators.dart';
import '../widgets/ribbed_glass.dart';

// Placeholder data, as in the design.
const _steps = [
  DayStep(title: 'Morning session', subtitle: 'Done at 6:30 am', done: true),
  DayStep(title: 'Review', subtitle: 'Done at 10:30 am', done: true),
  DayStep(title: 'Evening session', subtitle: 'Up next · 7:00 pm', done: false),
];
const _week = [
  StreakDay('M', true),
  StreakDay('T', true),
  StreakDay('W', true),
  StreakDay('T', true),
  StreakDay('F', true),
  StreakDay('S', false),
  StreakDay('S', false),
];

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.bottomInset, this.now});

  /// Space reserved under the content for the floating nav.
  final double bottomInset;

  /// Overrides the clock (tests).
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final t = now ?? DateTime.now();
    final greeting = t.hour < 12 ? 'Good morning' : (t.hour < 18 ? 'Good afternoon' : 'Good evening');
    final top = MediaQuery.paddingOf(context).top + 9;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, top < 56 ? 56 : top, 20, bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${_weekdays[t.weekday - 1]}, ${t.day} ${_months[t.month - 1]}',
                        style: HText.inter(size: 13, weight: FontWeight.w500, color: HColors.ink2)),
                    const SizedBox(height: 2),
                    Text(greeting, style: HText.inter(size: 24, weight: FontWeight.w700, letterSpacing: -0.4)),
                  ],
                ),
              ),
              GlassProfileButton(onTap: () {}),
            ],
          ),
          const SizedBox(height: 18),
          const _MainCard(),
          const SizedBox(height: 18),
          const IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _GoalCard(value: 0.67, caption: '1 session left')),
                SizedBox(width: 12),
                Expanded(child: _StreakCard(days: _week)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MainCard extends StatelessWidget {
  const _MainCard();

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(HRadii.homeCard));
    final done = _steps.where((s) => s.done).length;
    return ClipRRect(
      borderRadius: radius,
      child: CustomPaint(
        painter: RibbedGlassPainter.home,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: const Color(0xFFDDEEE4)),
          ),
          padding: const EdgeInsets.fromLTRB(13, 25, 13, 13), // design padding minus the 1 px border
          child: Column(
            children: [
              const HifdthOrb(),
              const SizedBox(height: 16),
              const _StatusPill(text: 'Hifdth is checking your day…'),
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
                          label: '$done of ${_steps.length} sessions done',
                          excludeSemantics: true,
                          child: Text.rich(TextSpan(
                            style: HText.inter(size: 14, weight: FontWeight.w700),
                            children: [
                              TextSpan(text: '$done'),
                              TextSpan(
                                text: '/${_steps.length}',
                                style: HText.inter(size: 14, weight: FontWeight.w500, color: HColors.inkMuted),
                              ),
                            ],
                          )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ExcludeSemantics(
                      child: SegmentedProgressBar(fills: [for (final s in _steps) s.done ? 1 : 0]),
                    ),
                    const SizedBox(height: 14),
                    const StepTimeline(steps: _steps),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The green assistant orb with its two eyes.
class HifdthOrb extends StatelessWidget {
  const HifdthOrb({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Hifdth assistant',
      child: SizedBox.square(
        dimension: 112,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            const Positioned(
              left: -18,
              top: -18,
              right: -18,
              bottom: -18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [HColors.accentGlow, Color(0x00FFFFFF)], stops: [0, .7]),
                ),
              ),
            ),
            Container(
              width: 104,
              height: 104,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment(-0.3, -0.44),
                  radius: 0.97,
                  colors: [Color(0xFFB8F5CF), HColors.accent, HColors.orbDeep],
                  stops: [0, .45, 1],
                ),
                boxShadow: [BoxShadow(color: HColors.accentShadow, offset: Offset(0, 14), blurRadius: 30)],
              ),
              foregroundDecoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)],
                  stops: [0, .3],
                ),
              ),
              padding: const EdgeInsets.only(top: 22),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [_Eye(), SizedBox(width: 16), _Eye()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Eye extends StatelessWidget {
  const _Eye();

  @override
  Widget build(BuildContext context) => Container(
        width: 9,
        height: 18,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(5)),
      );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});

  final String text;

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
              decoration: const BoxDecoration(color: HColors.accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(text, style: HText.inter(size: 13, weight: FontWeight.w500, color: HColors.pillInk)),
            ),
          ],
        ),
      );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.value, required this.caption});

  final double value;
  final String caption;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: HColors.surface, borderRadius: BorderRadius.circular(HRadii.card)),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ProgressRing(value: value),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily goal', style: HText.inter(size: 14, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(caption, style: HText.inter(size: 12, color: HColors.ink2)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.days});

  final List<StreakDay> days;

  @override
  Widget build(BuildContext context) {
    final streak = days.where((d) => d.done).length;
    return Container(
      decoration: BoxDecoration(color: HColors.surface, borderRadius: BorderRadius.circular(HRadii.card)),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text('Streak',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: HText.inter(size: 14, weight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
              Text('$streak days', style: HText.inter(size: 12, color: HColors.ink2)),
            ],
          ),
          const SizedBox(height: 10),
          StreakBars(days: days),
        ],
      ),
    );
  }
}
