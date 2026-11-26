import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/auth_api.dart';
import '../data/learned_store.dart';
import '../data/plan.dart';
import '../data/plan_store.dart';
import '../data/surahs.dart';
import '../theme/tokens.dart';
import '../widgets/auth_widgets.dart' show PrimaryButton;
import '../widgets/glass.dart';
import '../widgets/day_calendar.dart';
import '../widgets/hifdth_card.dart';
import '../widgets/hifdth_mood.dart';
import '../widgets/learned_sheet.dart';
import '../l10n/plan_text.dart';
import '../widgets/mushaf_icon.dart';
import '../widgets/progress_indicators.dart';
import '../widgets/quran_progress_card.dart';
import '../widgets/signed_out_card.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/toast.dart';
import 'account_screen.dart';
import 'auth_screen.dart';
import '../l10n/l10n.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen(
      {super.key,
      required this.bottomInset,
      required this.learned,
      this.now,
      this.auth,
      this.plans,
      this.onOpenMethod});

  /// The memorization plan and its ticks. Without it Home shows "No plan yet".
  final PlanStore? plans;

  /// Opens the My Method tab (set up or change the plan).
  final VoidCallback? onOpenMethod;

  /// Which ayahs are learned; the Quran progress card follows it.
  final LearnedStore learned;

  /// Sign-in calls (the signed-out card's buttons). Without it (tests) Home acts signed in.
  final AuthApi? auth;

  /// Space reserved under the content for the floating nav.
  final double bottomInset;

  /// Overrides the clock (tests).
  final DateTime? now;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  /// Signed in to a real account. Without an account connection (tests), Home
  /// behaves as signed in.
  bool get _signedIn => widget.auth?.signedIn ?? true;

  /// Signing out stops Hifdth's question (it asks to tap a surah); the Quran
  /// progress card redraws as the signed-out card or back.
  void _authChanged() {
    if (!mounted) return;
    if (!_signedIn) _hush();
    setState(() {});
  }

  void _openAuth() {
    final auth = widget.auth;
    if (auth == null) return;
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => auth.signedIn ? AccountScreen(api: auth) : AuthScreen(api: auth),
    ));
  }

  final _scroll = ScrollController();
  final _cardKey = GlobalKey();
  final _quranKey = GlobalKey();
  final _hintKey = GlobalKey();

  /// 0: Hifdth sits in its card. 1: it has landed in the bottom-right corner.
  /// In between it's flying, and the card's own character is hidden.
  late final _fly = AnimationController(vsync: this, duration: _flyDown, reverseDuration: _flyBack)
    ..addStatusListener(_flightChanged);

  /// Down to the corner, and a little quicker back into the card.
  static const _flyDown = Duration(milliseconds: 560);
  static const _flyBack = Duration(milliseconds: 460);

  /// Where Hifdth should be: down in the corner once its card spot reaches the top edge.
  bool _down = false;
  bool _talking = false;

  /// Half the Quran card is in view: Hifdth looks at it and asks.
  bool _atQuran = false;
  Timer? _quiet;

  static const _miniSize = 56.0;

  /// The floating top bar's height (the glass pill and buttons).
  static const _barHeight = 46.0;

  /// The corner spot's bottom edge, above Home's bottom. Hifdth's middle lines
  /// up with the card's hint line when the page is scrolled to the end; this
  /// fallback is replaced once the card has been laid out.
  double _cornerBottom = 180;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_followScroll);
    widget.auth?.addListener(_authChanged);
    widget.plans?.addListener(_planChanged);
  }

  void _planChanged() {
    if (mounted) setState(() {});
  }

  DateTime get _now => widget.now ?? DateTime.now();

  /// The day the calendar shows; null means today (so it rolls over at midnight).
  DateTime? _picked;

  /// -1 if the last move went back in time, 1 forward: new days slide in from that side.
  int _dir = 1;

  DateTime get _shown => _picked ?? dateOnly(_now);

  void _show(DateTime day) {
    final d = dateOnly(day);
    if (d == _shown) return;
    setState(() {
      _dir = d.isAfter(_shown) ? 1 : -1;
      _picked = d == dateOnly(_now) ? null : d;
    });
  }

  Future<void> _openMonth() async {
    final store = widget.plans;
    if (store == null) return;
    final now = _now;
    final picked = await MonthCalendarSheet.show(
      context,
      selected: _shown,
      now: now,
      stateOf: (d) => store.dayState(d, now),
    );
    if (picked != null && mounted) _show(picked);
  }

  /// Ticks or unticks today's task [i]; finishing the day says well done.
  Future<void> _toggle(List<PlanTask> tasks, int i) async {
    final store = widget.plans;
    if (store == null) return;
    final now = _now;
    final wasDone = store.allDone(now, now);
    await store.toggle(now, tasks[i].id);
    if (!wasDone && store.allDone(now, now) && mounted) Toast.show(context, context.l10n.planDoneToast);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    _fly
      ..duration = reduce ? Duration.zero : _flyDown
      ..reverseDuration = reduce ? Duration.zero : _flyBack;
  }

  @override
  void dispose() {
    widget.auth?.removeListener(_authChanged);
    widget.plans?.removeListener(_planChanged);
    _quiet?.cancel();
    _fly.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Top of the card's character in Home's coordinates, or null before layout.
  double? _cardCharacterTop() {
    final box = _cardKey.currentContext?.findRenderObject() as RenderBox?;
    final home = context.findRenderObject() as RenderBox?;
    if (box == null || home == null || !box.attached) return null;
    return box.localToGlobal(const Offset(0, HifdthCard.characterTop), ancestor: home).dy;
  }

  /// Where the hint's middle sits above the Quran card's bottom edge, or null before layout.
  double? _hintAboveCardBottom() {
    final card = _quranKey.currentContext?.findRenderObject() as RenderBox?;
    final hint = _hintKey.currentContext?.findRenderObject() as RenderBox?;
    if (card == null || hint == null || !card.attached || !hint.attached) return null;
    final cardBottom = card.localToGlobal(Offset(0, card.size.height)).dy;
    return cardBottom - hint.localToGlobal(hint.size.center(Offset.zero)).dy;
  }

  /// At the end of the page the card's bottom sits [HomeScreen.bottomInset] above Home's bottom.
  void _placeCorner() {
    final lift = _hintAboveCardBottom();
    if (lift == null) return;
    final bottom = widget.bottomInset + lift - _miniSize / 2;
    if ((bottom - _cornerBottom).abs() > 0.5) setState(() => _cornerBottom = bottom);
  }

  void _followScroll() {
    final top = _cardCharacterTop();
    if (top == null) return;
    final down = top < MediaQuery.paddingOf(context).top;
    if (down != _down) {
      _down = down;
      if (down) {
        _fly.forward();
      } else {
        _fly.reverse();
      }
    }

    final card = _quranKey.currentContext?.findRenderObject() as RenderBox?;
    final home = context.findRenderObject() as RenderBox?;
    if (card == null || home == null || !card.attached) return;
    final middle = card.localToGlobal(card.size.center(Offset.zero), ancestor: home).dy;
    final atQuran = middle < home.size.height - widget.bottomInset;
    if (atQuran == _atQuran) return;
    _atQuran = atQuran;
    if (!_signedIn) {
      setState(() {}); // the signed-out card's guide speaks while the card is in view
      return;
    }
    if (!atQuran) {
      _hush();
    } else if (_fly.isCompleted) {
      _talk();
    } // else it asks once it lands
  }

  void _flightChanged(AnimationStatus status) {
    // Rebuild so the card hides or shows its character, and the bubble can appear on landing.
    setState(() {});
    if (status == AnimationStatus.completed && _atQuran) _talk();
    if (status == AnimationStatus.reverse) _hush();
  }

  void _talk() {
    if (!_signedIn) return; // its question asks to tap a surah, which needs an account
    _quiet?.cancel();
    _quiet = Timer(const Duration(seconds: 8), _hush);
    setState(() => _talking = true);
  }

  void _hush() {
    _quiet?.cancel();
    if (mounted && _talking) setState(() => _talking = false);
  }

  void _showQuranCard() {
    _hush();
    final card = _quranKey.currentContext;
    if (card == null) return;
    Scrollable.ensureVisible(
      card,
      alignment: 0.5,
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _now;
    final l = context.l10n;
    final top = MediaQuery.paddingOf(context).top + 9;
    final today = _Today.of(l, widget.plans, t);
    final shown = _shown;
    final isToday = shown == dateOnly(t);
    final day = isToday ? today : _Today.of(l, widget.plans, t, day: shown);
    // Today: from late tasks. Another day: how that day went (partly done
    // worries Hifdth, a missed day makes it sad; done or ahead, it's happy).
    final mood = isToday
        ? moodFor(sessionsBehind: today.behind)
        : switch (widget.plans?.dayState(shown, t)) {
            DayState.missed => HifdthMood.sad,
            DayState.partial => HifdthMood.worried,
            _ => HifdthMood.happy,
          };
    final pastDay = shown.isBefore(dateOnly(t));
    final plans = widget.plans;
    final landed = _fly.isCompleted;
    final cornerBottom = _cornerBottom;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _placeCorner();
    });

    return LayoutBuilder(
      builder: (context, box) => Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scroll,
              padding: EdgeInsets.fromLTRB(16, (top < 56 ? 56 : top) + _barHeight + 14, 16, widget.bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (plans?.plan != null) ...[
                    WeekStrip(
                      selected: shown,
                      now: t,
                      direction: _dir,
                      stateOf: (d) => plans!.dayState(d, t),
                      onSelect: _show,
                    ),
                    const SizedBox(height: 18),
                  ],
                  HifdthCard(
                    key: _cardKey,
                    mood: mood,
                    characterAway: !_fly.isDismissed,
                    title: isToday ? l.todaysPlanCaps : dateShort(l, shown, now: t).toUpperCase(),
                    subtitle: day.subtitle,
                    status: day.status,
                    contentKey: shown,
                    locked: !isToday,
                    steps: [
                      for (final task in day.tasks)
                        DayStep(
                          title: task.range,
                          subtitle: task.morning
                              ? '${l.taskRecite(task.range)}. ${l.taskReciteSub(linesText(l, task.lines), task.lessons)}'
                              : '${l.taskMemorize(task.range)}. ${l.taskMemorizeSub(linesText(l, task.lines))}',
                          time: task.morning ? l.morning : l.evening,
                          morning: task.morning,
                          tags: task.morning
                              ? [l.tagRecite33, linesText(l, task.lines)]
                              : [l.tagMemorize, linesText(l, task.lines), l.tagBy22],
                          done: widget.plans!.isDone(shown, task.id),
                          missed: pastDay && !widget.plans!.isDone(shown, task.id),
                        ),
                    ],
                    onToggle: (i) => _toggle(today.tasks, i),
                    empty: _DayMessage(
                      icon: day.icon,
                      title: day.message,
                      detail: day.detail,
                      action: day.action,
                      onAction: widget.onOpenMethod,
                    ),
                  ),
                  if (widget.plans?.plan case final plan?) ...[
                    const SizedBox(height: 18),
                    _PlanCard(plan: plan, today: today, onChange: widget.onOpenMethod),
                  ],
                  const SizedBox(height: 18),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _GoalCard(value: today.goal, caption: today.goalCaption)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StreakCard(
                            streak: plans?.streak(t) ?? 0,
                            longest: plans?.longestStreak(t) ?? 0,
                            week: plans?.weekProgress(t) ?? (0, 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Signed out, progress can't be changed: the locked card asks to sign in instead.
                  if (_signedIn)
                    _QuranProgress(key: _quranKey, hintKey: _hintKey, learned: widget.learned, onOpen: _hush)
                  else
                    SignedOutCard(
                      key: _quranKey,
                      hintKey: _hintKey,
                      speaking: _atQuran,
                      onSignIn: _openAuth,
                      onRegister: _openAuth,
                    ),
                ],
              ),
            ),
          ),
          // The bubble, beside where Hifdth lands.
          // Pinned: they stay put while the page scrolls under them.
          // The top bar floats over the page: the day pill on the left, the
          // offline cloud on the right.
          if (plans?.plan != null)
            Positioned(
              top: top < 56 ? 56 : top,
              left: 16,
              child: DayPill(
                label: dayLabel(l, shown, t),
                direction: _dir,
                onPrev: () => _show(addDays(shown, -1)),
                onNext: () => _show(addDays(shown, 1)),
                onOpen: _openMonth,
              ),
            ),
          Positioned(
            top: top < 56 ? 56 : top,
            right: 16,
            child: _HeaderButtons(online: widget.auth?.online),
          ),
          if (_signedIn)
            Positioned(
              left: 16,
              right: 16 + _miniSize + 8,
              bottom: cornerBottom,
              child: Align(
                alignment: Alignment.bottomRight,
                child: SpeechBubbleSlot(
                  title: l.askTitle,
                  body: l.askBody,
                  visible: landed && _talking,
                  onTap: _showQuranCard,
                  hint: l.showsQuranProgress,
                ),
              ),
            ),
          if (!_fly.isDismissed)
            _FlyingHifdth(
              flight: _fly,
              scroll: _scroll,
              mood: mood,
              // Starts from the card, but never above the top edge where it took off.
              from: () {
                final size = HifdthCard.characterSize;
                final top = math.max(_cardCharacterTop() ?? 0, MediaQuery.paddingOf(context).top);
                return Rect.fromLTWH((box.maxWidth - size) / 2, top, size, size);
              },
              to: Rect.fromLTWH(
                box.maxWidth - 16 - _miniSize,
                box.maxHeight - cornerBottom - _miniSize,
                _miniSize,
                _miniSize,
              ),
              talking: _talking,
              // While the question shows: blue, and looking toward the bubble and the grid.
              speaking: landed && _talking,
              look: landed && _talking ? -1 : 0,
              onTap: landed ? () => _talking ? _hush() : _talk() : null,
            ),
        ],
      ),
    );
  }
}

