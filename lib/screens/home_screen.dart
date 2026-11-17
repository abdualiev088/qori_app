import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../data/learned_store.dart';
import '../data/surahs.dart';
import '../theme/tokens.dart';
import '../widgets/glass.dart';
import '../widgets/hifdth_card.dart';
import '../widgets/hifdth_mood.dart';
import '../widgets/learned_sheet.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.bottomInset, required this.learned, this.now});

  /// Which ayahs are learned; the Quran progress card follows it.
  final LearnedStore learned;

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
                      GlassProfileButton(onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 18),
                  HifdthCard(key: _cardKey, mood: mood, steps: _steps, characterAway: !_fly.isDismissed),
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
                  _QuranProgress(key: _quranKey, hintKey: _hintKey, learned: widget.learned, onOpen: _hush),
                ],
              ),
            ),
          ),
          // The bubble, beside where Hifdth lands.
          Positioned(
            left: 16,
            right: 16 + _miniSize + 8,
            bottom: cornerBottom,
            child: Align(
              alignment: Alignment.bottomRight,
              child: _BubbleSlot(talking: landed && _talking, onTap: _showQuranCard),
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

/// Fades and scales the speech bubble in from its corner.
class _BubbleSlot extends StatelessWidget {
  const _BubbleSlot({required this.talking, required this.onTap});

  final bool talking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final ms = reduce ? Duration.zero : Duration(milliseconds: talking ? 200 : 150);
    return IgnorePointer(
      ignoring: !talking,
      child: AnimatedOpacity(
        opacity: talking ? 1 : 0,
        duration: ms,
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: talking ? 1 : 0.92,
          alignment: Alignment.bottomRight,
          duration: ms,
          curve: Curves.easeOut,
          child: _SpeechBubble(onTap: onTap, visible: talking),
        ),
      ),
    );
  }
}

/// Hifdth's question. Each time it opens, the words stream in one after
/// another, like a chat reply being written.
class _SpeechBubble extends StatefulWidget {
  const _SpeechBubble({required this.onTap, required this.visible});

  final VoidCallback onTap;
  final bool visible;

  @override
  State<_SpeechBubble> createState() => _SpeechBubbleState();
}

class _SpeechBubbleState extends State<_SpeechBubble> with SingleTickerProviderStateMixin {
  static final _title = HomeScreen.askTitle.split(' ');
  static final _body = HomeScreen.askBody.split(' ');

  /// A new word starts this often; each one fades in over [_fade].
  static const _step = 55;
  static const _fade = 160;

  /// A short breath between the question and the line under it.
  static const _pause = 140;

  static const _bodyColor = Color(0xE6FFFFFF);

  static final _total = (_title.length + _body.length - 1) * _step + _pause + _fade;

  late final _typing = AnimationController(vsync: this, duration: Duration(milliseconds: _total));

  @override
  void initState() {
    super.initState();
    if (widget.visible) _type();
  }

  @override
  void didUpdateWidget(_SpeechBubble old) {
    super.didUpdateWidget(old);
    // Hiding keeps the words, so they fade out with the bubble; showing starts over.
    if (widget.visible && !old.visible) _type();
  }

  void _type() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _typing.value = 1;
    } else {
      _typing.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _typing.dispose();
    super.dispose();
  }

  /// The words as spans, each one's opacity following its own start time.
  /// Words not yet written are transparent but still laid out, so the bubble
  /// keeps its size and nothing reflows while it types.
  List<TextSpan> _words(List<String> words, int firstStart, double ms, Color color) => [
        for (var i = 0; i < words.length; i++)
          TextSpan(
            text: i < words.length - 1 ? '${words[i]} ' : words[i],
            style: TextStyle(
              color: color.withValues(
                alpha: color.a * Curves.easeOut.transform(((ms - firstStart - i * _step) / _fade).clamp(0.0, 1.0)),
              ),
            ),
          ),
      ];

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        liveRegion: widget.visible,
        hidden: !widget.visible,
        label: '${HomeScreen.askTitle} ${HomeScreen.askBody}',
        hint: 'Shows your Quran progress',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 240),
            margin: const EdgeInsets.only(bottom: 18), // the tail points at Hifdth's face
            // Hifdth's speaking blue as tinted glass, frosted only lightly so the surah
            // numbers behind still show through faintly.
            child: LiquidGlass(
              radius: 18,
              corners: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(4),
              ),
              blur: 4,
              borderColor: const Color(0x8CFFFFFF),
              shadows: const [
                BoxShadow(color: Color(0x332A6FD6), offset: Offset(0, 10), blurRadius: 28),
                BoxShadow(color: Color(0x1A1D58B5), offset: Offset(0, 1), blurRadius: 3),
              ],
              fill: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xC25FA6F5), Color(0xB33B8EF0), Color(0xC72A6FD6)],
                stops: [0, .55, 1],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
                child: AnimatedBuilder(
                  animation: _typing,
                  builder: (context, _) {
                    final ms = _typing.value * _total;
                    final bodyStart = _title.length * _step + _pause;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(children: _words(_title, 0, ms, Colors.white)),
                          style: HText.inter(size: 14, weight: FontWeight.w600, height: 1.3, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(children: _words(_body, bodyStart, ms, _bodyColor)),
                          style: HText.inter(size: 13, height: 1.3, color: _bodyColor),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HText.inter(size: 14, weight: FontWeight.w600)),
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
