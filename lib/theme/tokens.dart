import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colors from the Hifdth handoff (HANDOFF.md → Design tokens).
abstract final class HColors {
  static const bgTop = Color(0xFFF4F7FB);
  static const bgBottom = Color(0xFFEEF3F7);
  static const surface = Color(0xFFFFFFFF);

  static const ink = Color(0xFF17202A);
  static const ink2 = Color(0xFF56606B);
  static const ink3 = Color(0xFF46505B);
  static const inkMuted = Color(0xFF6B7480);
  static const pillInk = Color(0xFF2B3540);
  static const navInk = Color(0xFF3B4550);

  static const accent = Color(0xFF22B567);
  static const accentDeep = Color(0xFF0F7A4D);

  /// Orb shadow tone: the accent with each channel scaled (r×.55, g×.6, b×.55).
  static const orbDeep = Color(0xFF136D39);

  static const mintWash = Color(0xFFE8F7EF);
  static const mintRing = Color(0xFF9FDCBC);
  static const mintHintRing = Color(0xFFA9DFC2);
  static const mintLight = Color(0xFFDDF5E8);
  static const mintSelected = Color(0xFFF3FBF6);
  static const starFill = Color(0xFFBFEBD3);
  static const numOnMint = Color(0xFF0B3D27);

  /// Revision, beside new memorizing (accent), in the new-vs-revision split.
  static const revision = Color(0xFF5FA88A);

  /// Inline errors: text and icon, and the card behind them.
  static const warn = Color(0xFFA23B26);
  static const warnSoft = Color(0xFFFBEDEA);

  /// Times of day on plan tasks: a warm sunrise for the morning recitation, a
  /// deep indigo night for the evening lesson. Tile gradient (light → deep),
  /// then the soft tag fill and its text.
  static const morning = [Color(0xFFFFD27A), Color(0xFFFFAE3B), Color(0xFFEE8420)];
  static const morningSoft = Color(0xFFFFF2DC);
  static const morningInk = Color(0xFF9A5200);
  static const evening = [Color(0xFF8B97FF), Color(0xFF4A57D6), Color(0xFF26308C)];
  static const eveningSoft = Color(0xFFECEEFF);
  static const eveningInk = Color(0xFF3340B0);

  static const track = Color(0xFFE3E8EE);
  static const divider = Color(0xFFEEF1F5);

  static const playerMint = Color(0xFF7FE0A8);
  static const playerMint2 = Color(0xFF8FE3B5);
  static const playerSwitchOn = Color(0xFF4CC488);
  static const playerInk = Color(0xFF0B2B1E);
}

abstract final class HRadii {
  static const homeCard = 32.0;
  static const panel = 26.0;
  static const list = 24.0;
  static const card = 22.0;
  static const nav = 34.0;
  static const row = 18.0;
}

/// Inter for UI, Amiri Quran for Arabic.
abstract final class HText {
  /// Tests turn this off so fonts aren't fetched over the network.
  static bool useGoogleFonts = true;

  static TextStyle inter({
    double size = 15,
    FontWeight weight = FontWeight.w400,
    Color color = HColors.ink,
    double? letterSpacing,
    double? height,
    bool tabular = false,
  }) {
    final style = TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      // Equal-width digits, so a number that changes doesn't nudge what's around it.
      fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    );
    return useGoogleFonts ? GoogleFonts.inter(textStyle: style) : style;
  }

  /// Button labels: 16 px on full-width buttons, 15 px on [compact] ones
  /// (two side by side, or inside a card).
  static TextStyle button({Color color = HColors.ink, bool compact = false}) =>
      inter(size: compact ? 15 : 16, weight: FontWeight.w600, color: color);

  static TextStyle arabic({
    double size = 22,
    Color color = HColors.ink,
    double? height,
  }) {
    final style = TextStyle(fontSize: size, color: color, height: height);
    return useGoogleFonts ? GoogleFonts.amiriQuran(textStyle: style) : style;
  }
}

const _arDigits = '٠١٢٣٤٥٦٧٨٩';

String arabicDigits(int n) => n.toString().split('').map((d) => _arDigits[int.parse(d)]).join();