/// Hifdth on its way between the card and the corner. The path bows out to the
/// right: it drifts sideways early and drops late, shrinking as it goes.
class _FlyingHifdth extends StatelessWidget {
  const _FlyingHifdth({
    required this.flight,
    required this.scroll,
    required this.mood,
    required this.from,
    required this.to,
    required this.talking,
    required this.speaking,
    required this.look,
    required this.onTap,
  });

  /// Sideways leads and the drop follows, which bends the path. Both ease in
  /// and out gently, so it lifts off and settles without a jolt.
  static const _sideways = Cubic(0.3, 0.3, 0.2, 1);
  static const _drop = Cubic(0.5, 0.05, 0.25, 1);
  static const _shrink = Cubic(0.4, 0.15, 0.2, 1);

  final AnimationController flight;
  final ScrollController scroll;
  final HifdthMood mood;

  /// Read every frame, so landing back in the card follows the scroll.
  final Rect Function() from;
  final Rect to;
  final bool talking, speaking;
  final double look;

  /// Null while flying.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([flight, scroll]),
      builder: (context, child) {
        final t = flight.value;
        final a = from();
        final x = lerpDouble(a.left, to.left, _sideways.transform(t))!;
        final y = lerpDouble(a.top, to.top, _drop.transform(t))!;
        final size = lerpDouble(a.width, to.width, _shrink.transform(t))!;
        return Positioned(left: x, top: y, width: size, height: size, child: child!);
      },
      child: Semantics(
        button: true,
        label: context.l10n.hifdth,
        hint: talking ? context.l10n.hideMessage : context.l10n.talkToHifdth,
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: LayoutBuilder(
            builder: (context, box) => HifdthAvatar(
              mood: mood,
              size: box.maxWidth,
              look: look,
              speaking: speaking,
              // Green by the time it reaches the corner; its real mood again back in the card.
              calm: flight,
            ),
          ),
        ),
      ),
    );
  }
}

