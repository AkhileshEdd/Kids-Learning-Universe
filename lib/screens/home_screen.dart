import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/activities.dart';
import '../content/books.dart';
import '../content/characters.dart';
import '../content/subjects.dart';
import '../core/music_route.dart';
import '../core/routes.dart';
import '../core/sound.dart';
import '../core/speech.dart';
import '../core/theme.dart';
import '../models/profile.dart';
import '../premium/premium_service.dart';
import '../state/app_state.dart';
import '../widgets/bubbly_button.dart';
import '../widgets/common.dart';
import '../widgets/critter.dart';
import '../widgets/space_background.dart';
import 'adventure_screen.dart';
import 'library_screen.dart';
import 'parents/parent_zone_screen.dart';
import 'parents/parental_gate.dart';
import 'profile_picker_screen.dart';
import 'sticker_book_screen.dart';
import 'subject_screen.dart';

/// The universe map: pick a planet (subject) or start Today's Adventure.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with MusicAware {
  static String? _greetedProfile;
  final _talk = TalkingController();

  @override
  bool get wantsMusic => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _greet());
  }

  @override
  void dispose() {
    _talk.dispose();
    super.dispose();
  }

  void _greet({bool force = false}) {
    if (!mounted) return;
    final p = context.read<AppState>().active;
    if (p == null || (!force && _greetedProfile == p.id)) return;
    _greetedProfile = p.id;
    final line = 'Hi ${p.name}! Where shall we explore today?';
    context.read<SpeechService>().sayNow(line);
    _talk.talkFor(line);
  }

  void _openSubject(Subject s) {
    context.read<SoundService>().play(Sfx.whoosh);
    if (s.id == SubjectId.stories) {
      pushScreen(context, const LibraryScreen());
    } else {
      pushScreen(context, SubjectScreen(subject: s));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final profile = state.active;
    if (profile == null) return const Scaffold(backgroundColor: AppColors.spaceTop);
    return Scaffold(
      body: SpaceBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final compact = c.maxHeight < 420;
              return Column(
                children: [
                  _TopBar(profile: profile),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: min(320, c.maxWidth * 0.36),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 8, 12),
                            child: _AdventurePanel(profile: profile, talk: _talk, compact: compact, onCosmoTap: () => _greet(force: true)),
                          ),
                        ),
                        Expanded(child: _PlanetStrip(onOpen: _openSubject, height: c.maxHeight - 70)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.profile});
  final ChildProfile profile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => pushScreen(context, const ProfilePickerScreen()),
            child: Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: EmojiText(profile.avatar, size: 28),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(profile.name, style: KidText.display(18, color: Colors.white)),
                      Text(profile.grade.label, style: KidText.body(12, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          StarPill(stars: profile.stars, dark: true),
          const SizedBox(width: 10),
          BubblyButton(
            onTap: () => pushScreen(context, const StickerBookScreen()),
            color: AppColors.art,
            depth: 4,
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            semanticLabel: 'Sticker book',
            child: Row(
              children: [
                const EmojiText('📒', size: 22),
                const SizedBox(width: 6),
                Text('${profile.stickers.length}', style: KidText.display(18, color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GrownUpButton(onPassed: () => pushScreen(context, const ParentZoneScreen())),
        ],
      ),
    );
  }
}

class _AdventurePanel extends StatelessWidget {
  const _AdventurePanel({required this.profile, required this.talk, required this.compact, required this.onCosmoTap});

  final ChildProfile profile;
  final TalkingController talk;
  final bool compact;
  final VoidCallback onCosmoTap;

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumService>().isPremium;
    final adventure = context.read<AppState>().adventureFor(profile, premium: premium);
    final done = adventure.done.length;
    final total = adventure.steps.length;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: onCosmoTap,
                child: ValueListenableBuilder<bool>(
                  valueListenable: talk,
                  builder: (context, talking, _) => Critter(
                    id: CharacterId.cosmo,
                    size: compact ? 92 : 120,
                    talking: talking,
                    wave: talking,
                    mood: adventure.complete ? CritterMood.happy : CritterMood.idle,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: compact ? 50 : 70),
                  child: SpeechBubble(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      adventure.complete ? 'You finished today’s adventure! 🏆' : 'Hi ${profile.name}! Let’s explore! ✨',
                      style: KidText.display(compact ? 15 : 17, weight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => pushScreen(context, const AdventureScreen()),
          child: Container(
            padding: EdgeInsets.all(compact ? 10 : 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFC93C), Color(0xFFFF8A3D)]),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 3),
              boxShadow: [BoxShadow(color: const Color(0xFFFF8A3D).withValues(alpha: 0.45), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Floating(distance: 3, child: EmojiText('🚀', size: 30)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text("Today's Adventure", style: KidText.display(compact ? 19 : 22, color: Colors.white)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final step in adventure.steps)
                      Expanded(child: _StepDot(step: step, done: adventure.done.contains(step))),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  alignment: Alignment.center,
                  child: Text(
                    adventure.complete ? 'All done! 🏆' : (done == 0 ? "Let's go!" : 'Keep going! $done/$total'),
                    style: KidText.display(18, color: const Color(0xFFE8730C)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({required this.step, required this.done});
  final String step;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final emoji = stepEmoji(step);
    return Center(
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: done ? AppColors.success : Colors.white.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
        ),
        child: done ? const Icon(Icons.check_rounded, color: Colors.white, size: 26) : EmojiText(emoji, size: 22),
      ),
    );
  }
}

String stepEmoji(String step) {
  if (step.startsWith('book:')) return '📖';
  return activityById(step)?.emoji ?? '⭐';
}

String stepTitle(String step) {
  if (step.startsWith('book:')) return bookById(step.substring(5))?.title ?? 'A story';
  return activityById(step)?.title ?? step;
}

class _PlanetStrip extends StatelessWidget {
  const _PlanetStrip({required this.onOpen, required this.height});
  final ValueChanged<Subject> onOpen;
  final double height;

  @override
  Widget build(BuildContext context) {
    final list = subjects.values.toList();
    final planetSize = (height * 0.38).clamp(86.0, 170.0);
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(right: 24, left: 8),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final s = list[i];
        return Padding(
          padding: EdgeInsets.only(top: i.isOdd ? height * 0.16 : 0, bottom: i.isOdd ? 0 : height * 0.16),
          child: PopIn(
            delay: Duration(milliseconds: 120 * i),
            child: Floating(
              phase: i * 0.23,
              distance: 5,
              period: Duration(milliseconds: 3200 + i * 300),
              child: _PlanetTile(subject: s, size: planetSize, onTap: () => onOpen(s)),
            ),
          ),
        );
      },
    );
  }
}

class _PlanetTile extends StatefulWidget {
  const _PlanetTile({required this.subject, required this.size, required this.onTap});
  final Subject subject;
  final double size;
  final VoidCallback onTap;

  @override
  State<_PlanetTile> createState() => _PlanetTileState();
}

class _PlanetTileState extends State<_PlanetTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.subject;
    final size = widget.size;
    return Semantics(
      button: true,
      label: s.planetName,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.92 : 1,
          duration: const Duration(milliseconds: 120),
          child: SizedBox(
            width: size * 1.5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: size * 1.5,
                  height: size * 1.5,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: 0,
                        child: PlanetView(color: s.color, style: s.style, size: size, emoji: s.emoji),
                      ),
                      Positioned(
                        top: 0,
                        right: size * 0.1,
                        child: Critter(id: s.host, size: size * 0.5, showBody: false),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: s.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                  child: Text(s.name, style: KidText.display(size * 0.15 + 4, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
