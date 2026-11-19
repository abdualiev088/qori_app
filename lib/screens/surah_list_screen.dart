import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../data/learned_store.dart';
import '../data/surah_index.dart';
import '../data/surah_meta.dart';
import '../data/surahs.dart';
import '../player/player_controller.dart';
import '../theme/tokens.dart';
import '../widgets/icons.dart';
import '../widgets/progress_indicators.dart';
import '../widgets/star.dart';

/// The Player tab's first screen: every surah, grouped by juz, with search.
/// Tapping a row opens the player at that row's first ayah ([onOpen]).
class SurahListScreen extends StatefulWidget {
  const SurahListScreen(
      {super.key, required this.learned, required this.onOpen, required this.bottomInset, this.titleFocus});

  final LearnedStore learned;
  final void Function(int surah, int ayah) onOpen;

  /// Room at the bottom for the nav, and the mini-player while it shows.
  final ValueListenable<double> bottomInset;

  /// Focus lands on the "Surahs" title after the mini-player closes.
  final FocusNode? titleFocus;

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final _scroll = ScrollController();
  final _rail = ScrollController();
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  final _sectionKeys = [for (var j = 0; j < 30; j++) GlobalKey()];
  final _railKeys = [for (var j = 0; j < 30; j++) GlobalKey()];

  /// The juz whose section is at the top, 1–30.
  int _currentJuz = 1;

  /// Set while a tap on a juz button scrolls, so the scroll doesn't fight it.
  bool _jumping = false;

  static const _railHeight = 52.0;
  static const _searchHeight = 48.0;
  static const _stickyPad = 10.0;

  String get _query => _search.text;
  bool get _searching => _query.trim().isNotEmpty;
  double get _stickyHeight => _stickyPad + _searchHeight + (_searching ? _stickyPad : _railHeight);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_followScroll);
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scroll.dispose();
    _rail.dispose();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Highlights the juz whose section has reached the sticky block.
  void _followScroll() {
    if (_jumping || _searching) return;
    final viewport = _scroll.position.context.storageContext.findRenderObject() as RenderBox?;
    if (viewport == null) return;
    final line = viewport.localToGlobal(Offset.zero).dy + _stickyHeight + 1;
    var juz = 1;
    for (var j = 0; j < 30; j++) {
      final box = _sectionKeys[j].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached) continue;
      if (box.localToGlobal(Offset.zero).dy <= line) juz = j + 1;
    }
    if (juz != _currentJuz) {
      setState(() => _currentJuz = juz);
      _revealRailButton(juz);
    }
  }

  void _revealRailButton(int juz) {
    final ctx = _railKeys[juz - 1].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(ctx,
        alignment: 0.5,
        duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 250),
        curve: const Cubic(0.32, 0.72, 0, 1));
  }

  /// Scrolls so juz [j]'s section sits just under the sticky block.
  Future<void> _jumpTo(int j) async {
    final ctx = _sectionKeys[j - 1].currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject()!;
    final viewport = RenderAbstractViewport.of(box);
    final pos = _scroll.position;
    final target =
        (viewport.getOffsetToReveal(box, 0).offset - _stickyHeight).clamp(pos.minScrollExtent, pos.maxScrollExtent);
    setState(() => _currentJuz = j);
    _revealRailButton(j);
    _jumping = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(target);
    } else {
      await _scroll.animateTo(target,
          duration: const Duration(milliseconds: 420), curve: const Cubic(0.32, 0.72, 0, 1));
    }
    _jumping = false;
  }

  void _openFirstResult() {
    final results = searchSurahs(_query);
    if (results.isNotEmpty) widget.onOpen(results.first, 1);
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.paddingOf(context).top;
    return ListenableBuilder(
      listenable: widget.learned,
      // The list stays below the status bar, so the pinned search sits right under it.
      builder: (context, _) => Padding(
        padding: EdgeInsets.only(top: safeTop),
        child: ClipRect(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
            child: CustomScrollView(
              controller: _scroll,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 9, 20, 4),
                  sliver: SliverToBoxAdapter(child: _Title(focus: widget.titleFocus)),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyDelegate(
                    height: _stickyHeight,
                    child: _StickyBar(
                      search: _search,
                      focus: _searchFocus,
                      showRail: !_searching,
                      rail: _JuzRail(
                        controller: _rail,
                        keys: _railKeys,
                        current: _currentJuz,
                        memorized: (j) => juzMemorized(j, widget.learned.isSurahLearned),
                        onTap: _jumpTo,
                      ),
                      onSubmitted: _openFirstResult,
                    ),
                  ),
                ),
                if (_searching)
                  ..._results(searchSurahs(_query))
                else
                  for (var j = 1; j <= 30; j++)
                    SliverPadding(
                      key: _sectionKeys[j - 1],
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      sliver: SliverToBoxAdapter(
                          child: _JuzSection(juz: j, learned: widget.learned, onOpen: widget.onOpen)),
                    ),
                SliverToBoxAdapter(
                  child: ValueListenableBuilder<double>(
                    valueListenable: widget.bottomInset,
                    builder: (context, inset, _) => SizedBox(height: inset + 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _results(List<int> surahs) {
    if (surahs.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
            child: Column(children: [
              Text('No surah matches “${_query.trim()}”',
                  textAlign: TextAlign.center, style: HText.inter(size: 16, weight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Try a number, a name like “Kahf”, or a meaning like “cave”.',
                  textAlign: TextAlign.center, style: HText.inter(size: 14, color: HColors.ink2)),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => _search.clear(),
                style: TextButton.styleFrom(
                  minimumSize: const Size(88, 44),
                  foregroundColor: HColors.accentDeep,
                  textStyle: HText.button(),
                ),
                child: const Text('Clear search'),
              ),
            ]),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
        sliver: SliverToBoxAdapter(
          child: _Card(children: [
            for (final s in surahs)
              _SurahRow(
                surah: s,
                learned: widget.learned.learnedCount(s),
                subtitle: 'Juz ${juzOf(s)} · ${surahMeanings[s - 1]}',
                showProgress: true,
                onTap: () => widget.onOpen(s, 1),
              ),
          ]),
        ),
      ),
    ];
  }
}

// ---------------------------------------------------------------- header

class _Title extends StatelessWidget {
  const _Title({this.focus});
  final FocusNode? focus;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(reciterName, style: HText.inter(size: 13, weight: FontWeight.w500, color: HColors.ink2)),
              const SizedBox(height: 2),
              Focus(
                focusNode: focus,
                child: Semantics(
                  header: true,
                  child: Text('Surahs', style: HText.inter(size: 24, weight: FontWeight.w700, letterSpacing: -0.4)),
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '30', style: HText.inter(size: 15, weight: FontWeight.w700, tabular: true)),
              TextSpan(text: ' juz', style: HText.inter(size: 15, color: HColors.inkMuted)),
            ])),
          ),
        ],
      );
}