/// The offline cloud at the top right (the account lives in Settings). It shows while
/// offline; when the connection comes back it turns green for a moment
/// ([backOnlineFor]), then fades away.
class _HeaderButtons extends StatefulWidget {
  const _HeaderButtons({required this.online});

  final ValueListenable<bool>? online;

  static const backOnlineFor = Duration(seconds: 2);

  @override
  State<_HeaderButtons> createState() => _HeaderButtonsState();
}

enum _Cloud { hidden, offline, backOnline }

class _HeaderButtonsState extends State<_HeaderButtons> {
  /// Without an account connection (tests), the app counts as online.
  static final _alwaysOnline = ValueNotifier(true);

  ValueListenable<bool> get _online => widget.online ?? _alwaysOnline;
  late _Cloud _cloud = _online.value ? _Cloud.hidden : _Cloud.offline;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    _online.addListener(_changed);
  }

  @override
  void didUpdateWidget(_HeaderButtons old) {
    super.didUpdateWidget(old);
    if (old.online != widget.online) {
      (old.online ?? _alwaysOnline).removeListener(_changed);
      _online.addListener(_changed);
    }
  }

  void _changed() {
    _hide?.cancel();
    if (!_online.value) {
      setState(() => _cloud = _Cloud.offline);
    } else if (_cloud == _Cloud.offline) {
      setState(() => _cloud = _Cloud.backOnline);
      _hide = Timer(_HeaderButtons.backOnlineFor, () {
        if (mounted) setState(() => _cloud = _Cloud.hidden);
      });
    }
  }

  @override
  void dispose() {
    _hide?.cancel();
    _online.removeListener(_changed);
    super.dispose();
  }

  Widget _cloudButton() => switch (_cloud) {
        _Cloud.hidden => const SizedBox.shrink(key: ValueKey(_Cloud.hidden)),
        _Cloud.offline => _Pulse(
            key: const ValueKey(_Cloud.offline),
            child: GlassCircleButton(
              label: context.l10n.offline,
              onTap: () => Toast.show(context, context.l10n.offlineMessage),
              child: const Icon(Icons.cloud_off_rounded, size: 22, color: HColors.ink),
            ),
          ),
        _Cloud.backOnline => GlassCircleButton(
            key: const ValueKey(_Cloud.backOnline),
            label: context.l10n.backOnline,
            onTap: () => Toast.show(context, context.l10n.backOnlineMessage),
            fill: const RadialGradient(
              center: Alignment(-0.4, -0.6),
              radius: 1.1,
              colors: [Color(0xF26FD9A0), Color(0xE622B567), Color(0xF2169A55)],
              stops: [0, .5, 1],
            ),
            child: const Icon(Icons.cloud_done_rounded, size: 22, color: Colors.white),
          ),
      };

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      AnimatedSize(
        duration: reduce ? Duration.zero : const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: AnimatedSwitcher(
          // Offline → green is a colour change, so a quick cross-fade; appearing and leaving also scale a little.
          duration: reduce ? Duration.zero : const Duration(milliseconds: 200),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(a), child: child),
          ),
          layoutBuilder: (current, previous) =>
              Stack(alignment: Alignment.center, children: [...previous, if (current != null) current]),
          child: _cloudButton(),
        ),
      ),
    ]);
  }
}

