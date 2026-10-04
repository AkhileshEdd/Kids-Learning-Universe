import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'premium_service.dart';

class StoreException implements Exception {
  StoreException(this.message);
  final String message;

  @override
  String toString() => 'StoreException: $message';
}

/// The Google Play Billing calls the backend needs. The real implementation
/// is [PlayBillingApi]; tests use a fake.
abstract class BillingApi {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<List<ProductDetails>> queryProducts(Set<String> ids);

  /// Opens Google Play's purchase sheet. [replacing] is the subscription
  /// being switched from (monthly <-> yearly).
  Future<bool> launchPurchase(ProductDetails product, {PurchaseDetails? replacing});

  /// Acknowledges a purchase. Google refunds purchases that aren't
  /// acknowledged within three days.
  Future<void> acknowledge(PurchaseDetails purchase);

  /// Active subscriptions and owned one-time products.
  Future<List<PurchaseDetails>> queryOwned();
}

class PlayBillingApi implements BillingApi {
  final InAppPurchase _iap = InAppPurchase.instance;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<List<ProductDetails>> queryProducts(Set<String> ids) async {
    final response = await _iap.queryProductDetails(ids);
    if (response.error != null) throw StoreException(response.error!.message);
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('Products missing in Google Play Console: ${response.notFoundIDs}');
    }
    return response.productDetails;
  }

  @override
  Future<bool> launchPurchase(ProductDetails product, {PurchaseDetails? replacing}) {
    final param = GooglePlayPurchaseParam(
      productDetails: product,
      changeSubscriptionParam: replacing is GooglePlayPurchaseDetails
          ? ChangeSubscriptionParam(
              oldPurchaseDetails: replacing,
              replacementMode: ReplacementMode.withTimeProration,
            )
          : null,
    );
    // Subscriptions and the lifetime unlock are both non-consumable.
    return _iap.buyNonConsumable(purchaseParam: param);
  }

  @override
  Future<void> acknowledge(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) await _iap.completePurchase(purchase);
  }

  @override
  Future<List<PurchaseDetails>> queryOwned() async {
    final android = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
    final response = await android.queryPastPurchases();
    if (response.error != null) throw StoreException(response.error!.message);
    return response.pastPurchases;
  }
}

/// Premium through Google Play Billing: two subscriptions (monthly, yearly)
/// and a one-time lifetime unlock. Google Play takes the payment; the app
/// asks Play what the family owns at start-up, on resume and after buying.
class GooglePlayPurchaseBackend extends PurchaseBackend {
  GooglePlayPurchaseBackend([BillingApi? api]) : _api = api ?? PlayBillingApi();

  final BillingApi _api;
  final _changes = StreamController<Entitlement>.broadcast();
  final Map<PremiumPlan, ProductDetails> _details = {};
  StreamSubscription<List<PurchaseDetails>>? _purchases;
  bool _available = false;

  /// The subscription the family pays for now (to switch plans properly).
  PurchaseDetails? _activeSubscription;

  Completer<PurchaseOutcome>? _inFlight;
  String? _inFlightId;

  static const purchaseTimeout = Duration(minutes: 10);

  @override
  bool get isTestMode => false;

  @override
  Stream<Entitlement> get entitlementChanges => _changes.stream;

