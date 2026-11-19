import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'glass.dart';

/// A blue glass speech bubble that fades and scales in from its [origin]
/// corner while [visible], and types its words in each time it appears.
/// Hifdth's question on Home and the signed-out card's prompt both use it.
class SpeechBubbleSlot extends StatelessWidget {
  const SpeechBubbleSlot({
    super.key,
    required this.title,
    this.body,
    required this.visible,
    required this.onTap,
    this.hint,
    this.origin = Alignment.bottomRight,
    this.maxWidth = 240,
    this.tailGap = 18,
  });

  final String title;
  final String? body;
  final bool visible;
  final VoidCallback onTap;

  /// What tapping does, for screen readers.
  final String? hint;

  /// The corner it grows from; the small square corner (the tail) sits there too.
  final Alignment origin;
  final double maxWidth;

  /// Space between the bubble and whoever is speaking.
  final double tailGap;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final ms = reduce ? Duration.zero : Duration(milliseconds: visible ? 200 : 150);
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: ms,
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: visible ? 1 : 0.92,
          alignment: origin,
          duration: ms,
          curve: Curves.easeOut,
          child: _SpeechBubble(
            title: title,
            body: body,
            visible: visible,
            onTap: onTap,
            hint: hint,
            origin: origin,
            maxWidth: maxWidth,
            tailGap: tailGap,
          ),
        ),
      ),
    );
  }
}

/// Each time it opens, the words stream in one after another, like a chat
/// reply being written.
class _SpeechBubble extends StatefulWidget {
  const _SpeechBubble({
    required this.title,
    required this.body,
    required this.visible,
    required this.onTap,
    required this.hint,
    required this.origin,
    required this.maxWidth,
    required this.tailGap,
  });

  final String title;
  final String? body;
  final bool visible;
  final VoidCallback onTap;
  final String? hint;
  final Alignment origin;
  final double maxWidth;
  final double tailGap;

  @override
  State<_SpeechBubble> createState() => _SpeechBubbleState();
}

class _SpeechBubbleState extends State<_SpeechBubble> with SingleTickerProviderStateMixin {
  /// A new word starts this often; each one fades in over [_fade].
  static const _step = 55;
  static const _fade = 160;

  /// A short breath between the title and the line under it.
  static const _pause = 140;

  static const _bodyColor = Color(0xE6FFFFFF);

  List<String> get _title => widget.title.split(' ');
  List<String> get _body => widget.body?.split(' ') ?? const [];

  int get _total => (_title.length + _body.length - 1) * _step + (_body.isEmpty ? 0 : _pause) + _fade;

  late final _typing = AnimationController(vsync: this, duration: Duration(milliseconds: _total));

  @override
  void initState() {
    super.initState();
    if (widget.visible) WidgetsBinding.instance.addPostFrameCallback((_) => mounted ? _type() : null);
  }

  @override
  void didUpdateWidget(_SpeechBubble old) {
    super.didUpdateWidget(old);
    _typing.duration = Duration(milliseconds: _total);
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
  Widget build(BuildContext context) {
    final body = widget.body;
    const round = Radius.circular(18);
    const tail = Radius.circular(4);
    final o = widget.origin;
    return Semantics(
      button: true,
      liveRegion: widget.visible,
      hidden: !widget.visible,
      label: body == null ? widget.title : '${widget.title} $body',
      hint: widget.hint,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          margin: EdgeInsets.only(bottom: widget.tailGap),
          // Hifdth's speaking blue as tinted glass, frosted only lightly so the surah
          // numbers behind still show through faintly.
          child: LiquidGlass(
            radius: 18,
            corners: BorderRadius.only(
              topLeft: o == Alignment.topLeft ? tail : round,
              topRight: o == Alignment.topRight ? tail : round,
              bottomLeft: o == Alignment.bottomLeft ? tail : round,
              bottomRight: o == Alignment.bottomRight ? tail : round,
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
                      if (body != null) ...[
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(children: _words(_body, bodyStart, ms, _bodyColor)),
                          style: HText.inter(size: 13, height: 1.3, color: _bodyColor),
                        ),
                      ],
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
}
