import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A glossy, 3D-looking open mushaf with a green play badge: the "How it
/// works" icon. Drawn in code (Hifdth's speaking blues for the cover), so it's
/// sharp at any size.
class MushafPlayIcon extends StatelessWidget {
  const MushafPlayIcon({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) =>
      ExcludeSemantics(child: CustomPaint(size: Size.square(size), painter: const _MushafPainter()));
}

class _MushafPainter extends CustomPainter {
  const _MushafPainter();

  static const _coverLight = Color(0xFF6FB2FF);
  static const _cover = Color(0xFF3B8EF0);
  static const _coverDeep = Color(0xFF1D58B5);
  static const _paper = Color(0xFFFFFFFF);
  static const _paperShade = Color(0xFFDDE8F6);

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn on a 56×56 grid, scaled to the size asked for.
    final s = size.width / 56;
    canvas.save();
    canvas.scale(s);

    // Soft contact shadow under the book.
    canvas.drawOval(
      const Rect.fromLTWH(8, 44, 40, 8),
      Paint()
        ..color = const Color(0x401D58B5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Cover: a thick slab, its front edge darker than its top, so it reads as depth.
    final slab = RRect.fromLTRBR(6, 18, 50, 46, const Radius.circular(7));
    canvas.drawRRect(slab.shift(const Offset(0, 3)), Paint()..color = _coverDeep);
    canvas.drawRRect(
      slab,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_coverLight, _cover, _coverDeep],
          stops: [0, .55, 1],
        ).createShader(slab.outerRect),
    );

    // Pages: two leaves bowing up from the spine.
    Path leaf(bool left) {
      final p = Path();
      if (left) {
        p
          ..moveTo(28, 40)
          ..cubicTo(22, 36, 15, 36, 9, 38)
          ..lineTo(9, 16)
          ..cubicTo(15, 13, 22, 13, 28, 17)
          ..close();
      } else {
        p
          ..moveTo(28, 40)
          ..cubicTo(34, 36, 41, 36, 47, 38)
          ..lineTo(47, 16)
          ..cubicTo(41, 13, 34, 13, 28, 17)
          ..close();
      }
      return p;
    }

    for (final left in [true, false]) {
      final p = leaf(left);
      canvas.drawShadow(p, const Color(0xFF0B2A5C), 2, false);
      canvas.drawPath(
        p,
        Paint()
          ..shader = LinearGradient(
            begin: left ? Alignment.centerLeft : Alignment.centerRight,
            end: left ? Alignment.centerRight : Alignment.centerLeft,
            colors: const [_paper, _paper, _paperShade],
            stops: const [0, .6, 1],
          ).createShader(const Rect.fromLTWH(9, 13, 38, 27)),
      );
      // Lines of text.
      final line = Paint()
        ..color = const Color(0xFFB9CBE3)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 4; i++) {
        final y = 20.5 + i * 4.2;
        left
            ? canvas.drawLine(Offset(12.5, y), Offset(24.5, y + .6), line)
            : canvas.drawLine(Offset(31.5, y + .6), Offset(43.5, y), line);
      }
    }
    // The spine's crease.
    canvas.drawLine(
      const Offset(28, 17),
      const Offset(28, 40),
      Paint()
        ..color = const Color(0x332B5A9A)
        ..strokeWidth = 1,
    );

    // Play badge: a glossy green ball, bottom right.
    const c = Offset(42, 39);
    const r = 10.5;
    canvas.drawCircle(
      c + const Offset(0, 2),
      r,
      Paint()
        ..color = const Color(0x55136D39)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.35, -0.45),
          radius: 1,
          colors: [Color(0xFFB8F5CF), Color(0xFF22B567), Color(0xFF136D39)],
          stops: [0, .55, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xCCFFFFFF),
    );
    // Triangle, nudged right so it looks centred.
    final tri = Path()
      ..moveTo(c.dx - 3, c.dy - 4.6)
      ..lineTo(c.dx + 5, c.dy)
      ..lineTo(c.dx - 3, c.dy + 4.6)
      ..close();
    canvas.drawPath(
      tri,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..strokeJoin = StrokeJoin.round,
    );
    // Gloss on the ball.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 2.5),
      math.pi * 1.1,
      math.pi * 0.55,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = const Color(0x8CFFFFFF),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MushafPainter old) => false;
}