  @override
  Future<bool> connect() async {
    // Listen as early as possible so purchases finished while the app was
    // closed (or pending payments that went through) are handled.
    _purchases ??= _api.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) => debugPrint('Purchase stream error: $e'),
    );
    try {
      _available = await _api.isAvailable();
    } catch (e) {
      debugPrint('Google Play Billing unavailable: $e');
      _available = false;
    }
    return _available;
  }

  @override
  Future<List<PremiumProduct>> loadProducts() async {
    if (!_available) return const [];
    final found = await _api.queryProducts(PremiumProductIds.all);
    _details.clear();
    final products = <PremiumProduct>[];
    for (final plan in PremiumPlan.values) {
      final candidates = found.where((d) => d.id == PremiumProductIds.of(plan)).toList();
      final chosen = _chooseOffer(plan, candidates);
      if (chosen == null) continue;
      _details[plan] = chosen;
      products.add(_toProduct(plan, chosen));
    }
    return products;
  }

  /// Google Play returns one entry per base plan and per offer the user is
  /// eligible for. Pick the expected base plan, preferring an introductory
  /// offer (free trial or discount) when there is one.
  static ProductDetails? _chooseOffer(PremiumPlan plan, List<ProductDetails> candidates) {
    if (candidates.isEmpty) return null;
    if (plan == PremiumPlan.lifetime) return candidates.first;
    final offers = candidates.whereType<GooglePlayProductDetails>().where((d) => offerOf(d) != null).toList();
    if (offers.isEmpty) return candidates.first;
    final basePlanId = plan == PremiumPlan.monthly ? PremiumProductIds.monthlyBasePlan : PremiumProductIds.yearlyBasePlan;
    final matching = offers.where((d) => offerOf(d)!.basePlanId == basePlanId).toList();
    final pool = matching.isNotEmpty ? matching : offers;
    int firstPhase(GooglePlayProductDetails d) => offerOf(d)!.pricingPhases.first.priceAmountMicros;
    pool.sort((a, b) {
      final byPrice = firstPhase(a).compareTo(firstPhase(b));
      if (byPrice != 0) return byPrice;
      // Same price: the plain base plan (no offer id) first.
      return (offerOf(a)!.offerId == null ? 0 : 1).compareTo(offerOf(b)!.offerId == null ? 0 : 1);
    });
    return pool.first;
  }

  static SubscriptionOfferDetailsWrapper? offerOf(GooglePlayProductDetails d) {
    final i = d.subscriptionIndex;
    final offers = d.productDetails.subscriptionOfferDetails;
    if (i == null || offers == null || i >= offers.length) return null;
    return offers[i];
  }

  static PremiumProduct _toProduct(PremiumPlan plan, ProductDetails d) {
    var price = d.price;
    double? rawPrice = d.rawPrice;
    var currency = d.currencyCode;
    String? offer;
    if (d is GooglePlayProductDetails) {
      final details = offerOf(d);
      if (details != null && details.pricingPhases.isNotEmpty) {
        // The last phase is the regular renewal price.
        final regular = details.pricingPhases.last;
        price = regular.formattedPrice;
        rawPrice = regular.priceAmountMicros / 1e6;
        currency = regular.priceCurrencyCode;
        if (details.pricingPhases.length > 1) offer = introText(details.pricingPhases.first);
      }
    }
    return PremiumProduct(
      plan: plan,
      id: d.id,
      title: switch (plan) {
        PremiumPlan.monthly => 'Monthly',
        PremiumPlan.yearly => 'Yearly',
        PremiumPlan.lifetime => 'Lifetime',
      },
      price: price,
      period: switch (plan) {
        PremiumPlan.monthly => '/ month',
        PremiumPlan.yearly => '/ year',
        PremiumPlan.lifetime => 'one time',
      },
      rawPrice: rawPrice,
      currencyCode: currency,
      offer: offer,
    );
  }

  /// "7-day free trial", "1-month free trial" or "₹49 for the first 3 months".
  static String introText(PricingPhaseWrapper phase) {
    final match = RegExp(r'^P(\d+)([YMWD])$').firstMatch(phase.billingPeriod);
    if (match == null) return phase.priceAmountMicros == 0 ? 'Free trial' : 'Intro offer';
    final count = int.parse(match.group(1)!) * (phase.billingCycleCount > 0 ? phase.billingCycleCount : 1);
    final unit = const {'Y': 'year', 'M': 'month', 'W': 'week', 'D': 'day'}[match.group(2)]!;
    if (phase.priceAmountMicros == 0) return '$count-$unit free trial';
    return '${phase.formattedPrice} for the first ${count == 1 ? unit : '$count ${unit}s'}';
  }

  @override
  Future<PurchaseOutcome> buy(PremiumProduct product) async {
    final details = _details[product.plan];
    if (!_available || details == null) return PurchaseOutcome.unavailable;
    if (_inFlight != null) return PurchaseOutcome.pending;
    final current = _activeSubscription;
    // Switching between monthly and yearly replaces the subscription instead
    // of adding a second one.
    final replacing = product.isSubscription && current != null && current.productID != product.id ? current : null;
    final completer = _inFlight = Completer<PurchaseOutcome>();
    _inFlightId = product.id;
    try {
      final launched = await _api.launchPurchase(details, replacing: replacing);
      if (!launched) _finish(PurchaseOutcome.error);
    } catch (e) {
      debugPrint('Could not start purchase: $e');
      _finish(PurchaseOutcome.error);
    }
    return completer.future.timeout(purchaseTimeout, onTimeout: () {
      _inFlight = null;
      return PurchaseOutcome.pending;
    });
  }

  void _finish(PurchaseOutcome outcome) {
    final c = _inFlight;
    _inFlight = null;
    _inFlightId = null;
    if (c != null && !c.isCompleted) c.complete(outcome);
  }

  /// Cancelled and failed purchases arrive without a product ID.
  bool _isInFlight(PurchaseDetails p) => _inFlight != null && (p.productID.isEmpty || p.productID == _inFlightId);

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      final ours = PremiumProductIds.planOf(p.productID) != null;
      switch (p.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (ours) await _acknowledge(p);
          if (_isInFlight(p)) _finish(PurchaseOutcome.success);
        case PurchaseStatus.pending:
          // Paid later (e.g. cash at a store); unlocked once it completes.
          if (_isInFlight(p)) _finish(PurchaseOutcome.pending);
        case PurchaseStatus.canceled:
          if (_isInFlight(p)) _finish(PurchaseOutcome.cancelled);
        case PurchaseStatus.error:
          if (_isInFlight(p)) {
            final alreadyOwned = p.error?.message.contains('itemAlreadyOwned') ?? false;
            _finish(alreadyOwned ? PurchaseOutcome.success : PurchaseOutcome.error);
          }
      }
    }
    final owned = await fetchEntitlement();
    if (owned != null && !_changes.isClosed) _changes.add(owned);
  }

  Future<void> _acknowledge(PurchaseDetails p) async {
    try {
      await _api.acknowledge(p);
    } catch (e) {
      // Retried on the next start-up or resume via fetchEntitlement.
      debugPrint('Acknowledge failed: $e');
    }
  }

  @override
  Future<Entitlement?> fetchEntitlement() async {
    if (!_available) {
      try {
        _available = await _api.isAvailable();
      } catch (_) {
        _available = false;
      }
      if (!_available) return null;
    }
    try {
      final plans = <PremiumPlan>[];
      PurchaseDetails? subscription;
      for (final p in await _api.queryOwned()) {
        final plan = PremiumProductIds.planOf(p.productID);
        if (plan == null) continue;
        if (p.status != PurchaseStatus.purchased && p.status != PurchaseStatus.restored) continue;
        await _acknowledge(p);
        plans.add(plan);
        if (plan != PremiumPlan.lifetime) subscription = p;
      }
      _activeSubscription = subscription;
      return Entitlement.best(plans);
    } catch (e) {
      debugPrint('Could not check purchases: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _purchases?.cancel();
    _changes.close();
  }
}
