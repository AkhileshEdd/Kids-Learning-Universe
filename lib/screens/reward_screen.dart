import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/characters.dart';
import '../content/stickers.dart';
import '../core/music_route.dart';
import '../core/sound.dart';
import '../core/speech.dart';
import '../core/theme.dart';
import '../state/app_state.dart';
import '../widgets/bubbly_button.dart';
import '../widgets/common.dart';
import '../widgets/confetti.dart';
import '../widgets/critter.dart';
import '../widgets/space_background.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({
    super.key,
    required this.reward,
    required this.host,
    this.correct = 0,
    this.total = 0,
    this.onPlayAgain,
    this.message,
  });

  final Reward reward;
  final CharacterId host;
  final int correct;
  final int total;
  final void Function(BuildContext context)? onPlayAgain;
  final String? message;

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> with MusicAware {
  final _confetti = ConfettiController();
  int _starsShown = 0;
  bool _showSticker = false;
  final _timers = <Timer>[];

  @override
  bool get wantsMusic => false;

  int get _rating {
    if (widget.total == 0) return 3;
    final accuracy = widget.correct / widget.total;
    if (accuracy >= 0.85) return 3;
    if (accuracy >= 0.55) return 2;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _celebrate());
  }

  @override
  void dispose() {
    for (final t in _timers) {
      t.cancel();
    }
    _confetti.dispose();
    super.dispose();
  }

  void _celebrate() {
    if (!mounted) return;
    final sound = context.read<SoundService>();
    final name = context.read<AppState>().active?.name ?? 'friend';
    _confetti.burst(origin: const Offset(0.5, 0.35), count: 90);
    for (var i = 1; i <= _rating; i++) {
      _timers.add(Timer(Duration(milliseconds: 350 * i), () {
        if (!mounted) return;
        sound.play(Sfx.star);
        setState(() => _starsShown = i);
      }));
    }
    final parts = <String>[
      widget.message ?? 'Great job, $name!',
      'You earned ${widget.reward.stars} stars!',
      if (widget.reward.levelUp) 'Level up! You are getting so good at this!',
      if (widget.reward.sticker != null) 'And you got a new sticker!',
      if (widget.reward.adventureComplete) "Wow! You finished today's adventure!",
    ];
    context.read<SpeechService>().sayNow(parts.join(' '));
    if (widget.reward.sticker != null) {
      _timers.add(Timer(Duration(milliseconds: 350 * _rating + 500), () {
        if (!mounted) return;
        sound.play(Sfx.sticker);
        setState(() => _showSticker = true);
        _confetti.burst(origin: const Offset(0.78, 0.5), count: 40);
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.reward;
    final sticker = reward.sticker;
    return Scaffold(
      body: SpaceBackground(
        starCount: 60,
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Critter(id: widget.host, size: 140, mood: CritterMood.cheer),
                      const SizedBox(width: 16),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PopIn(
                            child: Text(
                              widget.message ?? 'Great job!',
                              style: KidText.display(40, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var i = 1; i <= 3; i++)
                                AnimatedScale(
                                  scale: i <= _starsShown ? 1 : 0.6,
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.elasticOut,
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: i == 2 ? 14 : 0, left: 4, right: 4),
                                    child: Icon(
                                      Icons.star_rounded,
                                      size: i == 2 ? 84 : 66,
                                      color: i <= _starsShown ? AppColors.star : Colors.white24,
                                      shadows: i <= _starsShown
                                          ? const [Shadow(color: Color(0xAAFFB300), blurRadius: 18)]
                                          : null,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              Pill(text: '+${reward.stars} ⭐', color: AppColors.starDeep, fontSize: 20),
                              if (widget.total > 0)
                                Pill(text: '${widget.correct}/${widget.total} first try', color: Colors.white24, fontSize: 16),
                              if (reward.levelUp) const Pill(text: 'Level up! 🎉', color: AppColors.success, fontSize: 18),
                              if (reward.adventureComplete)
                                const Pill(text: 'Adventure complete! 🏆 +10', color: AppColors.art, fontSize: 18),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            children: [
                              if (widget.onPlayAgain != null)
                                BubblyButton.label(
                                  label: 'Play again',
                                  icon: Icons.replay_rounded,
                                  color: AppColors.math,
                                  fontSize: 20,
                                  onTap: () {
                                    context.read<SpeechService>().stop();
                                    final nav = Navigator.of(context);
                                    final parentContext = nav.context;
                                    nav.pop();
                                    widget.onPlayAgain!(parentContext);
                                  },
                                ),
                              BubblyButton.label(
                                label: 'Continue',
                                icon: Icons.arrow_forward_rounded,
                                color: AppColors.success,
                                fontSize: 20,
                                onTap: () {
                                  context.read<SpeechService>().stop();
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (sticker != null) ...[
                        const SizedBox(width: 20),
                        AnimatedScale(
                          scale: _showSticker ? 1 : 0,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                          child: _StickerCard(sticker: sticker),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Positioned.fill(child: ConfettiLayer(controller: _confetti)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StickerCard extends StatelessWidget {
  const _StickerCard({required this.sticker});
  final String sticker;

  @override
  Widget build(BuildContext context) {
    final pack = packOf(sticker);
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.star, width: 4),
        boxShadow: const [BoxShadow(color: Color(0x66FFC93C), blurRadius: 24)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('New sticker!', style: KidText.display(18, color: AppColors.starDeep)),
          const SizedBox(height: 4),
          Floating(distance: 4, child: EmojiText(sticker, size: 72)),
          if (pack != null) Text(pack.name, style: KidText.body(13, color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}