class _StickyDelegate extends SliverPersistentHeaderDelegate {
  _StickyDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Once pinned, the rows scroll under it: give it the page's background.
    final pinned = shrinkOffset > 0 || overlapsContent;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: pinned ? HColors.bgTop.withValues(alpha: 0.96) : HColors.bgTop.withValues(alpha: 0),
        boxShadow: pinned ? const [BoxShadow(color: Color(0x0F14462D), offset: Offset(0, 4), blurRadius: 10)] : null,
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_StickyDelegate old) => old.height != height || old.child != child;
}

class _StickyBar extends StatelessWidget {
  const _StickyBar({
    required this.search,
    required this.focus,
    required this.showRail,
    required this.rail,
    required this.onSubmitted,
  });

  final TextEditingController search;
  final FocusNode focus;
  final bool showRail;
  final Widget rail;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: _SearchField(controller: search, focus: focus, onSubmitted: onSubmitted),
          ),
          if (showRail) rail,
        ],
      );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.focus, required this.onSubmitted});

  final TextEditingController controller;
  final FocusNode focus;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) =>
        OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c, width: w));
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        focusNode: focus,
        textInputAction: TextInputAction.search,
        autocorrect: false,
        enableSuggestions: false,
        onSubmitted: (_) => onSubmitted(),
        style: HText.inter(size: 16),
        cursorColor: HColors.accentDeep,
        decoration: InputDecoration(
          hintText: 'Name, number or meaning',
          hintStyle: HText.inter(size: 16, color: const Color(0xFF9AA3AD)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          prefixIcon: const Icon(Icons.search_rounded, size: 21, color: HColors.inkMuted),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: 'Clear search',
                    constraints: const BoxConstraints.tightFor(width: 44, height: 44),
                    onPressed: () {
                      controller.clear();
                      focus.requestFocus();
                    },
                    icon: const Icon(Icons.cancel_rounded, size: 20, color: Color(0xFFB4BCC5)),
                  ),
          ),
          enabledBorder: border(const Color(0xFFE1E6EC)),
          focusedBorder: border(HColors.accent, 1.6),
        ),
      ),
    );
  }
}

class _JuzRail extends StatelessWidget {
  const _JuzRail({
    required this.controller,
    required this.keys,
    required this.current,
    required this.memorized,
    required this.onTap,
  });

  final ScrollController controller;
  final List<GlobalKey> keys;
  final int current;
  final bool Function(int juz) memorized;
  final void Function(int juz) onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: 'Jump to juz',
        child: SizedBox(
          height: 52,
          child: ListView(
            controller: controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            children: [
              for (var j = 1; j <= 30; j++)
                Padding(
                  key: keys[j - 1],
                  padding: EdgeInsets.only(right: j < 30 ? 6 : 0),
                  child: _JuzButton(juz: j, current: j == current, memorized: memorized(j), onTap: () => onTap(j)),
                ),
            ],
          ),
        ),
      );
}

class _JuzButton extends StatelessWidget {
  const _JuzButton({required this.juz, required this.current, required this.memorized, required this.onTap});

