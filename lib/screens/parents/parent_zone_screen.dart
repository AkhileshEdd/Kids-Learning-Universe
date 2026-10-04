import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../../content/activities.dart';
import '../../content/books.dart';
import '../../content/subjects.dart';
import '../../core/routes.dart';
import '../../core/sound.dart';
import '../../core/speech.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';
import '../../models/settings.dart';
import '../../premium/premium_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../onboarding_screen.dart';
import '../splash_screen.dart';
import 'paywall_screen.dart';

/// Grown-ups area: progress reports, profiles, settings and Premium.
class ParentZoneScreen extends StatefulWidget {
  const ParentZoneScreen({super.key});

  @override
  State<ParentZoneScreen> createState() => _ParentZoneScreenState();
}

class _ParentZoneScreenState extends State<ParentZoneScreen> {
  int _tab = 0;
  String? _childId;

  @override
  void initState() {
    super.initState();
    context.read<SpeechService>().stop();
    context.read<SoundService>().wantMusic(false);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final child = state.profiles.firstWhere(
      (p) => p.id == _childId,
      orElse: () => state.active ?? state.profiles.first,
    );
    const tabs = [
      (Icons.insights_rounded, 'Progress'),
      (Icons.face_rounded, 'Children'),
      (Icons.tune_rounded, 'Settings'),
      (Icons.workspace_premium_rounded, 'Premium'),
      (Icons.info_outline_rounded, 'About'),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4FC),
      body: SafeArea(
        child: Row(
          children: [
            Container(
              width: 168,
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          tooltip: 'Back to the app',
                        ),
                        Text('Grown-ups', style: KidText.display(18)),
                      ],
                    ),
                  ),
                  for (final (i, t) in tabs.indexed)
                    ListTile(
                      dense: true,
                      selected: i == _tab,
                      selectedTileColor: AppColors.stories.pastel,
                      selectedColor: AppColors.stories,
                      leading: Icon(t.$1),
                      title: Text(t.$2, style: KidText.body(15, weight: FontWeight.w600, color: i == _tab ? AppColors.stories : AppColors.ink)),
                      onTap: () => setState(() => _tab = i),
                    ),
                ],
              ),
            ),
            Expanded(
              child: switch (_tab) {
                0 => _ProgressTab(
                    child: child,
                    profiles: state.profiles,
                    onPick: (p) => setState(() => _childId = p.id),
                  ),
                1 => const _ChildrenTab(),
                2 => const _SettingsTab(),
                3 => const _PremiumTab(),
                _ => const _AboutTab(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x10000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: child,
    );
  }
}

String _minutes(int seconds) {
  final m = seconds ~/ 60;
  if (m < 60) return '$m min';
  return '${m ~/ 60} h ${m % 60} min';
}

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes} min ago';
  if (d.inDays < 1) return '${d.inHours} h ago';
  if (d.inDays == 1) return 'yesterday';
  return '${d.inDays} days ago';
}

class _ProgressTab extends StatelessWidget {
  const _ProgressTab({required this.child, required this.profiles, required this.onPick});
  final ChildProfile child;
  final List<ChildProfile> profiles;
  final ValueChanged<ChildProfile> onPick;

  @override
  Widget build(BuildContext context) {
    Widget stat(String emoji, String value, String label) => Expanded(
          child: _Card(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            child: Column(
              children: [
                EmojiText(emoji, size: 26),
                const SizedBox(height: 4),
                Text(value, style: KidText.display(22)),
                Text(label, textAlign: TextAlign.center, style: KidText.body(12, color: AppColors.inkSoft)),
              ],
            ),
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Text('Progress report', style: KidText.display(26)),
            const Spacer(),
            for (final p in profiles)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: ChoiceChip(
                  label: Text('${p.avatar} ${p.name}', style: KidText.body(14, weight: FontWeight.w600)),
                  selected: p.id == child.id,
                  onSelected: (_) => onPick(p),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text('${child.name} · ${child.grade.label}', style: KidText.body(15, color: AppColors.inkSoft)),
        const SizedBox(height: 14),
        Row(
          children: [
            stat('⏱️', _minutes(child.secondsToday), 'learning today'),
            const SizedBox(width: 10),
            stat('📅', _minutes(child.secondsInLastDays(7)), 'last 7 days'),
            const SizedBox(width: 10),
            stat('🎮', '${child.totalActivities}', 'activities done'),
            const SizedBox(width: 10),
            stat('📚', '${child.booksRead.length}', 'books read'),
            const SizedBox(width: 10),
            stat('⭐', '${child.stars}', 'stars earned'),
            const SizedBox(width: 10),
            stat('🏆', '${child.adventuresCompleted}', 'adventures'),
          ],
        ),
        const SizedBox(height: 18),
        Text('Skills', style: KidText.display(20)),
        const SizedBox(height: 8),
        for (final subject in [SubjectId.reading, SubjectId.math, SubjectId.puzzles]) ...[
          _SkillSection(subject: subjects[subject]!, child: child),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 8),
        Text('Recent activity', style: KidText.display(20)),
        const SizedBox(height: 8),
        _Card(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: child.history.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No activities yet. Time to explore!', style: KidText.body(15, color: AppColors.inkSoft)),
                )
              : Column(
                  children: [
                    for (final h in child.history.take(12)) _HistoryRow(log: h),
                  ],
                ),
        ),
      ],
    );
  }
}

