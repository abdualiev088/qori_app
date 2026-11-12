import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// The design's SVG icons, drawn from their original paths.
class HIcon extends StatelessWidget {
  const HIcon._(this._body, {required this.size});

  final String _body;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: SvgPicture.string(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">$_body</svg>',
          width: size,
          height: size,
        ),
      );

  static String _hex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static String _stroke(Color c, double w, {bool round = true}) =>
      'fill="none" stroke="${_hex(c)}" stroke-opacity="${c.a}" stroke-width="$w" '
      'stroke-linecap="round"${round ? ' stroke-linejoin="round"' : ''}';

  static String _fill(Color c) => 'fill="${_hex(c)}" fill-opacity="${c.a}"';

  factory HIcon.profile(Color c) => HIcon._(
      '<g ${_stroke(c, 1.8)}><circle cx="12" cy="8" r="4"/><path d="M4 21c1.5-4 4.5-6 8-6s6.5 2 8 6"/></g>',
      size: 20);

  factory HIcon.check(Color c, {double size = 16, double width = 2.4}) =>
      HIcon._('<path ${_stroke(c, width)} d="M5 12.5l4.5 4.5L19 7.5"/>', size: size);

  factory HIcon.sparkle(Color c) => HIcon._(
      '<path ${_stroke(c, 2, round: false)} d="M12 3v3M12 18v3M3 12h3M18 12h3M5.6 5.6l2.1 2.1M16.3 16.3l2.1 2.1M5.6 18.4l2.1-2.1M16.3 7.7l2.1-2.1"/>',
      size: 16);

  factory HIcon.home(Color c, {required bool active}) => HIcon._(
      '<g ${_stroke(c, active ? 2 : 1.8)}><path d="M3.5 10.5L12 3.5l8.5 7"/><path d="M5.5 9v10.5h13V9"/><path d="M10 19.5v-5h4v5"/></g>',
      size: 22);

  factory HIcon.player(Color c, {required bool active}) => HIcon._(
      '<g ${_stroke(c, active ? 2 : 1.8)}><circle cx="12" cy="12" r="9"/><path d="M10 8.5l5.5 3.5-5.5 3.5z"/></g>',
      size: 22);

  factory HIcon.method(Color c, {required bool active}) => HIcon._(
      '<g ${_stroke(c, active ? 2 : 1.8)}><path d="M12 6.5C10 5 7 4.5 3.5 5v13c3.5-.5 6.5 0 8.5 1.5 2-1.5 5-2 8.5-1.5V5c-3.5-.5-6.5 0-8.5 1.5z"/><path d="M12 6.5v13"/></g>',
      size: 22);

  factory HIcon.settings(Color c, {required bool active}) => HIcon._(
      '<g ${_stroke(c, active ? 2 : 1.8)}><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.7 1.7 0 0 0-1.8-.3 1.7 1.7 0 0 0-1 1.5V21a2 2 0 1 1-4 0v-.1a1.7 1.7 0 0 0-1.1-1.5 1.7 1.7 0 0 0-1.8.3l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1a1.7 1.7 0 0 0 .3-1.8 1.7 1.7 0 0 0-1.5-1H3a2 2 0 1 1 0-4h.1a1.7 1.7 0 0 0 1.5-1.1 1.7 1.7 0 0 0-.3-1.8l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1a1.7 1.7 0 0 0 1.8.3H9a1.7 1.7 0 0 0 1-1.5V3a2 2 0 1 1 4 0v.1a1.7 1.7 0 0 0 1 1.5 1.7 1.7 0 0 0 1.8-.3l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.7 1.7 0 0 0-.3 1.8V9a1.7 1.7 0 0 0 1.5 1H21a2 2 0 1 1 0 4h-.1a1.7 1.7 0 0 0-1.5 1z"/></g>',
      size: 22);

  factory HIcon.previous(Color c) => HIcon._(
      '<g ${_fill(c)}><rect x="5" y="5" width="2.4" height="14" rx="1.2"/><path d="M19 6.2v11.6a1 1 0 0 1-1.55.83l-8.4-5.8a1 1 0 0 1 0-1.66l8.4-5.8A1 1 0 0 1 19 6.2z"/></g>',
      size: 20);

  factory HIcon.next(Color c) => HIcon._(
      '<g ${_fill(c)}><rect x="16.6" y="5" width="2.4" height="14" rx="1.2"/><path d="M5 6.2v11.6a1 1 0 0 0 1.55.83l8.4-5.8a1 1 0 0 0 0-1.66l-8.4-5.8A1 1 0 0 0 5 6.2z"/></g>',
      size: 20);

  factory HIcon.play(Color c) => HIcon._(
      '<path ${_fill(c)} d="M7 5.6v12.8a1 1 0 0 0 1.53.85l10.3-6.4a1 1 0 0 0 0-1.7L8.53 4.75A1 1 0 0 0 7 5.6z"/>',
      size: 20);

  factory HIcon.pause(Color c) => HIcon._(
      '<g ${_fill(c)}><rect x="6" y="5" width="4.2" height="14" rx="1.3"/><rect x="13.8" y="5" width="4.2" height="14" rx="1.3"/></g>',
      size: 20);
}