/// Gently grows and shrinks [child] for as long as it's shown, so the offline
/// cloud keeps quietly asking for attention. Still with Reduce Motion on.
class _Pulse extends StatefulWidget {
  const _Pulse({super.key, required this.child});

  final Widget child;

  /// One grow-and-shrink, and how far it grows.
  static const period = Duration(milliseconds: 1600);
  static const amount = 0.07;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _wave = AnimationController(vsync: this, duration: _Pulse.period ~/ 2);
  late final _scale =
      Tween(begin: 1.0, end: 1 + _Pulse.amount).animate(CurvedAnimation(parent: _wave, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _wave
        ..stop()
        ..value = 0;
    } else if (!_wave.isAnimating) {
      _wave.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(scale: _scale, child: widget.child);
}

/// The Player only has Al-Qalam (surah 68) for now, so the grid starts there.
const _playerSurahIndex = 67;

/// Holds the selected surah for [QuranProgressCard].
class _QuranProgress extends StatefulWidget {
  const _QuranProgress({super.key, required this.learned, required this.onOpen, this.hintKey});

  final LearnedStore learned;

  /// Passed to the card's hint line.
  final Key? hintKey;

  /// Called when a surah's sheet opens.
  final VoidCallback onOpen;

  @override
  State<_QuranProgress> createState() => _QuranProgressState();
}

class _QuranProgressState extends State<_QuranProgress> {
  int _selected = _playerSurahIndex;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: widget.learned,
        builder: (context, _) => QuranProgressCard(
          surahs: [
            for (var i = 0; i < 114; i++)
              SurahProgress(
                number: i + 1,
                name: surahNames[i],
                ayahs: surahAyahCounts[i],
                memorized: widget.learned.learnedCount(i + 1),
              ),
          ],
          selected: _selected,
          onSelect: (i) => setState(() => _selected = i),
          hintKey: widget.hintKey,
          onTap: (i) {
            widget.onOpen();
            showLearnedSheet(context, store: widget.learned, surah: i + 1);
          },
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
                  Text(context.l10n.dailyGoalTitle, style: HText.inter(size: 14, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(caption, style: HText.inter(size: 13, color: HColors.ink2)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// The streak as a ring (this week's done study days fill it), the count in
/// days, and the longest streak so far as a small chip.
class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak, required this.longest, required this.week});

  /// Fully done study days in a row.
  final int streak, longest;

  /// This week's done study days, and how many it has.
  final (int, int) week;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (done, total) = week;
    return Semantics(
      container: true,
      label: '${l.streak}: ${l.daysCount(streak)}. ${l.longestStreak(longest)}. ${l.streakThisWeek(done, total)}',
      excludeSemantics: true,
      child: Container(
        decoration: BoxDecoration(color: HColors.surface, borderRadius: BorderRadius.circular(HRadii.card)),
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          StreakRing(streak: streak, value: total == 0 ? 0 : done / total),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.streak, style: HText.inter(size: 14, weight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(l.daysCount(streak), style: HText.inter(size: 13, color: HColors.ink2, tabular: true)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: HColors.mintWash, borderRadius: BorderRadius.circular(999)),
                child: Text(l.longestStreak(longest),
                    style: HText.inter(size: 11, weight: FontWeight.w600, color: HColors.accentDeep, tabular: true)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Everything Home shows about today's plan.
class _Today {
  const _Today({
    this.tasks = const [],
    this.subtitle,
    this.status,
    this.icon = Icons.event_note_rounded,
    this.message = '',
    this.detail,
    this.action,
    this.behind = 0,
    this.goal = 0,
    this.goalCaption = '',
    this.day,
    this.total = 0,
    this.finish,
  });

  /// The projected last study day (moves later with each skipped evening).
  final DateTime? finish;

  final List<PlanTask> tasks;

  /// "Day 4/50", as a chip.
  final String? subtitle;

  /// Pill text, when it isn't the mood's own.
  final String? status;

  /// Shown when there are no tasks: an icon, a short title, one line, maybe a button.
  final IconData icon;
  final String message;
  final String? detail;
  final String? action;

  /// Tasks whose time has passed unticked: sets Hifdth's mood.
  final int behind;
  final double goal;
  final String goalCaption;

  /// Study day index today (null on a rest day), and the number of lessons.
  final int? day;
  final int total;

  /// What Home shows for [day] (today unless the calendar picked another).
  /// Mood and the goal only ever follow today.
  static _Today of(AppLocalizations l, PlanStore? store, DateTime now, {DateTime? day}) {
    final shown = day ?? now;
    final isToday = dateOnly(shown) == dateOnly(now);
    final plan = store?.plan;
    if (store == null || plan == null) {
      return _Today(
        status: l.waitingForPlan,
        message: l.noPlanYet,
        detail: l.noPlanDetail,
        action: l.setUpMyPlan,
        goalCaption: l.nothingDue,
      );
    }
    // Days follow the real ticks: an evening lesson that wasn't learned moves
    // to the next study day, which adds a day to the plan.
    final total = store.totalDays(now);
    final skipped = store.skipped(now);
    final finish = store.finishDate(now);
    final s = store.scheduleOn(shown, now);
    final d = dateOnly(shown);
    if (s == null) {
      if (d.isBefore(plan.startDate)) {
        return _Today(
          icon: Icons.event_rounded,
          message: l.startsOn(dateShort(l, plan.startDate)),
          goalCaption: l.nothingDue,
          day: -1,
          total: total,
        );
      }
      if (finish != null && d.isAfter(finish)) {
        return _Today(
          icon: Icons.verified_rounded,
          message: l.planComplete,
          detail: l.planCompleteDetail(plan.positions.length, nameOf(plan.start.s), nameOf(plan.end.s)),
          action: l.setNewRange,
          goalCaption: l.nothingDue,
          day: total,
          total: total,
        );
      }
      return _Today(
        status: l.restDayStatus,
        icon: Icons.self_improvement_rounded,
        message: l.restDay,
        detail: l.restDayDetail,
        goalCaption: l.nothingDue,
        total: total,
      );
    }
    final tasks = store.tasksOn(shown, now);
    final done = tasks.where((t) => store.isDone(shown, t.id)).length;
    final left = tasks.length - done;
    final String? status = isToday
        ? (left == 0
            ? l.planDoneToast
            : skipped > 0 && finish != null
                ? l.skippedStatus(skipped, dateShort(l, finish, now: now))
                : null)
        : switch (store.dayState(shown, now)) {
            DayState.done => l.dayDoneStatus,
            DayState.partial => l.dayPartialStatus(done, tasks.length),
            DayState.missed => l.dayMissedStatus,
            _ => l.dayUpcomingStatus,
          };
    return _Today(
      tasks: tasks,
      subtitle: l.dayOf(s.number, total),
      status: status,
      behind: isToday ? store.behind(now) : 0,
      goal: tasks.isEmpty ? 0 : done / tasks.length,
      goalCaption: left == 0 ? l.allDoneToday : l.leftToday(left),
      day: s.number - 1,
      total: total,
      finish: finish,
    );
  }
}

/// No tasks today: an icon, why, and maybe a button to My Method.
class _DayMessage extends StatelessWidget {
  const _DayMessage({required this.icon, required this.title, this.detail, this.action, this.onAction});

  final IconData icon;
  final String title;
  final String? detail;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: HColors.mintWash, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 22, color: HColors.accentDeep),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: HText.inter(size: 15, weight: FontWeight.w600)),
                if (detail case final d?) ...[
                  const SizedBox(height: 2),
                  Text(d, style: HText.inter(size: 13, height: 1.35, color: HColors.ink2)),
                ],
              ]),
            ),
          ]),
          if (action case final label?) ...[
            const SizedBox(height: 14),
            PrimaryButton(label: label, compact: true, onPressed: onAction),
          ],
        ],
      );
}

