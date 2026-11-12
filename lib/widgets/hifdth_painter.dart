import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'hifdth_mood.dart';

/// Hifdth in a 112 px box: a 104 px orb with a radial gradient, a soft
/// shadow, a light rim at the bottom, two pill eyes and (when not happy) brows.
class HifdthPainter extends CustomPainter {
  const HifdthPainter(this.style);

  final MoodStyle style;

  static const _orb = 104.0;
  static const _eye = Size(9, 18);
  static const _eyeGap = 16.0;
  static const _eyeTop = 54.0; // from the top of the orb: centered in the 82 px below a 22 px top padding
  static const _brow = Size(13, 3.5);
  static const _browGap = 6.0; // between the happy eye top and the brow's center

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final orb = Rect.fromCircle(center: center, radius: _orb / 2);

    canvas.drawCircle(
      center + const Offset(0, 14),
      _orb / 2,
      BoxShadow(color: style.accent.withAlpha(0x61), blurRadius: 30).toPaint(), // accent at 38%
    );
    canvas.drawCircle(
      center,
      _orb / 2,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.3, -0.44),
          radius: 0.97,
          colors: style.body,
          stops: const [0, .45, 1],
        ).createShader(orb),
    );
    canvas.drawCircle(
      center,
      _orb / 2,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)],
          stops: [0, .3],
        ).createShader(orb),
    );

    final white = Paint()..color = const Color(0xFFFFFFFF);
    final eyeY = orb.top + _eyeTop + _eye.height / 2 + style.eyeOffsetY;
    final browY = eyeY - _eye.height / 2 - _browGap + style.browOffsetY;
    final browPaint = Paint()..color = Color.fromRGBO(255, 255, 255, style.browOpacity);
    final dx = (_eyeGap + _eye.width) / 2;

    for (final (side, angle) in [(-1, style.browLeft), (1, style.browRight)]) {
      final x = center.dx + side * dx;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(x, eyeY),
            width: _eye.width * style.eyeScaleX,
            height: _eye.height * style.eyeScaleY,
          ),
          const Radius.circular(5),
        ),
        white,
      );
      if (style.browOpacity <= 0) continue;
      canvas
        ..save()
        ..translate(x, browY)
        ..rotate(angle * math.pi / 180)
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: _brow.width, height: _brow.height),
            Radius.circular(_brow.height / 2),
          ),
          browPaint,
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(HifdthPainter old) => old.style != style;
}
