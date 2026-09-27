import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/stickers.dart';
import '../core/music_route.dart';
import '../core/sound.dart';
import '../core/speech.dart';
import '../core/theme.dart';
import '../premium/premium_service.dart';
import '../state/app_state.dart';
import '../widgets/bubbly_button.dart';
import '../widgets/common.dart';
import 'activity_launcher.dart';

/// Collection of stickers earned by finishing activities and books.
class StickerBookScreen extends StatefulWidget {
  const StickerBookScreen({super.key});

  @override
  State<StickerBookScreen> createState() => _StickerBookScreenState();
}

class _StickerBookScreenState extends State<StickerBookScreen> with MusicAware {
  int _pack = 0;

  @override
  bool get wantsMusic => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SpeechService>().sayNow('Your sticker book! Finish games and books to collect more stickers.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AppState>().active!;
    final premium = context.watch<PremiumService>().isPremium;
    final pack = stickerPacks[_pack];
    final got = pack.stickers.where(profile.stickers.contains).length;
    final locked = pack.premium && !premium;
    return Scaffold(
      body: PlayfulBackground(
        color: pack.color,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Row(
                  children: [
                    RoundButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).pop(), semanticLabel: 'Back'),
                    const SizedBox(width: 12),
                    Text('My Sticker Book', style: KidText.display(26, color: pack.color.darken(0.15))),
                    const Spacer(),
                    Pill(text: '${profile.stickers.length} stickers', color: pack.color, fontSize: 16),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 6, 6, 12),
                        itemCount: stickerPacks.length,
                        itemBuilder: (context, i) {
                          final p = stickerPacks[i];
                          final selected = i == _pack;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: BubblyButton(
                              onTap: () {
                                context.read<SoundService>().play(Sfx.page);
                                setState(() => _pack = i);
                              },
                              color: selected ? p.color : Colors.white,
                              height: 64,
                              depth: 4,
                              radius: 20,
                              padding: EdgeInsets.zero,
                              gradient: false,
                              sound: null,
                              semanticLabel: p.name,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Center(child: EmojiText(p.cover, size: 34)),
                                  if (p.premium && !premium) const Positioned(right: -4, top: -8, child: LockBadge(size: 24)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(6, 4, 16, 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: pack.color.withValues(alpha: 0.35), width: 4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(pack.name, style: KidText.display(22, color: pack.color.darken(0.1))),
                                const Spacer(),
                                Text('$got / ${pack.stickers.length}', style: KidText.display(18, color: AppColors.inkSoft)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: locked
                                  ? _LockedPack(pack: pack)
                                  : GridView.count(
                                      crossAxisCount: 6,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      children: [
                                        for (final s in pack.stickers)
                                          profile.stickers.contains(s)
                                              ? GestureDetector(
                                                  onTap: () => context.read<SoundService>().play(Sfx.pop),
                                                  child: PopIn(
                                                    child: Container(
                                                      alignment: Alignment.center,
                                                      decoration: BoxDecoration(
                                                        color: pack.color.pastel,
                                                        borderRadius: BorderRadius.circular(18),
                                                      ),
                                                      child: FittedBox(
                                                        child: Padding(padding: const EdgeInsets.all(6), child: EmojiText(s, size: 48)),
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Container(
                                                  alignment: Alignment.center,
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFF2F0F8),
                                                    borderRadius: BorderRadius.circular(18),
                                                    border: Border.all(color: const Color(0xFFE2DEF0), width: 2),
                                                  ),
                                                  child: Text('?', style: KidText.display(30, color: const Color(0xFFCBC6DE))),
                                                ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedPack extends StatelessWidget {
  const _LockedPack({required this.pack});
  final StickerPack pack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: 0.5,
            child: Wrap(
              spacing: 6,
              children: [for (final s in pack.stickers.take(6)) EmojiText(s, size: 36)],
            ),
          ),
          const SizedBox(height: 12),
          Text('A Premium sticker pack!', style: KidText.display(20)),
          const SizedBox(height: 10),
          BubblyButton.label(
            label: 'Ask a grown-up',
            icon: Icons.lock_open_rounded,
            color: AppColors.starDeep,
            fontSize: 18,
            onTap: () => showPremiumLock(context, what: '${pack.name} stickers'),
          ),
        ],
      ),
    );
  }
}
