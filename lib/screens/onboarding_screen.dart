import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/characters.dart';
import '../core/routes.dart';
import '../core/speech.dart';
import '../core/theme.dart';
import '../models/grade.dart';
import '../models/profile.dart';
import '../state/app_state.dart';
import '../widgets/app_logo.dart';
import '../widgets/bubbly_button.dart';
import '../widgets/common.dart';
import '../widgets/critter.dart';
import '../widgets/space_background.dart';
import 'home_screen.dart';

const avatarChoices = [
  '🦁', '🐯', '🐼', '🐨', '🐸', '🐵', '🦄', '🐙', '🦊', '🐰', '🐶', '🐱', '🐧', '🦖', '🐝', '🦋',
];

/// First-run welcome and "create your child's profile".
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _welcome = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpeechService>().sayNow("Hi! I'm Cosmo. Welcome to the Kids Learning Universe!");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SpaceBackground(
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _welcome
                ? _Welcome(key: const ValueKey('w'), onNext: () => setState(() => _welcome = false))
                : ProfileEditor(
                    key: const ValueKey('p'),
                    title: 'Who is learning today?',
                    buttonLabel: 'Start exploring!',
                    onDone: (name, avatar, grade) {
                      context.read<AppState>().addProfile(name: name, avatar: avatar, grade: grade);
                      resetTo(context, const HomeScreen());
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    Widget feature(String emoji, String label, Color color) => Container(
          margin: const EdgeInsets.only(right: 10, bottom: 10),
          padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: color.withValues(alpha: 0.6), width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              EmojiText(emoji, size: 22),
              const SizedBox(width: 6),
              Text(label, style: KidText.display(16, color: Colors.white, weight: FontWeight.w600)),
            ],
          ),
        );

    return LayoutBuilder(
      builder: (context, c) {
        final compact = c.maxHeight < 380;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SpeechBubble(
                      tail: BubbleTail.bottom,
                      child: Text("Hi! I'm Cosmo! 👋", style: KidText.display(20, weight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 6),
                    Floating(child: Critter(id: CharacterId.cosmo, size: compact ? 120 : 150, wave: true)),
                  ],
                ),
              ),
              Expanded(
                flex: 6,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppLogo(scale: compact ? 0.8 : 1),
                      const SizedBox(height: 10),
                      Text(
                        'Fun learning adventures for kids from preschool to 2nd grade.',
                        style: KidText.body(18, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        children: [
                          feature('🔤', 'Reading & phonics', AppColors.reading),
                          feature('🔢', 'Math', AppColors.math),
                          feature('🧩', 'Thinking games', AppColors.puzzles),
                          feature('📚', 'Storybooks', AppColors.stories),
                          feature('🎨', 'Art', AppColors.art),
                          feature('📴', 'Works offline', Colors.white),
                        ],
                      ),
                      const SizedBox(height: 10),
                      BubblyButton.label(label: "Let's get started", emoji: '🚀', onTap: onNext, fontSize: 22),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Name + avatar + grade form. Used for onboarding and in the parent zone.
class ProfileEditor extends StatefulWidget {
  const ProfileEditor({
    super.key,
    required this.title,
    required this.buttonLabel,
    required this.onDone,
    this.initial,
    this.dark = true,
  });

  final String title;
  final String buttonLabel;
  final ChildProfile? initial;
  final bool dark;
  final void Function(String name, String avatar, Grade grade) onDone;

  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  late final TextEditingController _name = TextEditingController(text: widget.initial?.name ?? '');
  late String _avatar = widget.initial?.avatar ?? avatarChoices.first;
  late Grade _grade = widget.initial?.grade ?? Grade.kindergarten;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fg = widget.dark ? Colors.white : AppColors.ink;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: KidText.display(28, color: fg)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.adventure, width: 4),
                ),
                child: EmojiText(_avatar, size: 54),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 16,
                      style: KidText.display(22),
                      decoration: const InputDecoration(hintText: "Child's first name", counterText: ''),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 52,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final a in avatarChoices)
                            GestureDetector(
                              onTap: () => setState(() => _avatar = a),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 50,
                                height: 50,
                                margin: const EdgeInsets.only(right: 6),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: a == _avatar ? AppColors.adventure : Colors.white.withValues(alpha: widget.dark ? 0.15 : 1),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: a == _avatar ? Colors.white : Colors.transparent, width: 2),
                                ),
                                child: EmojiText(a, size: 28),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Learning level', style: KidText.display(18, color: fg.withValues(alpha: 0.85), weight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final g in Grade.values)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _grade = g),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      decoration: BoxDecoration(
                        color: g == _grade ? AppColors.adventure : Colors.white.withValues(alpha: widget.dark ? 0.12 : 1),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: g == _grade ? Colors.white : (widget.dark ? Colors.white24 : const Color(0xFFE2DDF5)),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          EmojiText(g.emoji, size: 26),
                          const SizedBox(height: 2),
                          FittedBox(
                            child: Text(
                              g.label,
                              style: KidText.display(17, color: g == _grade ? AppColors.ink : fg),
                            ),
                          ),
                          Text(
                            g.ages,
                            style: KidText.body(13, color: (g == _grade ? AppColors.ink : fg).withValues(alpha: 0.75)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: BubblyButton.label(
              label: widget.buttonLabel,
              emoji: '✨',
              color: AppColors.success,
              onTap: () => widget.onDone(_name.text, _avatar, _grade),
            ),
          ),
        ],
      ),
    );
  }
}
