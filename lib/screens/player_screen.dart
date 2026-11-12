import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../data/al_qalam.dart';
import '../player/player_controller.dart';
import '../theme/tokens.dart';
import '../widgets/glass.dart';
import '../widgets/icons.dart';
import '../widgets/progress_indicators.dart';
import '../widgets/ribbed_glass.dart';
import '../widgets/star.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.controller, required this.bottomInset});

  final PlayerController controller;
  final double bottomInset;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _scroll = ScrollController();
  final _rowKeys = {for (var n = 0; n <= ayat.length; n++) n: GlobalKey()};

  PlayerController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.onScrollRequest = _scrollTo;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollTo(c.current, center: true));
  }

  @override
  void dispose() {
    if (c.onScrollRequest == _scrollTo) c.onScrollRequest = null;
    _scroll.dispose();
    super.dispose();
  }

  /// Centers the row, or nudges the list just enough to show it (6 px margin).
  void _scrollTo(int n, {bool center = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _rowKeys[n]?.currentContext;
      if (ctx == null || !_scroll.hasClients) return;
      final box = ctx.findRenderObject()!;
      final viewport = RenderAbstractViewport.of(box);
      final pos = _scroll.position;
      final top = viewport.getOffsetToReveal(box, 0).offset;
      final bottom = viewport.getOffsetToReveal(box, 1).offset;
      double? target;
      if (center) {
        target = viewport.getOffsetToReveal(box, 0.5).offset;
      } else if (pos.pixels > top - 6) {
        target = top - 6;
      } else if (pos.pixels < bottom + 6) {
        target = bottom + 6;
      }
      if (target == null) return;
      target = target.clamp(pos.minScrollExtent, pos.maxScrollExtent);
      if (center || MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(target);
      } else {
        _scroll.animateTo(target, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 9;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => Padding(
        padding: EdgeInsets.fromLTRB(16, top < 56 ? 56 : top, 16, widget.bottomInset),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(c: c),
            if (c.selecting) ...[
              const SizedBox(height: 12),
              Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: HColors.mintWash,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: HColors.mintHintRing),
                  ),
                  child: Text(c.selectionHint,
                      textAlign: TextAlign.center, style: HText.inter(size: 14, height: 1.4)),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(child: _AyahList(c: c, scroll: _scroll, rowKeys: _rowKeys)),
            const SizedBox(height: 12),
            _PlayerPanel(c: c),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- header

class _Header extends StatelessWidget {
  const _Header({required this.c});

  final PlayerController c;

  @override
  Widget build(BuildContext context) {
    final count = c.selected.length;
    Widget textButton(String label, VoidCallback onTap) => TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            foregroundColor: HColors.accentDeep,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: HText.inter(size: 14, weight: FontWeight.w600),
          ),
          child: Text(label),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('Al-Qalam',
                          style: HText.inter(size: 24, weight: FontWeight.w700, letterSpacing: -0.4, height: 1.2)),
                      const SizedBox(width: 8),
                      Text('القلم',
                          textDirection: TextDirection.rtl,
                          style: HText.arabic(size: 22, color: HColors.accentDeep)),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text('Alijon Qori · Surah 68 · 52 ayahs',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HText.inter(size: 13, weight: FontWeight.w500, color: HColors.ink2)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (c.selecting && count == 0) textButton('All', c.selectAll),
          if (c.selecting && count > 0) textButton('Clear', c.clearSelection),
          if (!c.selecting && count > 0) textButton('Cancel', c.cancelSelection),
          const SizedBox(width: 2),
          _SelectPill(c: c),
        ],
      ),
    );
  }
}

class _SelectPill extends StatelessWidget {
  const _SelectPill({required this.c});

  final PlayerController c;

  @override
  Widget build(BuildContext context) {
    final count = c.selected.length;
    final on = c.selecting;
    final color = on ? Colors.white : HColors.ink;
    final label = on ? 'Done' : (count > 0 ? 'Selected' : 'Select');
    return Semantics(
      button: true,
      label: on ? 'Done selecting' : (count > 0 ? 'Selected, $count ayat. Tap to change' : 'Select ayat'),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => c.setSelecting(!on),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2), // 40 px pill, 44 px target
          child: SizedBox(
            height: 40,
            child: LiquidGlass(
              radius: 20,
              blur: 20,
              borderColor: const Color(0xD9FFFFFF),
              highlight: 0.9,
              shadows: const [BoxShadow(color: Color(0x1F14462D), offset: Offset(0, 6), blurRadius: 16)],
              fill: on
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF149A5A), HColors.accentDeep],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xD9FFFFFF), Color(0x73FFFFFF)],
                    ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    HIcon.check(color, width: 2.2),
                    const SizedBox(width: 6),
                    Text(label, style: HText.inter(size: 14, weight: FontWeight.w600, color: color)),
                    if (!on && count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        constraints: const BoxConstraints(minWidth: 20),
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: HColors.accentDeep,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$count',
                            style: HText.inter(size: 12, weight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- list

class _AyahList extends StatelessWidget {
  const _AyahList({required this.c, required this.scroll, required this.rowKeys});

  final PlayerController c;
  final ScrollController scroll;
  final Map<int, GlobalKey> rowKeys;

  @override
  Widget build(BuildContext context) {
    final basmalaCurrent = c.current == 0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(HRadii.list),
      child: ColoredBox(
        color: HColors.surface,
        child: SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RowSurface(
                key: rowKeys[0],
                current: basmalaCurrent,
                semanticLabel: 'Basmala. Tap to listen',
                onTap: () => c.tapAyah(0),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Column(
                  children: [
                    Text(basmala,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        style: HText.arabic(size: 22, height: 1.9)),
                    const SizedBox(height: 2),
                    Text('Tap to listen to the Basmala',
                        style: HText.inter(size: 12, height: 1.4, color: HColors.ink2)),
                  ],
                ),
              ),
              for (final (i, a) in ayat.indexed)
                _AyahRow(
                  key: rowKeys[a.n],
                  ayah: a,
                  c: c,
                  showDivider: i > 0 && c.current != a.n && c.current != ayat[i - 1].n,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tappable rounded row; mint wash + ring when it's the current ayah.
class _RowSurface extends StatelessWidget {
  const _RowSurface({
    super.key,
    required this.current,
    required this.onTap,
    required this.child,
    required this.padding,
    required this.semanticLabel,
    this.checked,
    this.tint,
  });

  final bool current;
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;
  final String semanticLabel;
  final bool? checked;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      checked: checked,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: current ? HColors.mintWash : (tint ?? Colors.transparent),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HRadii.row),
          side: current ? const BorderSide(color: HColors.mintRing) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          highlightColor: HColors.mintWash.withValues(alpha: 0.6),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class _AyahRow extends StatelessWidget {
  const _AyahRow({super.key, required this.ayah, required this.c, required this.showDivider});

  final Ayah ayah;
  final PlayerController c;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final cur = ayah.n == c.current;
    final checked = c.selected.contains(ayah.n);
    final dim = c.hasQueue && !c.selecting && !checked && !cur;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: showDivider ? HColors.divider : Colors.transparent)),
      ),
      child: Opacity(
        opacity: dim ? 0.42 : 1,
        child: _RowSurface(
          current: cur,
          tint: c.selecting && checked ? HColors.mintSelected : null,
          semanticLabel: 'Ayah ${ayah.n}. ${ayah.en}',
          checked: c.selecting ? checked : null,
          onTap: () => c.tapAyah(ayah.n),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          child: ExcludeSemantics(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (c.selecting) ...[
                  SizedBox(
                    width: 24,
                    height: 34,
                    child: Center(
                      child: Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: checked ? HColors.accentDeep : null,
                          border: checked ? null : Border.all(color: HColors.inkMuted, width: 1.5),
                        ),
                        child: checked ? HIcon.check(Colors.white, size: 13, width: 3.2) : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                SizedBox.square(
                  dimension: 34,
                  child: Center(
                    child: StarBadge(
                      size: 32,
                      fill: cur ? HColors.starFill : null,
                      stroke: cur ? HColors.accent : HColors.accentDeep,
                      label: Text('${ayah.n}',
                          style: HText.inter(
                              size: 11,
                              weight: FontWeight.w700,
                              color: cur ? HColors.numOnMint : HColors.accentDeep)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text.rich(
                          TextSpan(
                            style: HText.arabic(size: 22, height: 1.95),
                            children: [
                              TextSpan(text: '${ayah.ar} '),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: StarBadge(
                                  size: 26,
                                  stroke: HColors.accentDeep,
                                  strokeWidth: 1.6,
                                  label: Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Text(arabicDigits(ayah.n),
                                        style: HText.arabic(size: 11, height: 1, color: HColors.accentDeep)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(ayah.en, style: HText.inter(size: 14, height: 1.5, color: HColors.ink3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- player panel

class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({required this.c});

  final PlayerController c;

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.all(Radius.circular(HRadii.panel));
    final (pre, strong, post) = c.counter;
    final white72 = Colors.white.withValues(alpha: 0.72);

    return Semantics(
      container: true,
      label: 'Player',
      child: DecoratedBox(
        decoration: const BoxDecoration(
          borderRadius: radius,
          boxShadow: [BoxShadow(color: Color(0x4D08241A), offset: Offset(0, 10), blurRadius: 26)],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: CustomPaint(
            painter: RibbedGlassPainter.player,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: HColors.playerMint.withValues(alpha: 0.22)),
              ),
              padding: const EdgeInsets.fromLTRB(13, 9, 13, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(c.current == 0 ? 'Basmala' : 'Ayah ${c.current}',
                          style: HText.inter(
                              size: 15, weight: FontWeight.w600, letterSpacing: -0.2, color: Colors.white)),
                      if (c.current != 0) ...[
                        const SizedBox(width: 7),
                        Text(arabicDigits(c.current), style: HText.arabic(size: 17, color: HColors.playerMint2)),
                      ],
                      if (c.queuePosition.isNotEmpty) ...[
                        const SizedBox(width: 7),
                        Text(c.queuePosition,
                            style: HText.inter(size: 12, weight: FontWeight.w500, color: white72)),
                      ],
                      const Spacer(),
                      Semantics(
                        liveRegion: true,
                        child: Text.rich(
                          TextSpan(
                            style: HText.inter(size: 12, color: white72),
                            children: [
                              TextSpan(text: pre),
                              TextSpan(
                                  text: strong,
                                  style: HText.inter(size: 12, weight: FontWeight.w700, color: Colors.white)),
                              TextSpan(text: post),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _SeekBar(c: c),
                  const SizedBox(height: 6),
                  _Transport(c: c),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('REPEAT EACH AYAH',
                          style: HText.inter(size: 11, weight: FontWeight.w600, letterSpacing: 0.6, color: white72)),
                      _AutoSwitch(c: c),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      for (final (i, r) in repeatOptions.indexed) ...[
                        if (i > 0) const SizedBox(width: 5),
                        Expanded(child: _RepeatChip(value: r, on: r == c.repeat, onTap: () => c.setRepeat(r))),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One segment per repetition; tap or drag seeks inside the current one.
class _SeekBar extends StatelessWidget {
  const _SeekBar({required this.c});

  final PlayerController c;

  void _seek(Offset local, double width) {
    final n = c.repeat == 0 ? 1 : c.repeat;
    final cur = c.repeat == 0 ? 0 : (c.plays < n - 1 ? c.plays : n - 1);
    const gap = 3.0;
    final segW = (width - gap * (n - 1)) / n;
    c.seekTo((local.dx - cur * (segW + gap)) / segW);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: c.progress,
      builder: (context, p, _) => Semantics(
        slider: true,
        label: 'Position',
        value: '${(p * 100).round()}',
        onIncrease: () => c.seekBy(const Duration(seconds: 2)),
        onDecrease: () => c.seekBy(const Duration(seconds: -2)),
        child: LayoutBuilder(
          builder: (context, box) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => _seek(d.localPosition, box.maxWidth),
            onHorizontalDragUpdate: (d) => _seek(d.localPosition, box.maxWidth),
            child: SizedBox(
              height: 16,
              child: Center(
                child: SegmentedProgressBar(
                  fills: c.segmentFills(p),
                  height: 4,
                  gap: 3,
                  color: HColors.playerMint,
                  trackColor: Colors.white.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Transport extends StatelessWidget {
  const _Transport({required this.c});

  final PlayerController c;

  @override
  Widget build(BuildContext context) {
    Widget skip(String label, bool enabled, VoidCallback onTap, HIcon Function(Color) icon) => Semantics(
          button: true,
          enabled: enabled,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? onTap : null,
            child: SizedBox.square(
              dimension: 44,
              child: Center(child: icon(enabled ? Colors.white : Colors.white.withValues(alpha: 0.3))),
            ),
          ),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        skip('Previous ayah', c.canGoPrevious, c.goPrevious, HIcon.previous),
        const SizedBox(width: 26),
        Semantics(
          button: true,
          label: c.playing ? 'Pause' : 'Play',
          excludeSemantics: true,
          child: GestureDetector(
            onTap: c.toggle,
            child: SizedBox.square(
              dimension: 48,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        center: Alignment(-0.3, -0.44),
                        radius: 0.97,
                        colors: [Color(0xFFD4FBE4), HColors.playerMint2, HColors.playerSwitchOn],
                        stops: [0, .5, 1],
                      ),
                      boxShadow: [BoxShadow(color: Color(0x594CC488), offset: Offset(0, 6), blurRadius: 16)],
                    ),
                    child: SizedBox.expand(),
                  ),
                  c.playing
                      ? HIcon.pause(HColors.playerInk)
                      : Padding(
                          padding: const EdgeInsets.only(left: 3),
                          child: HIcon.play(HColors.playerInk),
                        ),
                  if (c.loading) const Positioned(left: -5, top: -5, right: -5, bottom: -5, child: _Spinner()),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 26),
        skip('Next ayah', c.canGoNext, c.goNext, HIcon.next),
      ],
    );
  }
}

/// Buffering ring around the play button; holds still under reduced motion.
class _Spinner extends StatefulWidget {
  const _Spinner();

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner> with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: RotationTransition(
          turns: _ctrl,
          child: const CustomPaint(painter: _ArcPainter()),
        ),
      );
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(1);
    canvas.drawArc(
      rect,
      -2.356, // the CSS border-top arc: from 10:30 to 1:30
      1.571,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = HColors.playerMint2,
    );
  }

  @override
  bool shouldRepaint(_ArcPainter old) => false;
}

class _AutoSwitch extends StatelessWidget {
  const _AutoSwitch({required this.c});

  final PlayerController c;

  @override
  Widget build(BuildContext context) {
    final on = c.autoOn;
    const curve = Cubic(0.32, 0.72, 0, 1);
    final reduce = MediaQuery.disableAnimationsOf(context);
    final dur = reduce ? Duration.zero : const Duration(milliseconds: 200);
    return Semantics(
      toggled: on,
      label: c.autoLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: c.toggleAuto,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(c.autoLabel, style: HText.inter(size: 12, color: Colors.white)),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: dur,
                width: 34,
                height: 20,
                decoration: BoxDecoration(
                  color: on ? HColors.playerSwitchOn : Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AnimatedAlign(
                  duration: dur,
                  curve: curve,
                  alignment: on ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Color(0x4D000000), offset: Offset(0, 1), blurRadius: 2)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RepeatChip extends StatelessWidget {
  const _RepeatChip({required this.value, required this.on, required this.onTap});

  final int value;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      label: value == 0 ? 'Repeat forever' : 'Repeat $value times',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: on ? const Color(0xE6BFF5D6) : Colors.white.withValues(alpha: 0.14)),
            gradient: on
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFA6EBC6), HColors.playerMint],
                  )
                : null,
            color: on ? null : Colors.white.withValues(alpha: 0.08),
            boxShadow: on
                ? const [BoxShadow(color: Color(0x4D7FE0A8), offset: Offset(0, 3), blurRadius: 8)]
                : null,
          ),
          child: Text(
            value == 0 ? '∞' : '$value×',
            style: HText.inter(
                size: 13,
                weight: FontWeight.w600,
                color: on ? HColors.playerInk : Colors.white.withValues(alpha: 0.85)),
          ),
        ),
      ),
    );
  }
}
