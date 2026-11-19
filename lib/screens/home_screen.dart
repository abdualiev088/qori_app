import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../data/auth_api.dart';
import '../data/learned_store.dart';
import '../data/surahs.dart';
import '../theme/tokens.dart';
import '../widgets/glass.dart';
import '../widgets/hifdth_card.dart';
import '../widgets/hifdth_mood.dart';
import '../widgets/learned_sheet.dart';
import '../widgets/progress_indicators.dart';
import '../widgets/quran_progress_card.dart';
import '../widgets/signed_out_card.dart';
import '../widgets/speech_bubble.dart';
import '../widgets/toast.dart';
import 'account_screen.dart';
import 'auth_screen.dart';

// Today's plan, empty until sessions are tracked: nothing is done on a fresh install.
const _steps = [
  DayStep(title: 'Morning session', subtitle: 'Up next · 6:30 am', done: false),
  DayStep(title: 'Review', subtitle: '10:30 am', done: false),
  DayStep(title: 'Evening session', subtitle: '7:00 pm', done: false),
];

/// Sessions whose time has passed without being done. Placeholder until the schedule is real.
const _sessionsBehind = 0;
const _week = [
  StreakDay('M', false),
  StreakDay('T', false),
  StreakDay('W', false),
  StreakDay('T', false),
  StreakDay('F', false),
  StreakDay('S', false),
  StreakDay('S', false),
];

int get _sessionsDone => _steps.where((s) => s.done).length;
int get _sessionsLeft => _steps.length - _sessionsDone;

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', //
  'July', 'August', 'September', 'October', 'November', 'December',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.bottomInset, required this.learned, this.now, this.auth});

  /// Which ayahs are learned; the Quran progress card follows it.
  final LearnedStore learned;

  /// Sign-in calls. Without it (tests) the profile button does nothing.
  final AuthApi? auth;

  /// Space reserved under the content for the floating nav.
  final double bottomInset;

  /// Overrides the clock (tests).
  final DateTime? now;

  /// What the small Hifdth says when it asks about memorisation.
  static const askTitle = 'How much of the Quran have you memorised?';
  static const askBody = 'Tap a surah to tell me.';

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

  /// The corner spot's bottom edge, above Home's bottom. Hifdth's middle lines
  /// up with the card's hint line when the page is scrolled to the end; this
  /// fallback is replaced once the card has been laid out.
  double _cornerBottom = 180;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_followScroll);
    widget.auth?.addListener(_authChanged);
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
    final t = widget.now ?? DateTime.now();
    final greeting = t.hour < 12 ? 'Good morning' : (t.hour < 18 ? 'Good afternoon' : 'Good evening');
    final top = MediaQuery.paddingOf(context).top + 9;
    final mood = moodFor(sessionsBehind: _sessionsBehind);
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
              padding: EdgeInsets.fromLTRB(16, top < 56 ? 56 : top, 16, widget.bottomInset),
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
                      const SizedBox(width: 46), // the header buttons float here (see _HeaderButtons)
                    ],
                  ),
                  const SizedBox(height: 18),
                  HifdthCard(key: _cardKey, mood: mood, steps: _steps, characterAway: !_fly.isDismissed),
                  const SizedBox(height: 18),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _GoalCard(
                            value: _sessionsDone / _steps.length,
                            caption: _sessionsLeft == 0
                                ? 'All sessions done'
                                : '$_sessionsLeft ${_sessionsLeft == 1 ? 'session' : 'sessions'} left',
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(child: _StreakCard(days: _week)),
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
          Positioned(
            top: top < 56 ? 56 : top,
            right: 16,
            child: _HeaderButtons(online: widget.auth?.online, onProfile: _openAuth),
          ),
          if (_signedIn)
            Positioned(
              left: 16,
              right: 16 + _miniSize + 8,
              bottom: cornerBottom,
              child: Align(
                alignment: Alignment.bottomRight,
                child: SpeechBubbleSlot(
                  title: HomeScreen.askTitle,
                  body: HomeScreen.askBody,
                  visible: landed && _talking,
                  onTap: _showQuranCard,
                  hint: 'Shows your Quran progress',
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
        label: 'Hifdth',
        hint: talking ? 'Hide message' : 'Talk to Hifdth',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: LayoutBuilder(
            builder: (context, box) => HifdthAvatar(mood: mood, size: box.maxWidth, look: look, speaking: speaking),
          ),
        ),
      ),
    );
  }
}

/// The cloud and profile buttons at the top right. The cloud shows while
/// offline; when the connection comes back it turns green for a moment
/// ([backOnlineFor]), then fades away.
class _HeaderButtons extends StatefulWidget {
  const _HeaderButtons({required this.online, required this.onProfile});

  final ValueListenable<bool>? online;
  final VoidCallback onProfile;

  static const offlineMessage = "You're offline. Changes are saved on this phone and sync when you're back online.";
  static const backOnlineMessage = "You're back online. Your changes are syncing.";
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
              label: 'Offline',
              onTap: () => Toast.show(context, _HeaderButtons.offlineMessage),
              child: const Icon(Icons.cloud_off_rounded, size: 22, color: HColors.ink),
            ),
          ),
        _Cloud.backOnline => GlassCircleButton(
            key: const ValueKey(_Cloud.backOnline),
            label: 'Back online',
            onTap: () => Toast.show(context, _HeaderButtons.backOnlineMessage),
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
          child: _cloud == _Cloud.hidden
              ? _cloudButton()
              : Padding(key: ValueKey(_cloud), padding: const EdgeInsets.only(right: 10), child: _cloudButton()),
        ),
      ),
      GlassProfileButton(onTap: widget.onProfile),
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
                  Text('Daily goal', style: HText.inter(size: 14, weight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(caption, style: HText.inter(size: 13, color: HColors.ink2)),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HText.inter(size: 14, weight: FontWeight.w600)),
              ),
              const SizedBox(width: 6),
              Text('$streak ${streak == 1 ? 'day' : 'days'}',
                  style: HText.inter(size: 13, color: HColors.ink2, tabular: true)),
            ],
          ),
          const SizedBox(height: 10),
          StreakBars(days: days),
        ],
      ),
    );
  }
}
