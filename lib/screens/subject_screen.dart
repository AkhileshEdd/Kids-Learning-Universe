import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../content/activities.dart';
import '../content/subjects.dart';
import '../core/music_route.dart';
import '../core/speech.dart';
import '../core/theme.dart';
import '../models/grade.dart';
import '../premium/premium_service.dart';
import '../state/app_state.dart';
import '../widgets/bubbly_button.dart';
import '../widgets/common.dart';
import '../widgets/critter.dart';
import 'activity_launcher.dart';

/// A planet: the list of activities for one subject.
class SubjectScreen extends StatefulWidget {
  const SubjectScreen({super.key, required this.subject});
  final Subject subject;

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> with MusicAware {
  late Grade _grade = context.read<AppState>().active?.grade ?? Grade.kindergarten;
  final _talk = TalkingController();

  @override
  bool get wantsMusic => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hello());
  }

  @override
  void dispose() {
    _talk.dispose();
    super.dispose();
  }

  void _hello() {
    if (!mounted) return;
    final host = widget.subject.hostInfo;
    final line = "Welcome to ${widget.subject.planetName}! I'm ${host.name}. Pick a game!";
    context.read<SpeechService>().sayNow(line);
    _talk.talkFor(line);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.subject;
    final state = context.watch<AppState>();
    final premium = context.watch<PremiumService>().isPremium;
    final profile = state.active!;
    final list = activitiesFor(s.id, _grade);
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
                    EmojiText(s.emoji, size: 30),
                    const SizedBox(width: 8),
                    Flexible(child: Text(s.planetName, style: KidText.display(26, color: s.color.darken(0.15)), overflow: TextOverflow.ellipsis)),
                    const Spacer(),
                    for (final g in Grade.values)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _LevelChip(
                          grade: g,
                          selected: g == _grade,
                          color: s.color,
                          onTap: () => setState(() => _grade = g),
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
                    SizedBox(
                      width: 170,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          SpeechBubble(
                            tail: BubbleTail.bottom,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Text(s.tagline, textAlign: TextAlign.center, style: KidText.display(15, weight: FontWeight.w600)),
                          ),
                          GestureDetector(
                            onTap: _hello,
                            child: ValueListenableBuilder<bool>(
                              valueListenable: _talk,
                              builder: (context, talking, _) =>
                                  Critter(id: s.host, size: 128, talking: talking, wave: talking),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                    Expanded(
                      child: list.isEmpty
                          ? Center(child: Text('More games coming soon!', style: KidText.display(22)))
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 190,
                                mainAxisExtent: 158,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: list.length,
                              itemBuilder: (context, i) {
                                final a = list[i];
                                return PopIn(
                                  delay: Duration(milliseconds: 50 * i),
                                  child: ActivityCard(
                                    activity: a,
                                    locked: a.premium && !premium,
                                    stars: profile.skills[a.skillKey]?.masteryStars ?? 0,
                                    isNew: (profile.plays[a.id] ?? 0) == 0,
                                    onTap: () => openActivity(context, a, grade: _grade),
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

class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.grade, required this.selected, required this.color, required this.onTap});
  final Grade grade;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.white : color.withValues(alpha: 0.3), width: 2),
        ),
        child: Text(grade.short, style: KidText.display(16, color: selected ? Colors.white : color.darken(0.1))),
      ),
    );
  }
}

class ActivityCard extends StatelessWidget {
  const ActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
    this.locked = false,
    this.stars = 0,
    this.isNew = false,
  });

  final ActivityDef activity;
  final VoidCallback onTap;
  final bool locked;
  final int stars;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final color = activity.subjectInfo.color;
    return BubblyButton(
      onTap: onTap,
      color: Colors.white,
      depth: 6,
      radius: 26,
      padding: const EdgeInsets.all(10),
      gradient: false,
      semanticLabel: activity.title,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: RadialGradient(colors: [color.lighten(0.15), color]),
                  shape: BoxShape.circle,
                ),
                child: EmojiText(activity.emoji, size: 38),
              ),
              const SizedBox(height: 6),
              Text(
                activity.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: KidText.display(17, color: AppColors.ink),
              ),
              if (activity.isScored)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: i < stars ? AppColors.star : const Color(0xFFE6E2F3),
                      ),
                  ],
                ),
            ],
          ),
          if (locked) const Positioned(right: -2, top: -2, child: LockBadge()),
          if (isNew && !locked)
            const Positioned(left: -2, top: -2, child: Pill(text: 'NEW', color: AppColors.success, fontSize: 12)),
        ],
      ),
    );
  }
}
