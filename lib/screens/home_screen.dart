import 'package:flutter/material.dart';

import '../data/surahs.dart';
import '../theme/tokens.dart';
import '../widgets/glass.dart';
import '../widgets/hifdth_card.dart';
import '../widgets/hifdth_mood.dart';
import '../widgets/progress_indicators.dart';
import '../widgets/quran_progress_card.dart';

// Placeholder data, as in the design.
const _steps = [
  DayStep(title: 'Morning session', subtitle: 'Done at 6:30 am', done: true),
  DayStep(title: 'Review', subtitle: 'Done at 10:30 am', done: true),
  DayStep(title: 'Evening session', subtitle: 'Up next · 7:00 pm', done: false),
];
/// Sessions whose time has passed without being done. Placeholder until the schedule is real.
const _sessionsBehind = 0;
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
      padding: EdgeInsets.fromLTRB(16, top < 56 ? 56 : top, 16, bottomInset),
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
          HifdthCard(mood: moodFor(sessionsBehind: _sessionsBehind), steps: _steps),
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
          const SizedBox(height: 18),
          const _QuranProgress(),
        ],
      ),
    );
  }
}

/// The Player only has Al-Qalam (surah 68) for now, so the grid starts there.
const _playerSurahIndex = 67;

/// Holds the selected surah for [QuranProgressCard].
class _QuranProgress extends StatefulWidget {
  const _QuranProgress();

  @override
  State<_QuranProgress> createState() => _QuranProgressState();
}

class _QuranProgressState extends State<_QuranProgress> {
  // Placeholder progress until memorization is tracked.
  final _surahs = sampleSurahProgress();
  int _selected = _playerSurahIndex;

  @override
  Widget build(BuildContext context) => QuranProgressCard(
        surahs: _surahs,
        selected: _selected,
        onSelect: (i) => setState(() => _selected = i),
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
