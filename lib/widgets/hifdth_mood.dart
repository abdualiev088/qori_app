import 'dart:ui' show lerpDouble;

import 'package:flutter/painting.dart';

import '../theme/tokens.dart';
import 'ribbed_glass.dart';

enum HifdthMood { happy, worried, sad }

/// How Hifdth moves while idle. [period] is one full loop.
enum IdleMotion {
  bounce(Duration(milliseconds: 2400)),
  sway(Duration(milliseconds: 3000)),
  droop(Duration(milliseconds: 3200));

  const IdleMotion(this.period);

  final Duration period;
}

/// Picks Hifdth's mood from how far behind today's plan the user is.
///
/// TODO: replace these placeholder rules with the real schedule logic.
HifdthMood moodFor({required int sessionsBehind}) => switch (sessionsBehind) {
      <= 0 => HifdthMood.happy, // on schedule
      1 => HifdthMood.worried, // one session late
      _ => HifdthMood.sad, // sessions missed
    };

/// Everything about Hifdth and the home card that changes with the mood.
class MoodStyle {
  const MoodStyle({
    required this.body,
    required this.accent,
    required this.eyeScaleX,
    required this.eyeScaleY,
    required this.eyeOffsetY,
    required this.browLeft,
    required this.browRight,
    required this.browOffsetY,
    required this.browOpacity,
    required this.idle,
    required this.status,
    required this.background,
    required this.border,
  });

  /// Body radial gradient: highlight (top left), middle, edge.
  final List<Color> body;

  /// The mood's middle color: glow, status dot, progress segments; the ribs are tinted to its hue.
  final Color accent;

  final double eyeScaleX, eyeScaleY;

  /// Pixels the eyes move down from their happy position.
  final double eyeOffsetY;

  /// Brow rotation in degrees (positive is clockwise).
  final double browLeft, browRight;

  /// Pixels the brows move down from their resting place above the eyes.
  final double browOffsetY;
  final double browOpacity;

  final IdleMotion idle;
  final String status;

  /// The ribbed card fill behind everything.
  final RibbedGlassPainter background;
  final Color border;

  static const _happyBorder = Color(0xFFDDEEE4);

  /// Today's design, unchanged.
  static const happy = MoodStyle(
    body: [Color(0xFFB8F5CF), HColors.accent, HColors.orbDeep],
    accent: HColors.accent,
    eyeScaleX: 1,
    eyeScaleY: 1,
    eyeOffsetY: 0,
    browLeft: 0,
    browRight: 0,
    browOffsetY: 0,
    browOpacity: 0,
    idle: IdleMotion.bounce,
    status: "Hifdth is happy, you're on track",
    background: RibbedGlassPainter.home,
    border: _happyBorder,
  );

  static final worried = _tinted(
    body: const [Color(0xFFFBE29A), Color(0xFFE0B33A), Color(0xFFB88A1E)],
    eyeScaleX: 1.05,
    eyeScaleY: 0.55,
    eyeOffsetY: 0,
    browLeft: -12,
    browRight: 12,
    browOffsetY: 4,
    idle: IdleMotion.sway,
    status: 'Hifdth is getting worried…',
  );

  static final sad = _tinted(
    body: const [Color(0xFFF7A9A3), Color(0xFFDE5B53), Color(0xFFB43A33)],
    eyeScaleX: 0.85,
    eyeScaleY: 0.4,
    eyeOffsetY: 14,
    browLeft: -18, // inner ends raised, steeper than worried
    browRight: 18,
    browOffsetY: 6,
    idle: IdleMotion.droop,
    status: 'Hifdth is sad, sessions missed',
  );

  /// A mood whose card is Home's mint card turned to the hue of its middle color.
  static MoodStyle _tinted({
    required List<Color> body,
    required double eyeScaleX,
    required double eyeScaleY,
    required double eyeOffsetY,
    required double browLeft,
    required double browRight,
    required double browOffsetY,
    required IdleMotion idle,
    required String status,
  }) {
    final accent = body[1];
    final turn = HSLColor.fromColor(accent).hue - HSLColor.fromColor(HColors.accent).hue;
    return MoodStyle(
      body: body,
      accent: accent,
      eyeScaleX: eyeScaleX,
      eyeScaleY: eyeScaleY,
      eyeOffsetY: eyeOffsetY,
      browLeft: browLeft,
      browRight: browRight,
      browOffsetY: browOffsetY,
      browOpacity: 1,
      idle: idle,
      status: status,
      background: RibbedGlassPainter.home.rotated(turn),
      border: rotateHue(_happyBorder, turn),
    );
  }

  static MoodStyle of(HifdthMood mood) => switch (mood) {
        HifdthMood.happy => happy,
        HifdthMood.worried => worried,
        HifdthMood.sad => sad,
      };

  /// Blends two styles. Colors follow [t]; eyes and brows follow [shapeT]
  /// when given, so they can use a springier curve. Text and idle motion switch halfway.
  static MoodStyle lerp(MoodStyle a, MoodStyle b, double t, {double? shapeT}) {
    final s = shapeT ?? t;
    double d(double x, double y) => lerpDouble(x, y, s)!;
    return MoodStyle(
      body: [for (var i = 0; i < 3; i++) Color.lerp(a.body[i], b.body[i], t)!],
      accent: Color.lerp(a.accent, b.accent, t)!,
      eyeScaleX: d(a.eyeScaleX, b.eyeScaleX),
      eyeScaleY: d(a.eyeScaleY, b.eyeScaleY),
      eyeOffsetY: d(a.eyeOffsetY, b.eyeOffsetY),
      browLeft: d(a.browLeft, b.browLeft),
      browRight: d(a.browRight, b.browRight),
      browOffsetY: d(a.browOffsetY, b.browOffsetY),
      browOpacity: d(a.browOpacity, b.browOpacity).clamp(0.0, 1.0),
      idle: t < 0.5 ? a.idle : b.idle,
      status: t < 0.5 ? a.status : b.status,
      background: RibbedGlassPainter.lerp(a.background, b.background, t),
      border: Color.lerp(a.border, b.border, t)!,
    );
  }
}