class _SkillSection extends StatelessWidget {
  const _SkillSection({required this.subject, required this.child});
  final Subject subject;
  final ChildProfile child;

  @override
  Widget build(BuildContext context) {
    final list = activities
        .where((a) => a.subject == subject.id && a.isScored && (a.fitsGrade(child.grade) || (child.skills[a.skillKey]?.sessions ?? 0) > 0))
        .toList();
    final played = list.where((a) => (child.skills[a.skillKey]?.sessions ?? 0) > 0).toList();
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              EmojiText(subject.emoji, size: 22),
              const SizedBox(width: 8),
              Text(subject.name, style: KidText.display(18, color: subject.color.darken(0.1))),
              const Spacer(),
              Text('${played.length} of ${list.length} skills practiced', style: KidText.body(13, color: AppColors.inkSoft)),
            ],
          ),
          if (played.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('Not started yet.', style: KidText.body(14, color: AppColors.inkSoft)),
            ),
          for (final a in played) ...[
            const SizedBox(height: 10),
            _SkillRow(activity: a, stats: child.skills[a.skillKey]!, color: subject.color),
          ],
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.activity, required this.stats, required this.color});
  final ActivityDef activity;
  final SkillStats stats;
  final Color color;

  @override
  Widget build(BuildContext context) {
    const levels = ['Easy', 'Medium', 'Hard'];
    return Row(
      children: [
        SizedBox(width: 30, child: EmojiText(activity.emoji, size: 20)),
        SizedBox(width: 150, child: Text(activity.title, style: KidText.body(14, weight: FontWeight.w600))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: stats.accuracy,
              minHeight: 12,
              color: color,
              backgroundColor: color.withValues(alpha: 0.15),
            ),
          ),
        ),
        SizedBox(
          width: 60,
          child: Text('${(stats.accuracy * 100).round()}%', textAlign: TextAlign.right, style: KidText.body(14, weight: FontWeight.w600)),
        ),
        SizedBox(
          width: 90,
          child: Text(levels[stats.level.clamp(0, 2)], textAlign: TextAlign.right, style: KidText.body(13, color: AppColors.inkSoft)),
        ),
        SizedBox(
          width: 80,
          child: Text('${stats.sessions}× played', textAlign: TextAlign.right, style: KidText.body(13, color: AppColors.inkSoft)),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.log});
  final ActivityLog log;

  @override
  Widget build(BuildContext context) {
    String title;
    String emoji;
    if (log.activityId.startsWith('book:')) {
      final b = bookById(log.activityId.substring(5));
      title = 'Read “${b?.title ?? 'a book'}”';
      emoji = '📖';
    } else {
      final a = activityById(log.activityId);
      title = a?.title ?? log.activityId;
      emoji = a?.emoji ?? '⭐';
    }
    return ListTile(
      dense: true,
      leading: EmojiText(emoji, size: 22),
      title: Text(title, style: KidText.body(15, weight: FontWeight.w600)),
      subtitle: Text(_ago(log.when), style: KidText.body(12, color: AppColors.inkSoft)),
      trailing: Text(
        log.total > 0 ? '${log.correct}/${log.total} first try · +${log.stars} ⭐' : '+${log.stars} ⭐',
        style: KidText.body(13),
      ),
    );
  }
}

