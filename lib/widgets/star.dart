import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The 8-pointed ayah star from the design (16-point polygon in a 36×36 box).
class StarPainter extends CustomPainter {
  const StarPainter({this.fill, required this.stroke, this.strokeWidth = 1.5, this.fillShare, this.fillTo});

  final Color? fill;
  final Color stroke;
  final double strokeWidth;

  /// When set (0–1), [fill] covers the whole star and [fillTo] rises from the
  /// bottom by this share, like a glass filling up.
  final double? fillShare;
  final Color? fillTo;

  static Path _path() {
    const big = 17.0, small = big * 0.7654, c = 18.0;
    final p = Path();
    for (var k = 0; k < 16; k++) {
      final a = -math.pi / 2 + k * math.pi / 8;
      final r = k.isOdd ? small : big;
      final pt = Offset(c + r * math.cos(a), c + r * math.sin(a));
      k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  static final _star = _path();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 36, size.height / 36);
    if (fill != null) canvas.drawPath(_star, Paint()..color = fill!);
    final share = fillShare;
    if (share != null && share > 0 && fillTo != null) {
      canvas
        ..save()
        ..clipRect(Rect.fromLTRB(0, 36 * (1 - share.clamp(0.0, 1.0)), 36, 36))
        ..drawPath(_star, Paint()..color = fillTo!)
        ..restore();
    }
    canvas.drawPath(
      _star,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = strokeWidth
        ..color = stroke,
    );
  }

  @override
  bool shouldRepaint(StarPainter old) =>
      old.fill != fill ||
      old.stroke != stroke ||
      old.strokeWidth != strokeWidth ||
      old.fillShare != fillShare ||
      old.fillTo != fillTo;
}

/// A star with a label in the middle (ayah number badge, inline end marker).
class StarBadge extends StatelessWidget {
  const StarBadge({
    super.key,
    required this.size,
    required this.label,
    this.fill,
    required this.stroke,
    this.strokeWidth = 1.5,
    this.fillShare,
    this.fillTo,
  });

  final double size;
  final Widget label;
  final Color? fill;
  final Color stroke;
  final double strokeWidth;
  final double? fillShare;
  final Color? fillTo;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter:
              StarPainter(fill: fill, stroke: stroke, strokeWidth: strokeWidth, fillShare: fillShare, fillTo: fillTo),
          child: Center(child: label),
        ),
      );
}
