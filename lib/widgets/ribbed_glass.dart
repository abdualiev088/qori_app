import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

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

  EllipseGlow _mapColors(Color Function(Color) f) =>
      EllipseGlow(cx: cx, cy: cy, rx: rx, ry: ry, colors: colors.map(f).toList(), stops: stops);

  @override
  bool operator ==(Object other) =>
      other is EllipseGlow &&
      other.cx == cx &&
      other.cy == cy &&
      other.rx == rx &&
      other.ry == ry &&
      listEquals(other.colors, colors) &&
      listEquals(other.stops, stops);

  @override
  int get hashCode => Object.hash(cx, cy, rx, ry, Object.hashAll(colors), Object.hashAll(stops));
}

/// Turns [c] around the color wheel by [degrees], keeping its saturation, lightness and alpha.
Color rotateHue(Color c, double degrees) {
  if (degrees == 0) return c;
  final hsl = HSLColor.fromColor(c);
  return hsl.withHue((hsl.hue + degrees) % 360).toColor();
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

  /// The same fill with every color turned [degrees] around the color wheel
  /// (Home's mint card tinted to another mood).
  RibbedGlassPainter rotated(double degrees) {
    if (degrees == 0) return this;
    Color f(Color c) => rotateHue(c, degrees);
    return RibbedGlassPainter(
      base: LinearGradient(begin: base.begin, end: base.end, colors: base.colors.map(f).toList(), stops: base.stops),
      glows: [for (final g in glows) g._mapColors(f)],
      stripe: stripe.map(f).toList(),
    );
  }

  /// Blends two fills with the same layout (one made from the other with [rotated]).
  static RibbedGlassPainter lerp(RibbedGlassPainter a, RibbedGlassPainter b, double t) {
    if (t == 0) return a;
    if (t == 1) return b;
    List<Color> mix(List<Color> x, List<Color> y) => [for (var i = 0; i < x.length; i++) Color.lerp(x[i], y[i], t)!];
    return RibbedGlassPainter(
      base: LinearGradient.lerp(a.base, b.base, t)!,
      glows: [
        for (var i = 0; i < a.glows.length; i++)
          EllipseGlow(
            cx: a.glows[i].cx,
            cy: a.glows[i].cy,
            rx: a.glows[i].rx,
            ry: a.glows[i].ry,
            colors: mix(a.glows[i].colors, b.glows[i].colors),
            stops: a.glows[i].stops,
          ),
      ],
      stripe: mix(a.stripe, b.stripe),
    );
  }

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
  bool shouldRepaint(RibbedGlassPainter old) =>
      old.base != base || !listEquals(old.glows, glows) || !listEquals(old.stripe, stripe);
}
