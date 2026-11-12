import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// A CSS `radial-gradient(ellipse rx ry at cx cy, …)`; all values are fractions of the box.
class EllipseGlow {
  const EllipseGlow({
    required this.cx,
    required this.cy,
    required this.rx,
    required this.ry,
    required this.colors,
    required this.stops,
  });

  final double cx, cy, rx, ry;
  final List<Color> colors;
  final List<double> stops;
}

/// The "ribbed glass" fill: a vertical base gradient, soft elliptical glows,
/// and 10 px vertical stripes on top.
class RibbedGlassPainter extends CustomPainter {
  const RibbedGlassPainter({
    required this.base,
    required this.glows,
    required this.stripe,
  });

  /// Main card on Home.
  static const home = RibbedGlassPainter(
    base: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFFF9FCFA), Color(0xFFE6F5EC), Color(0xFFD3EFDF)],
      stops: [0, .55, 1],
    ),
    glows: [
      EllipseGlow(cx: .92, cy: 1, rx: .60, ry: .45, colors: [Color(0xFFA9E4C5), Color(0x00E2F5EB)], stops: [0, .70]),
      EllipseGlow(
          cx: .5,
          cy: .38,
          rx: .75,
          ry: .55,
          colors: [Color(0xFF8FDDB4), Color(0xFFBFEBD3), Color(0x00E2F5EB)],
          stops: [0, .40, .75]),
    ],
    stripe: [Color(0xB3FFFFFF), Color(0x26FFFFFF), Color(0x1A126E46), Color(0x26FFFFFF), Color(0xB3FFFFFF)],
  );

  /// Dark player panel.
  static const player = RibbedGlassPainter(
    base: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF08241A), Color(0xFF0E3B29)],
    ),
    glows: [
      EllipseGlow(
          cx: .5,
          cy: .7,
          rx: .70,
          ry: .90,
          colors: [Color(0xFF2E9C69), Color(0xFF176B47), Color(0x000B2B1E)],
          stops: [0, .45, .90]),
    ],
    stripe: [Color(0x1AFFFFFF), Color(0x05FFFFFF), Color(0x29000000), Color(0x05FFFFFF), Color(0x1AFFFFFF)],
  );

  final LinearGradient base;
  final List<EllipseGlow> glows;

  /// Colors at 0, 3, 6, 8 and 10 px of each 10 px stripe.
  final List<Color> stripe;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..shader = base.createShader(rect));

    for (final g in glows) {
      final center = Offset(size.width * g.cx, size.height * g.cy);
      final rx = size.width * g.rx, ry = size.height * g.ry;
      canvas
        ..save()
        ..translate(center.dx, center.dy)
        ..scale(1, ry / rx);
      final k = rx / ry;
      canvas.drawRect(
        Rect.fromLTWH(-center.dx, -center.dy * k, size.width, size.height * k),
        Paint()..shader = ui.Gradient.radial(Offset.zero, rx, g.colors, g.stops),
      );
      canvas.restore();
    }

    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(10, 0),
          stripe,
          const [0, .3, .6, .8, 1],
          TileMode.repeated,
        ),
    );
  }

  @override
  bool shouldRepaint(RibbedGlassPainter old) => false;
}
