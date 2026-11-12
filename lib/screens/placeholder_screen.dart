import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// "My Method" and "Settings" until they're designed.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({super.key, required this.title, required this.bottomInset});

  final String title;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 9;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, top < 56 ? 56 : top, 16, bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: HText.inter(size: 24, weight: FontWeight.w700, letterSpacing: -0.4)),
          const SizedBox(height: 4),
          Text('Coming soon.', style: HText.inter(size: 15, color: HColors.ink2)),
        ],
      ),
    );
  }
}
