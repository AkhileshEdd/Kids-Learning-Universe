import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/characters.dart';
import '../core/routes.dart';
import '../state/app_state.dart';
import '../widgets/app_logo.dart';
import '../widgets/common.dart';
import '../widgets/critter.dart';
import '../widgets/space_background.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'profile_picker_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _left = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2200), _continue);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _continue() {
    if (_left || !mounted) return;
    _left = true;
    final state = context.read<AppState>();
    final Widget next;
    if (!state.hasProfiles) {
      next = const OnboardingScreen();
    } else if (state.profiles.length > 1) {
      next = const ProfilePickerScreen();
    } else {
      next = const HomeScreen();
    }
    replaceScreen(context, next);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _continue,
        child: SpaceBackground(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const PopIn(
                  child: Floating(child: Critter(id: CharacterId.cosmo, size: 150, wave: true)),
                ),
                const SizedBox(width: 24),
                PopIn(delay: const Duration(milliseconds: 250), child: AppLogo(scale: 1.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
