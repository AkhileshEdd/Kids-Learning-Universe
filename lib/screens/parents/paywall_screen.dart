import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../content/activities.dart';
import '../../content/books.dart';
import '../../content/characters.dart';
import '../../content/stickers.dart';
import '../../core/theme.dart';
import '../../premium/premium_service.dart';
import '../../state/app_state.dart';
import '../../widgets/bubbly_button.dart';
import '../../widgets/common.dart';
import '../../widgets/critter.dart';
import '../../widgets/space_background.dart';

/// Opens Google Play's subscription center (cancel or change plans).
Future<void> openManageSubscriptions(BuildContext context, PremiumService premium) async {
  final ok = await launchUrl(premium.manageSubscriptionsUri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Open the Play Store app → Profile → Payments & subscriptions → Subscriptions.')),
    );
  }
}

/// Premium upgrade screen (only reachable through the parental gate).
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.reason});
  final String? reason;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  PremiumPlan? _selected;

  PremiumPlan _defaultPlan(PremiumService premium) => switch (premium.plan) {
        PremiumPlan.yearly => PremiumPlan.lifetime,
        _ => PremiumPlan.yearly,
      };

  Future<void> _buy(PremiumService premium, PremiumProduct product) async {
    final wasSubscribed = premium.hasSubscription;
    final outcome = await premium.purchase(product);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (outcome) {
      case PurchaseOutcome.success:
        if (wasSubscribed && product.plan == PremiumPlan.lifetime) {
          await _remindToCancel(premium);
          if (!mounted) return;
        } else {
          messenger.showSnackBar(const SnackBar(content: Text('Premium unlocked! Enjoy everything in the universe. 🚀')));
        }
        Navigator.of(context).pop();
      case PurchaseOutcome.pending:
        messenger.showSnackBar(
          const SnackBar(content: Text('Your payment is pending. Premium unlocks as soon as Google Play confirms it.')),
        );
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.error:
        messenger.showSnackBar(const SnackBar(content: Text('The purchase didn’t go through. Nothing was charged. Please try again.')));
      case PurchaseOutcome.unavailable:
        messenger.showSnackBar(const SnackBar(content: Text('Google Play isn’t available right now. Please try again later.')));
    }
  }

  Future<void> _remindToCancel(PremiumService premium) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('You own Premium for life! 👑'),
        content: const Text(
          'Your old subscription is still active in Google Play. Cancel it there so you aren’t charged again.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Later')),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              openManageSubscriptions(this.context, premium);
            },
            child: const Text('Open Google Play'),
          ),
        ],
      ),
    );
  }

  Future<void> _restore(PremiumService premium) async {
    final result = await premium.restore();
    if (!mounted) return;
    final text = switch (result) {
      true => 'Premium restored! 🎉',
      false => 'No Premium purchase found for this Google account.',
      null => 'Couldn’t reach Google Play. Check your connection and try again.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<PremiumService>();
    final premiumActivities = activities.where((a) => a.premium).length;
    final premiumBooks = books.where((b) => b.premium).length;
    final premiumPacks = stickerPacks.where((p) => p.premium).length;
    final benefits = <(String, String)>[
      ('🎮', 'Every learning game, including $premiumActivities Premium-only games'),
      ('📚', 'All ${books.length} storybooks, including $premiumBooks Premium-only books'),
      ('🌟', '$premiumPacks extra sticker packs'),
      ('👨‍👩‍👧', 'Up to ${PremiumLimits.premiumProfiles} child profiles'),
      ('🖍️', 'All coloring pages'),
      ('🚫', 'Always ad-free, works offline'),
    ];
    return Scaffold(
      body: SpaceBackground(
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          RoundButton(icon: Icons.close_rounded, size: 44, onTap: () => Navigator.of(context).pop(), semanticLabel: 'Close'),
                          const SizedBox(width: 12),
                          const Critter(id: CharacterId.cosmo, size: 76, mood: CritterMood.happy, showBody: false),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Premium', style: KidText.display(34, color: AppColors.star)),
                                Text('Unlock the whole universe', style: KidText.body(17, color: Colors.white70)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (widget.reason != null) ...[
                        const SizedBox(height: 8),
                        Text(widget.reason!, style: KidText.body(15, color: Colors.white)),
                      ],
                      const SizedBox(height: 10),
                      for (final (emoji, text) in benefits)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              EmojiText(emoji, size: 22),
                              const SizedBox(width: 10),
                              Expanded(child: Text(text, style: KidText.body(16, color: Colors.white))),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 16, 24, 16),
                  child: _storePanel(premium),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _storePanel(PremiumService premium) {
    if (premium.plan == PremiumPlan.lifetime) {
      return _Owned(
        emoji: '👑',
        title: 'You own Premium for life!',
        body: 'Everything in the universe is unlocked on every device signed in to this Google account.',
      );
    }
    if (premium.storeState == StoreState.connecting && premium.products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 80),
        child: Column(
          children: [
            const CircularProgressIndicator(color: AppColors.star),
            const SizedBox(height: 14),
            Text('Connecting to Google Play…', style: KidText.body(16, color: Colors.white70)),
          ],
        ),
      );
    }
    if (premium.products.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 40),
          const EmojiText('🛰️', size: 52),
          const SizedBox(height: 10),
          Text('Google Play isn’t available', style: KidText.display(22, color: Colors.white)),
          const SizedBox(height: 6),
          Text(
            'Check your internet connection and make sure you’re signed in to the Play Store, then try again.',
            textAlign: TextAlign.center,
            style: KidText.body(15, color: Colors.white70),
          ),
          const SizedBox(height: 14),
          BubblyButton.label(label: 'Try again', icon: Icons.refresh_rounded, color: AppColors.math, fontSize: 18, onTap: premium.retry),
          TextButton(
            onPressed: premium.busy ? null : () => _restore(premium),
            child: Text('Restore purchases', style: KidText.body(15, color: Colors.white70)),
          ),
        ],
      );
    }

    final current = premium.plan;
    final selectedPlan = _selected != null && _selected != current ? _selected! : _defaultPlan(premium);
    final selected = premium.productFor(selectedPlan) ?? premium.products.first;
    final ctaLabel = premium.busy
        ? 'Please wait…'
        : switch (selected.plan) {
            PremiumPlan.lifetime => current == null ? 'Buy lifetime' : 'Upgrade to lifetime',
            _ when current != null => 'Switch to ${selected.title.toLowerCase()}',
            _ when selected.hasFreeTrial => 'Start ${selected.offer}',
            _ => 'Subscribe',
          };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (premium.isTestMode)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0x33FFC93C),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.star),
            ),
            child: Text('Test mode: purchases are simulated and nothing is charged.', style: KidText.body(13, color: Colors.white)),
          ),
        if (current != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              'Premium is active (${premium.productFor(current)?.title ?? current.name} plan). You can switch plans below.',
              style: KidText.body(15, color: Colors.white),
            ),
          ),
        for (final p in premium.products)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _PlanCard(
              product: p,
              selected: p.plan == selected.plan,
              current: p.plan == current,
              onTap: p.plan == current ? null : () => setState(() => _selected = p.plan),
            ),
          ),
        const SizedBox(height: 4),
        BubblyButton.label(
          label: ctaLabel,
          emoji: '🚀',
          color: AppColors.success,
          onTap: premium.busy ? null : () => _buy(premium, selected),
        ),
        const SizedBox(height: 6),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            TextButton(
              onPressed: premium.busy ? null : () => _restore(premium),
              child: Text('Restore purchases', style: KidText.body(15, color: Colors.white70)),
            ),
            if (premium.hasSubscription)
              TextButton(
                onPressed: () => openManageSubscriptions(context, premium),
                child: Text('Manage subscription', style: KidText.body(15, color: Colors.white70)),
              ),
          ],
        ),
        Text(
          _finePrint(selected),
          textAlign: TextAlign.center,
          style: KidText.body(12, color: Colors.white54),
        ),
      ],
    );
  }

  String _finePrint(PremiumProduct selected) {
    if (!selected.isSubscription) {
      return 'One payment to your Google Play account. Premium stays unlocked forever on this Google account.';
    }
    final trial = selected.hasFreeTrial
        ? 'After the ${selected.offer}, you pay ${selected.price} ${selected.period} unless you cancel before it ends. '
        : '';
    return '${trial}Payment is charged to your Google Play account. Subscriptions renew automatically unless '
        'cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in Google Play.';
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.product, required this.selected, required this.current, required this.onTap});
  final PremiumProduct product;
  final bool selected;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final light = selected && !current;
    final fg = light ? AppColors.ink : Colors.white;
    return Semantics(
      button: true,
      selected: selected,
      label: '${product.title} ${product.price} ${product.period}',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: light ? Colors.white : Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: light ? AppColors.star : Colors.white24, width: 3),
          ),
          child: Row(
            children: [
              Icon(
                current
                    ? Icons.check_circle_rounded
                    : (selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded),
                color: current ? AppColors.success : (selected ? AppColors.starDeep : Colors.white70),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(product.title, style: KidText.display(20, color: fg)),
                        if (current)
                          const Pill(text: 'Current plan', color: AppColors.success, fontSize: 12)
                        else if (product.badge != null)
                          Pill(text: product.badge!, color: AppColors.art, fontSize: 12),
                      ],
                    ),
                    if (product.offer != null && !current)
                      Text(product.offer!, style: KidText.body(13, color: light ? AppColors.successDeep : AppColors.success, weight: FontWeight.w700)),
                  ],
                ),
              ),
              Text(product.price, style: KidText.display(20, color: fg)),
              const SizedBox(width: 4),
              Text(product.period, style: KidText.body(13, color: light ? AppColors.inkSoft : Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Owned extends StatelessWidget {
  const _Owned({required this.emoji, required this.title, required this.body});
  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        EmojiText(emoji, size: 64),
        const SizedBox(height: 10),
        Text(title, textAlign: TextAlign.center, style: KidText.display(26, color: Colors.white)),
        const SizedBox(height: 6),
        Text(body, textAlign: TextAlign.center, style: KidText.body(16, color: Colors.white70)),
      ],
    );
  }
}
