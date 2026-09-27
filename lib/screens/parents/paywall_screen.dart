import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

/// Premium upgrade screen (only reachable through the parental gate).
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key, this.reason});
  final String? reason;

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  PremiumPlan _plan = PremiumPlan.yearly;

  Future<void> _buy(PremiumService premium) async {
    final products = premium.products;
    if (products.isEmpty) return;
    final product = products.firstWhere((p) => p.plan == _plan, orElse: () => products.first);
    final outcome = await premium.purchase(product);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    switch (outcome) {
      case PurchaseOutcome.success:
        messenger.showSnackBar(const SnackBar(content: Text('Premium unlocked! Enjoy everything in the universe. 🚀')));
        Navigator.of(context).pop();
      case PurchaseOutcome.pending:
        messenger.showSnackBar(const SnackBar(content: Text('Your purchase is pending. It will unlock once confirmed.')));
      case PurchaseOutcome.cancelled:
        break;
      case PurchaseOutcome.error:
      case PurchaseOutcome.unavailable:
        messenger.showSnackBar(const SnackBar(content: Text('The store is not available right now. Please try again later.')));
    }
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
          child: Stack(
            children: [
              Row(
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
                      child: premium.isPremium
                          ? _AlreadyPremium()
                          : Column(
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
                                    child: Text(
                                      'Test mode: purchases are simulated and nothing is charged.',
                                      style: KidText.body(13, color: Colors.white),
                                    ),
                                  ),
                                for (final p in premium.products)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _PlanCard(
                                      product: p,
                                      selected: p.plan == _plan,
                                      onTap: () => setState(() => _plan = p.plan),
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                BubblyButton.label(
                                  label: premium.busy ? 'Please wait…' : 'Start Premium',
                                  emoji: '🚀',
                                  color: AppColors.success,
                                  onTap: premium.busy ? null : () => _buy(premium),
                                ),
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: premium.busy
                                      ? null
                                      : () async {
                                          final ok = await premium.restore();
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(ok ? 'Purchases restored!' : 'No previous purchase found.')),
                                          );
                                        },
                                  child: Text('Restore purchases', style: KidText.body(15, color: Colors.white70)),
                                ),
                                Text(
                                  'Subscriptions renew automatically until cancelled in Google Play. '
                                  'You can cancel any time.',
                                  textAlign: TextAlign.center,
                                  style: KidText.body(12, color: Colors.white54),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.product, required this.selected, required this.onTap});
  final PremiumProduct product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.star : Colors.white24, width: 3),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppColors.starDeep : Colors.white70,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Text(product.title, style: KidText.display(20, color: selected ? AppColors.ink : Colors.white)),
                  if (product.badge != null) ...[
                    const SizedBox(width: 8),
                    Pill(text: product.badge!, color: AppColors.art, fontSize: 12),
                  ],
                ],
              ),
            ),
            Text(product.price, style: KidText.display(20, color: selected ? AppColors.ink : Colors.white)),
            const SizedBox(width: 4),
            Text(product.period, style: KidText.body(13, color: selected ? AppColors.inkSoft : Colors.white70)),
          ],
        ),
      ),
    );
  }
}

class _AlreadyPremium extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 30),
        const EmojiText('👑', size: 64),
        const SizedBox(height: 10),
        Text('You have Premium!', style: KidText.display(26, color: Colors.white)),
        const SizedBox(height: 6),
        Text('Everything in the universe is unlocked.', style: KidText.body(16, color: Colors.white70)),
      ],
    );
  }
}
