import 'package:flutter/material.dart';

import '../content/subjects.dart';
import '../core/theme.dart';
import 'space_background.dart';

/// "Kids Learning Universe" wordmark with a ringed planet.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.scale = 1});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PlanetView(color: AppColors.adventure, style: PlanetStyle.rings, size: 64 * scale),
        SizedBox(width: 4 * scale),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kids Learning',
              style: KidText.display(24 * scale, color: Colors.white, weight: FontWeight.w600),
            ),
            ShaderMask(
              shaderCallback: (rect) => const LinearGradient(
                colors: [Color(0xFFFFE066), Color(0xFFFF9F43), Color(0xFFFF6FB5)],
              ).createShader(rect),
              child: Text(
                'UNIVERSE',
                style: KidText.display(48 * scale, color: Colors.white).copyWith(letterSpacing: 2 * scale, height: 1),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