/// Your plan: the method and range, an edit button, a strip of days, and the
/// pace, finish date and rest day as small chips.
class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan, required this.today, this.onChange});

  final Plan plan;
  final _Today today;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final total = today.total;
    final cells = total < 40 ? total : 40;
    final per = total / cells;
    final day = today.day;
    // Which cell is today: none before the start or on a rest day; all done once finished.
    final now = day == null || day < 0 ? -1 : (day >= total ? cells : (day / per).floor());
    final dayText = day == null || day < 0 ? '0/$total' : '${day >= total ? total : day + 1}/$total';
    final rest = plan.restWeekday;
    return Semantics(
      container: true,
      label: context.l10n.yourPlanTitle,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 16),
        decoration: BoxDecoration(color: HColors.surface, borderRadius: BorderRadius.circular(HRadii.card)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const MushafPlayIcon(size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.l10n.methodName, style: HText.inter(size: 16, weight: FontWeight.w600)),
                const SizedBox(height: 1),
                Text('${nameOf(plan.start.s)} → ${nameOf(plan.end.s)}',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: HText.inter(size: 13, color: HColors.ink2)),
              ]),
            ),
            Semantics(
              button: true,
              label: context.l10n.changePlan,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onChange,
                child: SizedBox.square(
                  dimension: 44,
                  child: Center(
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(color: HColors.mintWash, shape: BoxShape.circle),
                      child: const Icon(Icons.edit_rounded, size: 17, color: HColors.accentDeep),
                    ),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(children: [
              Expanded(
                child: Semantics(
                  label: day == null ? context.l10n.restDay : context.l10n.dayText(dayText),
                  excludeSemantics: true,
                  child: SizedBox(
                    height: 8,
                    child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      for (var i = 0; i < cells; i++) ...[
                        if (i > 0) const SizedBox(width: 2),
                        Expanded(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: i < now
                                  ? HColors.accent
                                  : i == now
                                      ? HColors.accentDeep
                                      : HColors.track,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 6, runSpacing: 6, children: [
            _Fact(Icons.subject_rounded, context.l10n.linesPerDayFact(plan.linesPerDay)),
            _Fact(Icons.flag_rounded, dateShort(context.l10n, today.finish ?? plan.finishDate()),
                label: context.l10n.finishesOn(dateShort(context.l10n, today.finish ?? plan.finishDate()))),
            if (rest != null)
              _Fact(Icons.weekend_rounded, context.l10n.dayOff(weekdayTitle(context.l10n, rest))),
          ]),
        ]),
      ),
    );
  }
}

/// An icon and a few words, on a soft gray pill.
class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.text, {this.label});

  final IconData icon;
  final String text;
  final String? label;

  @override
  Widget build(BuildContext context) => Semantics(
        label: label ?? text,
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
          decoration: BoxDecoration(color: HColors.bgTop, borderRadius: BorderRadius.circular(999)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: HColors.inkMuted),
            const SizedBox(width: 4),
            Text(text, style: HText.inter(size: 12, weight: FontWeight.w500, color: HColors.ink2, tabular: true)),
          ]),
        ),
      );
}
