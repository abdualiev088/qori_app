import 'package:flutter/material.dart';

import '../data/surah_meta.dart';
import '../data/surahs.dart';
import '../player/player_controller.dart';
import '../theme/tokens.dart';
import 'icons.dart';
import 'ribbed_glass.dart';
import 'star.dart';
import '../l10n/l10n.dart';

/// The bar above the nav while a surah is active and the player is closed:
/// the surah, where playback is, play/pause and ×. Tapping the left side
/// reopens the player ([onOpen]); × stops and clears it ([onClose]).
class MiniPlayer extends StatefulWidget {
  const MiniPlayer(
      {super.key, required this.controller, required this.visible, required this.onOpen, required this.onClose});

  final PlayerController controller;
  final bool visible;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  static const height = 60.0;

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  /// The last surah shown, so the bar keeps its content while it fades out after ×.
  int? _surah;
  String _summary = '';

  PlayerController get c => widget.controller;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final show = widget.visible;
    // Enters with a 10 px rise over 220 ms ease-out; leaves in 150 ms ease-in.
    final duration = reduce ? Duration.zero : Duration(milliseconds: show ? 220 : 150);
    final curve = show ? Curves.easeOut : Curves.easeIn;
    return IgnorePointer(
      ignoring: !show,
      child: ExcludeSemantics(
        excluding: !show,
        child: AnimatedOpacity(
          opacity: show ? 1 : 0,
          duration: duration,
          curve: curve,
          child: AnimatedSlide(
            offset: show ? Offset.zero : const Offset(0, 10 / MiniPlayer.height),
            duration: duration,
            curve: curve,
            child: ListenableBuilder(
              listenable: c,
              builder: (context, _) {
                // Frozen while hidden, so the bar doesn't flip to a newly tapped surah as it fades.
                if (c.surah != null && show) {
                  _surah = c.surah;
                  _summary = c.summary;
                }
                final s = _surah;
                return s == null ? const SizedBox(height: MiniPlayer.height) : _bar(s);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _bar(int s) {
    const radius = BorderRadius.all(Radius.circular(20));
    final white72 = Colors.white.withValues(alpha: 0.72);
    final name = surahNames[s - 1];
    return DecoratedBox(
      decoration: const BoxDecoration(
        borderRadius: radius,
        boxShadow: [BoxShadow(color: Color(0x4D08241A), offset: Offset(0, 8), blurRadius: 20)],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: CustomPaint(
          painter: RibbedGlassPainter.player,
          child: Container(
            height: MiniPlayer.height,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: HColors.playerMint.withValues(alpha: 0.22)),
            ),
            child: Stack(children: [
              Row(children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    label: context.l10n.openPlayerLabel(name, _summary),
                    excludeSemantics: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onOpen,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Row(children: [
                          StarBadge(
                            size: 36,
                            stroke: HColors.playerMint,
                            fill: Colors.white.withValues(alpha: 0.08),
                            label: Text('$s',
                                style: HText.inter(
                                    size: s > 99 ? 11 : 12,
                                    weight: FontWeight.w700,
                                    color: Colors.white,
                                    tabular: true)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Flexible(
                                    child: Text(name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: HText.inter(size: 15, weight: FontWeight.w600, color: Colors.white)),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(surahArabicNames[s - 1],
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.fade,
                                        textDirection: TextDirection.rtl,
                                        style: HText.arabic(size: 15, height: 1.2, color: HColors.playerMint2)),
                                  ),
                                ]),
                                const SizedBox(height: 1),
                                Text(_summary,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: HText.inter(size: 12, color: white72, tabular: true)),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ),
                ),
                _PlayPause(c: c),
                Semantics(
                  button: true,
                  label: context.l10n.stopAndClose(name),
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.onClose,
                    child: SizedBox.square(
                      dimension: 44,
                      child: Icon(Icons.close_rounded, size: 22, color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ]),
              // Progress through the current ayah's repeats.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 2,
                child: ValueListenableBuilder<double>(
                  valueListenable: c.progress,
                  builder: (context, p, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: c.surah == null ? 0 : c.overallProgress(p),
                    child: const ColoredBox(color: HColors.playerMint),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _PlayPause extends StatelessWidget {
  const _PlayPause({required this.c});
  final PlayerController c;

  @override
  Widget build(BuildContext context) {
    final enabled = c.hasAudio;
    return Semantics(
      button: true,
      enabled: enabled,
      label: c.playing ? context.l10n.pause : context.l10n.play,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? c.toggle : null,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Opacity(
              opacity: enabled ? 1 : 0.35,
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment(-0.3, -0.44),
                    radius: 0.97,
                    colors: [Color(0xFFD4FBE4), HColors.playerMint2, HColors.playerSwitchOn],
                    stops: [0, .5, 1],
                  ),
                ),
                child: c.playing
                    ? HIcon.pause(HColors.playerInk)
                    : Padding(padding: const EdgeInsets.only(left: 2), child: HIcon.play(HColors.playerInk)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
