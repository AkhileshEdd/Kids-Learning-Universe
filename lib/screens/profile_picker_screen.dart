import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes.dart';
import '../core/theme.dart';
import '../premium/premium_service.dart';
import '../state/app_state.dart';
import '../widgets/bubbly_button.dart';
import '../widgets/common.dart';
import '../widgets/space_background.dart';
import 'home_screen.dart';
import 'onboarding_screen.dart';
import 'parents/parental_gate.dart';
import 'parents/paywall_screen.dart';

class ProfilePickerScreen extends StatelessWidget {
  const ProfilePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final premium = context.watch<PremiumService>().isPremium;
    final canAdd = state.profiles.length < state.maxProfiles(premium);
    return Scaffold(
      body: SpaceBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              Text("Who's learning today?", style: KidText.display(32, color: Colors.white)),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        for (final (i, p) in state.profiles.indexed)
                          PopIn(
                            delay: Duration(milliseconds: 80 * i),
                            child: _ProfileBubble(
                              emoji: p.avatar,
                              label: p.name,
                              sub: p.grade.label,
                              color: AppColors.playful[i % AppColors.playful.length],
                              onTap: () {
                                state.selectProfile(p);
                                resetTo(context, const HomeScreen());
                              },
                            ),
                          ),
                        _ProfileBubble(
                          emoji: '➕',
                          label: 'Add child',
                          sub: canAdd ? 'Grown-ups' : 'Premium',
                          color: Colors.white24,
                          onTap: () async {
                            if (!await showParentalGate(context) || !context.mounted) return;
                            if (!canAdd) {
                              pushScreen(context, const PaywallScreen(reason: 'Add up to 5 children with Premium.'));
                              return;
                            }
                            pushScreen(context, const _AddChildScreen());
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileBubble extends StatelessWidget {
  const _ProfileBubble({required this.emoji, required this.label, required this.sub, required this.color, required this.onTap});

  final String emoji;
  final String label;
  final String sub;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BubblyButton(
            onTap: onTap,
            color: color,
            width: 128,
            height: 128,
            radius: 64,
            padding: EdgeInsets.zero,
            semanticLabel: label,
            child: EmojiText(emoji, size: 66),
          ),
          const SizedBox(height: 8),
          Text(label, style: KidText.display(22, color: Colors.white)),
          Text(sub, style: KidText.body(15, color: Colors.white70)),
        ],
      ),
    );
  }
}

class _AddChildScreen extends StatelessWidget {
  const _AddChildScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SpaceBackground(
        child: SafeArea(
          child: Stack(
            children: [
              ProfileEditor(
                title: 'Add a child',
                buttonLabel: 'Add',
                onDone: (name, avatar, grade) {
                  context.read<AppState>().addProfile(name: name, avatar: avatar, grade: grade);
                  resetTo(context, const HomeScreen());
                },
              ),
              Positioned(
                right: 16,
                top: 8,
                child: RoundButton(icon: Icons.close_rounded, onTap: () => Navigator.of(context).pop()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