class _ChildrenTab extends StatelessWidget {
  const _ChildrenTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final premium = context.watch<PremiumService>().isPremium;
    final max = state.maxProfiles(premium);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Children', style: KidText.display(26)),
        const SizedBox(height: 4),
        Text('${state.profiles.length} of $max profiles${premium ? '' : ' (Premium allows up to ${PremiumLimits.premiumProfiles})'}',
            style: KidText.body(14, color: AppColors.inkSoft)),
        const SizedBox(height: 12),
        for (final p in state.profiles)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _Card(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.cream, child: Text(p.avatar, style: KidText.emoji(24))),
                title: Text(p.name, style: KidText.display(18)),
                subtitle: Text('${p.grade.label} · ${p.stars} stars · ${p.stickers.length} stickers', style: KidText.body(13, color: AppColors.inkSoft)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit',
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () => _edit(context, p),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.oops),
                      onPressed: state.profiles.length <= 1 ? null : () => _delete(context, p),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () {
              if (state.profiles.length >= max) {
                pushScreen(context, const PaywallScreen(reason: 'Add more children with Premium.'));
              } else {
                _edit(context, null);
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add a child'),
          ),
        ),
      ],
    );
  }

  void _edit(BuildContext context, ChildProfile? p) {
    pushScreen(
      context,
      Scaffold(
        backgroundColor: const Color(0xFFF6F4FC),
        appBar: AppBar(title: Text(p == null ? 'Add a child' : 'Edit ${p.name}')),
        body: ProfileEditor(
          title: p == null ? 'New explorer' : 'Edit profile',
          buttonLabel: 'Save',
          initial: p,
          dark: false,
          onDone: (name, avatar, grade) {
            final state = context.read<AppState>();
            if (p == null) {
              state.addProfile(name: name, avatar: avatar, grade: grade);
            } else {
              state.updateProfile(p, name: name, avatar: avatar, grade: grade);
            }
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, ChildProfile p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${p.name}?'),
        content: const Text('All progress, stars and stickers for this child will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && context.mounted) context.read<AppState>().deleteProfile(p);
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final s = state.settings;
    final speech = context.read<SpeechService>();
    final sound = context.read<SoundService>();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Settings', style: KidText.display(26)),
        const SizedBox(height: 12),
        _Card(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Sound effects'),
                value: s.soundEffects,
                onChanged: (v) {
                  state.updateSettings((x) => x.soundEffects = v);
                  sound.sfxEnabled = v;
                },
              ),
              SwitchListTile(
                title: const Text('Background music'),
                value: s.music,
                onChanged: (v) {
                  state.updateSettings((x) => x.music = v);
                  sound.musicEnabled = v;
                },
              ),
              SwitchListTile(
                title: const Text('Narrator voice'),
                subtitle: const Text('Reads instructions and questions aloud (recommended for pre-readers).'),
                value: s.voice,
                onChanged: (v) {
                  state.updateSettings((x) => x.voice = v);
                  speech.enabled = v;
                },
              ),
              ListTile(
                title: const Text('Voice speed'),
                subtitle: Slider(
                  value: s.speechRate,
                  min: 0.3,
                  max: 0.6,
                  divisions: 6,
                  label: s.speechRate <= 0.36 ? 'Slow' : (s.speechRate >= 0.52 ? 'Fast' : 'Normal'),
                  onChanged: (v) => state.updateSettings((x) => x.speechRate = v),
                  onChangeEnd: (v) {
                    speech.setRate(v);
                    speech.sayNow('This is how fast I talk.');
                  },
                ),
              ),
              ListTile(
                title: const Text('Narrator accent'),
                subtitle: Wrap(
                  spacing: 6,
                  children: [
                    for (final e in AppSettings.voiceLocales.entries)
                      ChoiceChip(
                        label: Text(e.value),
                        selected: s.voiceLocale == e.key,
                        onSelected: (_) {
                          state.updateSettings((x) => x.voiceLocale = e.key);
                          speech.englishLocale = e.key;
                          speech.sayNow('Hello! Let’s learn together.');
                        },
                      ),
                  ],
                ),
              ),
              SwitchListTile(
                title: const Text('Read storybooks in Spanish by default'),
                subtitle: const Text('Kids can switch between English and Español inside every book.'),
                value: s.readAloudSpanish,
                onChanged: (v) => state.updateSettings((x) => x.readAloudSpanish = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text('Screen time', style: KidText.display(20)),
        const SizedBox(height: 8),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily learning limit (per child)', style: KidText.body(15, weight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('When the time is up, the app shows a friendly “time for a break” screen.',
                  style: KidText.body(13, color: AppColors.inkSoft)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  for (final m in const [0, 15, 30, 45, 60, 90])
                    ChoiceChip(
                      label: Text(m == 0 ? 'No limit' : '$m min'),
                      selected: s.dailyLimitMinutes == m,
                      onSelected: (_) => state.updateSettings((x) => x.dailyLimitMinutes = m),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _Card(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reset all data', style: KidText.body(15, weight: FontWeight.w600)),
                    Text('Deletes every profile and all progress on this device.', style: KidText.body(13, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Reset everything?'),
                      content: const Text('This cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset')),
                      ],
                    ),
                  );
                  if (ok == true && context.mounted) {
                    await context.read<AppState>().resetAll();
                    if (context.mounted) resetTo(context, const SplashScreen());
                  }
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PremiumTab extends StatelessWidget {
  const _PremiumTab();

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumService>();
    final plan = premium.plan;
    final planName = plan == null ? null : (premium.productFor(plan)?.title ?? plan.name);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Premium', style: KidText.display(26)),
        const SizedBox(height: 12),
        _Card(
          child: Row(
            children: [
              EmojiText(premium.isPremium ? '👑' : '🔒', size: 40),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      switch (plan) {
                        null => 'Free plan',
                        PremiumPlan.lifetime => 'Premium for life',
                        _ => 'Premium: $planName subscription',
                      },
                      style: KidText.display(20),
                    ),
                    Text(
                      premium.isPremium
                          ? 'All games, books, sticker packs and profiles are unlocked. Billing is handled by Google Play.'
                          : 'Upgrade to unlock every game, book and sticker pack. Payments go through Google Play.',
                      style: KidText.body(14, color: AppColors.inkSoft),
                    ),
                  ],
                ),
              ),
              if (plan != PremiumPlan.lifetime)
                FilledButton(
                  onPressed: () => pushScreen(context, const PaywallScreen()),
                  child: Text(plan == null ? 'See plans' : 'Change plan'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton.icon(
              onPressed: premium.busy
                  ? null
                  : () async {
                      final result = await premium.restore();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(switch (result) {
                            true => 'Premium restored! 🎉',
                            false => 'No Premium purchase found for this Google account.',
                            null => 'Couldn’t reach Google Play. Check your connection and try again.',
                          }),
                        ),
                      );
                    },
              icon: const Icon(Icons.restore_rounded),
              label: const Text('Restore purchases'),
            ),
            if (premium.hasSubscription)
              OutlinedButton.icon(
                onPressed: () => openManageSubscriptions(context, premium),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Manage or cancel subscription'),
              ),
            if (premium.isTestMode && premium.isPremium)
              OutlinedButton.icon(
                onPressed: premium.resetTestPurchase,
                icon: const Icon(Icons.science_outlined),
                label: const Text('Test mode: turn Premium off'),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          'Premium is linked to the Google account used in the Play Store, so it also works on your other '
          'Android devices. Subscriptions renew automatically until cancelled in Google Play.',
          style: KidText.body(13, color: AppColors.inkSoft),
        ),
      ],
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab();

  @override
  Widget build(BuildContext context) {
    Widget point(String emoji, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmojiText(emoji, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: KidText.body(16, weight: FontWeight.w700)),
                    Text(body, style: KidText.body(14, color: AppColors.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
        );
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('About Kids Learning Universe', style: KidText.display(26)),
        const SizedBox(height: 12),
        _Card(
          child: Column(
            children: [
              point('🎯', 'Learning through play', 'Reading, phonics, math, thinking skills, social-emotional learning, storybooks and art for ages 2–8 (preschool to 2nd grade). Activities adapt to your child as they learn.'),
              point('🔒', 'Private by design', 'No ads, no tracking, no accounts. All progress is stored only on this device.'),
              point('📴', 'Works offline', 'Every game and book is built into the app — perfect for car trips and waiting rooms.'),
              point('🗣️', 'Built for pre-readers', 'Every instruction is read aloud. Books can be read in English or Spanish.'),
              point('⏱️', 'Healthy screen time', 'Set a daily limit in Settings. Grown-up areas are protected by a parental gate.'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snap) => Text(
            snap.hasData ? 'Version ${snap.data!.version} (build ${snap.data!.buildNumber})' : '',
            style: KidText.body(13, color: AppColors.inkSoft),
          ),
        ),
      ],
    );
  }
}
