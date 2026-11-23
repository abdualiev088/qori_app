import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// A row of equal segments, each filled 0–1. Used for the player's per-repetition
/// progress (4 px) and the surah list rows.
class SegmentedProgressBar extends StatelessWidget {
  const SegmentedProgressBar({
    super.key,
    required this.fills,
    this.height = 6,
    this.gap = 6,
    this.color = HColors.accent,
    this.trackColor = HColors.track,
  });

  final List<double> fills;
  final double height;
  final double gap;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(height / 2);
    return Row(
      children: [
        for (final (i, f) in fills.indexed) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: ClipRRect(
              borderRadius: radius,
              child: SizedBox(
                height: height,
                child: ColoredBox(
                  color: trackColor,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: f.clamp(0.0, 1.0),
                      heightFactor: 1,
                      child: ColoredBox(color: color),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