  final int juz;
  final bool current;
  final bool memorized;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color border, Color ink) = current
        ? (HColors.accentDeep, HColors.accentDeep, Colors.white)
        : memorized
            ? (HColors.mintWash, HColors.mintRing, HColors.accentDeep)
            : (Colors.white, const Color(0xFFE1E6EC), HColors.ink2);
    return Semantics(
      button: true,
      selected: current,
      label: 'Juz $juz${memorized ? ', memorized' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: memorized && !current ? 1.4 : 1),
          ),
          child: Text('$juz', style: HText.inter(size: 15, weight: FontWeight.w600, color: ink, tabular: true)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- sections

class _JuzSection extends StatelessWidget {
  const _JuzSection({required this.juz, required this.learned, required this.onOpen});

  final int juz;
  final LearnedStore learned;
  final void Function(int surah, int ayah) onOpen;

  @override
  Widget build(BuildContext context) {
    final parts = juzParts[juz - 1];
    final first = parts.first;
    final last = parts.last;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Semantics(
            header: true,
            child:
                Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text('Juz $juz', style: HText.inter(size: 17, weight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text('الجزء ${arabicDigits(juz)}',
                  textDirection: TextDirection.rtl, style: HText.arabic(size: 17, color: HColors.accentDeep)),
            ]),
          ),
          const SizedBox(height: 2),
          Text('${surahNames[first.surah - 1]} ${first.from} – ${surahNames[last.surah - 1]} ${last.to}',
              style: HText.inter(size: 13, color: HColors.ink2, tabular: true)),
        ]),
      ),
      _Card(children: [
        for (final p in parts)
          _SurahRow(
            surah: p.surah,
            learned: learned.learnedCount(p.surah),
            subtitle: p.whole
                ? '${surahMeanings[p.surah - 1]} · ${p.ayahCount} ayahs'
                : '${p.from > 1 ? 'Continues · ' : ''}ayahs ${p.from}–${p.to}',
            showProgress: p.whole,
            onTap: () => onOpen(p.surah, p.from),
          ),
      ]),
    ]);
  }
}

/// The white list card (radius 24) with hairlines between rows.
class _Card extends StatelessWidget {
  const _Card({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(color: HColors.surface, borderRadius: BorderRadius.circular(HRadii.list)),
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 68, endIndent: 16, color: HColors.divider),
            children[i],
          ],
        ]),
      );
}

/// One surah: the star (filled by the memorized share), name, subtitle and the
/// Arabic name. Memorized surahs get a check; in-progress whole rows a bar.
class _SurahRow extends StatefulWidget {
  const _SurahRow({
    required this.surah,
    required this.learned,
    required this.subtitle,
    required this.showProgress,
    required this.onTap,
  });

  final int surah;
  final int learned;
  final String subtitle;
  final bool showProgress;
  final VoidCallback onTap;

  @override
  State<_SurahRow> createState() => _SurahRowState();
}

class _SurahRowState extends State<_SurahRow> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.surah;
    final total = surahAyahCounts[s - 1];
    final done = widget.learned >= total;
    final share = widget.learned / total;
    final inProgress = widget.learned > 0 && !done;
    final name = surahNames[s - 1];
    return Semantics(
      button: true,
      label:
          '$s, $name, ${widget.subtitle}${done ? ', memorized' : inProgress ? ', ${widget.learned} of $total ayahs memorized' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _down = true),
        onTapUp: (_) => setState(() => _down = false),
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: _down ? 0 : 200),
          color: _down ? const Color(0xFFF1F4F7) : Colors.white,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.fromLTRB(14, 10, 16, 10),
          child: Row(children: [
            StarBadge(
              size: 38,
              stroke: widget.learned == 0 ? HColors.inkMuted : HColors.accentDeep,
              fill: widget.learned == 0 ? null : HColors.mintWash,
              fillShare: done ? 1 : share,
              fillTo: HColors.starFill,
              label: Text('$s',
                  style: HText.inter(
                      size: s > 99 ? 11 : 12,
                      weight: FontWeight.w700,
                      color: widget.learned == 0 ? HColors.ink2 : HColors.numOnMint,
                      tabular: true)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(
                    child: Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: HText.inter(size: 16, weight: FontWeight.w600)),
                  ),
                  if (done) ...[
                    const SizedBox(width: 6),
                    HIcon.check(HColors.accent, size: 14, width: 3),
                  ],
                ]),
                const SizedBox(height: 2),
                Text(widget.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HText.inter(size: 13, color: HColors.ink2, tabular: true)),
                if (widget.showProgress && inProgress) ...[
                  const SizedBox(height: 7),
                  Row(children: [
                    Expanded(
                      child: SegmentedProgressBar(
                        fills: [share],
                        height: 4,
                        gap: 0,
                        color: HColors.accent,
                        trackColor: HColors.track,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${widget.learned}/$total',
                        style:
                            HText.inter(size: 12, weight: FontWeight.w600, color: HColors.accentDeep, tabular: true)),
                  ]),
                ],
              ]),
            ),
            const SizedBox(width: 10),
            Text(surahArabicNames[s - 1],
                textDirection: TextDirection.rtl, style: HText.arabic(size: 20, color: HColors.accentDeep)),
          ]),
        ),
      ),
    );
  }
}
