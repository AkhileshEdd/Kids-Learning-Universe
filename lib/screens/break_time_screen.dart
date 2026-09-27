import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/characters.dart';
import '../core/speech.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/bubbly_button.dart';
import '../widgets/critter.dart';
import '../widgets/space_background.dart';
import 'parents/parental_gate.dart';

/// Covers the whole app when today's learning time is used up.
class ScreenTimeGuard extends StatelessWidget {
  const ScreenTimeGuard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final limited = context.select<AppState, bool>((s) => s.limitReached);
    return Stack(
      children: [
        child,
        if (limited) const Positioned.fill(child: _BreakTime()),
      ],
    );
  }
}

class _BreakTime extends StatefulWidget {
  const _BreakTime();

  @override
  State<_BreakTime> createState() => _BreakTimeState();
}

class _BreakTimeState extends State<_BreakTime> {
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final speech = context.read<SpeechService>();
      speech.stop();
      speech.sayNow("Great learning today! It's time for a break. See you tomorrow!");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SpaceBackground(
        child: SafeArea(
          child: Center(
            child: _asking
                ? ParentalGate(
                    onResult: (ok) {
                      if (ok) context.read<AppState>().grantBonusMinutes(15);
                      setState(() => _asking = false);
                    },
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Critter(id: CharacterId.cosmo, size: 150, mood: CritterMood.happy),
                      const SizedBox(width: 24),
                      Flexible(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Time for a break! 🌙', style: KidText.display(34, color: Colors.white)),
                            const SizedBox(height: 8),
                            Text(
                              'You did so much learning today.\nLet’s rest our eyes and play outside!',
                              style: KidText.body(20, color: Colors.white70),
                            ),
                            const SizedBox(height: 20),
                            BubblyButton.label(
                              label: 'Grown-ups: +15 minutes',
                              icon: Icons.lock_rounded,
                              fontSize: 18,
                              color: const Color(0xFF3B2A86),
                              onTap: () => setState(() => _asking = true),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
