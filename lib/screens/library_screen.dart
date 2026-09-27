import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/books.dart';
import '../content/characters.dart';
import '../content/subjects.dart';
import '../core/music_route.dart';
import '../core/speech.dart';
import '../core/theme.dart';
import '../premium/premium_service.dart';
import '../state/app_state.dart';
import '../widgets/bubbly_button.dart';
import '../widgets/common.dart';
import '../widgets/critter.dart';
import '../widgets/scene_view.dart';
import 'activity_launcher.dart';

/// Story Moon: the storybook library.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with MusicAware {
  BookKind? _filter;

  @override
  bool get wantsMusic => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<SpeechService>().sayNow("Hoo hoo! I'm Luna. Pick a book, and I'll read it to you!");
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = subjects[SubjectId.stories]!;
    final state = context.watch<AppState>();
    final premium = context.watch<PremiumService>().isPremium;
    final profile = state.active!;
    final list = books.where((b) => _filter == null || b.kind == _filter).toList()
      ..sort((a, b) {
        // Books for the child's grade first, then free before premium.
        final fa = a.fitsGrade(profile.grade) ? 0 : 1;
        final fb = b.fitsGrade(profile.grade) ? 0 : 1;
        if (fa != fb) return fa - fb;
        return (a.premium ? 1 : 0) - (b.premium ? 1 : 0);
      });
    return Scaffold(
      body: PlayfulBackground(
        color: s.color,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Row(
                  children: [
                    RoundButton(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).pop(), semanticLabel: 'Back'),
                    const SizedBox(width: 12),
                    const EmojiText('📚', size: 30),
                    const SizedBox(width: 8),
                    Text('Story Moon', style: KidText.display(26, color: s.color.darken(0.15))),
                    const Spacer(),
                    for (final (label, kind) in [('All', null), ('Stories', BookKind.story), ('Facts', BookKind.nonfiction)])
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          label: Text(label, style: KidText.display(15, color: _filter == kind ? Colors.white : s.color)),
                          selected: _filter == kind,
                          selectedColor: s.color,
                          backgroundColor: Colors.white,
                          showCheckmark: false,
                          side: BorderSide(color: s.color.withValues(alpha: 0.3), width: 2),
                          onSelected: (_) => setState(() => _filter = kind),
                        ),
                      ),
                    const SizedBox(width: 10),
                    StarPill(stars: profile.stars),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(left: 12, bottom: 12),
                      child: Critter(id: CharacterId.luna, size: 120),
                    ),
                    Expanded(
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(12, 12, 20, 20),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 16),
                        itemBuilder: (context, i) {
                          final b = list[i];
                          return PopIn(
                            delay: Duration(milliseconds: 60 * i),
                            child: BookCover(
                              book: b,
                              locked: b.premium && !premium,
                              read: profile.booksRead.contains(b.id),
                              onTap: () => openBook(context, b),
                            ),
                          );
                        },
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

class BookCover extends StatelessWidget {
  const BookCover({super.key, required this.book, required this.onTap, this.locked = false, this.read = false});

  final Book book;
  final VoidCallback onTap;
  final bool locked;
  final bool read;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        final w = h * 0.78;
        return BubblyButton(
          onTap: onTap,
          color: book.color,
          width: w,
          height: h - 8,
          radius: 22,
          padding: const EdgeInsets.all(8),
          semanticLabel: book.title,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SceneView(scene: book.cover, animate: false),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    book.title,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: KidText.display(17, color: Colors.white),
                  ),
                  Text(
                    book.kind == BookKind.story ? 'Story' : 'Facts',
                    style: KidText.body(12, color: Colors.white70),
                  ),
                ],
              ),
              if (locked) const Positioned(right: -4, top: -4, child: LockBadge()),
              if (read)
                const Positioned(
                  left: -4,
                  top: -4,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.success,
                    child: Icon(Icons.check_rounded, color: Colors.white, size: 18),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
