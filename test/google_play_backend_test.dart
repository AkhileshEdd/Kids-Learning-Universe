import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:kids_learning_universe/premium/google_play_backend.dart';
import 'package:kids_learning_universe/premium/premium_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stands in for Google Play Billing.
class FakeBillingApi implements BillingApi {
  final controller = StreamController<List<PurchaseDetails>>.broadcast();
  bool available = true;
  bool ownedFails = false;
  List<ProductDetails> products = [];
  List<PurchaseDetails> owned = [];
  final acknowledged = <String>[];
  ProductDetails? launched;
  PurchaseDetails? replacing;

  /// What Google Play reports after the purchase sheet closes.
  List<PurchaseDetails> Function(ProductDetails product)? respond;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => controller.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<ProductDetails>> queryProducts(Set<String> ids) async => products.where((p) => ids.contains(p.id)).toList();

  @override
  Future<bool> launchPurchase(ProductDetails product, {PurchaseDetails? replacing}) async {
    launched = product;
    this.replacing = replacing;
    final reply = respond?.call(product);
    if (reply != null) scheduleMicrotask(() => controller.add(reply));
    return true;
  }

  @override
  Future<void> acknowledge(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      acknowledged.add(purchase.productID);
      purchase.pendingCompletePurchase = false;
    }
  }

  @override
  Future<List<PurchaseDetails>> queryOwned() async {
    if (ownedFails) throw StoreException('offline');
    return owned;
  }
}

PricingPhaseWrapper phase(int rupees, String period, {int cycles = 0}) => PricingPhaseWrapper(
      billingCycleCount: cycles,
      billingPeriod: period,
      formattedPrice: rupees == 0 ? 'Free' : '₹$rupees',
      priceAmountMicros: rupees * 1000000,
      priceCurrencyCode: 'INR',
      recurrenceMode: cycles == 0 ? RecurrenceMode.infiniteRecurring : RecurrenceMode.finiteRecurring,
    );

SubscriptionOfferDetailsWrapper offer(String basePlan, List<PricingPhaseWrapper> phases, {String? offerId}) =>
    SubscriptionOfferDetailsWrapper(
      basePlanId: basePlan,
      offerId: offerId,
      offerTags: const [],
      offerIdToken: '$basePlan:${offerId ?? 'base'}',
      pricingPhases: phases,
    );

List<GooglePlayProductDetails> subscription(String id, List<SubscriptionOfferDetailsWrapper> offers) =>
    GooglePlayProductDetails.fromProductDetails(ProductDetailsWrapper(
      description: '',
      name: id,
      productId: id,
      productType: ProductType.subs,
      title: id,
      subscriptionOfferDetails: offers,
    ));

List<GooglePlayProductDetails> oneTime(String id, int rupees) => GooglePlayProductDetails.fromProductDetails(ProductDetailsWrapper(
      description: '',
      name: id,
      productId: id,
      productType: ProductType.inapp,
      title: id,
      oneTimePurchaseOfferDetails: OneTimePurchaseOfferDetailsWrapper(
        formattedPrice: '₹$rupees',
        priceAmountMicros: rupees * 1000000,
        priceCurrencyCode: 'INR',
      ),
    ));

GooglePlayPurchaseDetails purchase(String id, {PurchaseStateWrapper state = PurchaseStateWrapper.purchased, bool acknowledged = false}) =>
    GooglePlayPurchaseDetails.fromPurchase(PurchaseWrapper(
      orderId: 'GPA.$id',
      packageName: kAndroidPackageName,
      purchaseTime: 0,
      purchaseToken: 'token-$id',
      signature: 'signature',
      products: [id],
      isAutoRenewing: id != PremiumProductIds.lifetime,
      originalJson: '{}',
      isAcknowledged: acknowledged,
      purchaseState: state,
    )).single;

/// What Play sends for cancelled or failed purchases (no product ID).
PurchaseDetails noProduct(PurchaseStatus status, {String? errorMessage}) => PurchaseDetails(
      productID: '',
      purchaseID: '',
      transactionDate: null,
      status: status,
      verificationData: PurchaseVerificationData(localVerificationData: '', serverVerificationData: '', source: 'google_play'),
    )..error = errorMessage == null ? null : IAPError(source: 'google_play', code: 'purchase_error', message: errorMessage);

/// Monthly with a 7-day free trial offer, yearly base plan, lifetime.
List<ProductDetails> playCatalog() => [
      ...subscription(PremiumProductIds.monthly, [
        offer('monthly', [phase(199, 'P1M')]),
        offer('monthly', [phase(0, 'P7D', cycles: 1), phase(199, 'P1M')], offerId: 'trial'),
      ]),
      ...subscription(PremiumProductIds.yearly, [offer('yearly', [phase(999, 'P1Y')])]),
      ...oneTime(PremiumProductIds.lifetime, 2499),
    ];

void main() {
  late FakeBillingApi api;
  late GooglePlayPurchaseBackend backend;

  setUp(() async {
    api = FakeBillingApi()..products = playCatalog();
    backend = GooglePlayPurchaseBackend(api);
    await backend.connect();
  });

  tearDown(() => backend.dispose());

  group('plans and prices', () {
    test('shows renewal prices and the free trial from Google Play', () async {
      final products = await backend.loadProducts();
      expect(products.map((p) => p.plan), PremiumPlan.values);
      final monthly = products[0], yearly = products[1], lifetime = products[2];
      expect(monthly.price, '₹199');
      expect(monthly.period, '/ month');
      expect(monthly.offer, '7-day free trial');
      expect(monthly.hasFreeTrial, isTrue);
      expect(yearly.price, '₹999');
      expect(yearly.offer, isNull);
      expect(lifetime.price, '₹2499');
      expect(lifetime.isSubscription, isFalse);
    });

    test('buys the free-trial offer when the family is eligible', () async {
      final products = await backend.loadProducts();
      api.respond = (p) => [purchase(p.id)];
      await backend.buy(products.first);
      expect((api.launched! as GooglePlayProductDetails).offerToken, 'monthly:trial');
    });

    test('prefers the expected base plan over other base plans', () async {
      api.products = [
        ...subscription(PremiumProductIds.monthly, [
          offer('old-promo', [phase(49, 'P1M')]),
          offer('monthly', [phase(199, 'P1M')]),
        ]),
      ];
      final products = await backend.loadProducts();
      expect(products.single.price, '₹199');
    });

    test('describes introductory offers', () {
      expect(GooglePlayPurchaseBackend.introText(phase(0, 'P1M', cycles: 1)), '1-month free trial');
      expect(GooglePlayPurchaseBackend.introText(phase(0, 'P2W', cycles: 1)), '2-week free trial');
      expect(GooglePlayPurchaseBackend.introText(phase(49, 'P1M', cycles: 3)), '₹49 for the first 3 months');
      expect(GooglePlayPurchaseBackend.introText(phase(99, 'P1Y', cycles: 1)), '₹99 for the first year');
    });

    test('the yearly plan shows its saving over monthly', () async {
      SharedPreferences.setMockInitialValues({});
      final service = PremiumService(backend, await SharedPreferences.getInstance());
      await service.init();
      expect(service.storeState, StoreState.ready);
      expect(service.productFor(PremiumPlan.yearly)!.badge, 'Save 58%');
    });

    test('no products when Google Play is unavailable', () async {
      api.available = false;
      await backend.connect();
      expect(await backend.loadProducts(), isEmpty);
      expect(await backend.fetchEntitlement(), isNull);
    });
  });

  group('what the family owns', () {
    test('an active subscription unlocks Premium and gets acknowledged', () async {
      api.owned = [purchase(PremiumProductIds.monthly)];
      final owned = await backend.fetchEntitlement();
      expect(owned!.plan, PremiumPlan.monthly);
      expect(api.acknowledged, [PremiumProductIds.monthly]);
    });

    test('lifetime wins over a subscription', () async {
      api.owned = [purchase(PremiumProductIds.monthly, acknowledged: true), purchase(PremiumProductIds.lifetime, acknowledged: true)];
      expect((await backend.fetchEntitlement())!.plan, PremiumPlan.lifetime);
      expect(api.acknowledged, isEmpty);
    });

    test('a pending payment does not unlock yet', () async {
      api.owned = [purchase(PremiumProductIds.yearly, state: PurchaseStateWrapper.pending)];
      expect((await backend.fetchEntitlement())!.isPremium, isFalse);
    });

    test('nothing owned (e.g. expired or refunded) means free', () async {
      expect((await backend.fetchEntitlement())!.isPremium, isFalse);
    });

    test('unknown when Google Play cannot be reached', () async {
      api.ownedFails = true;
      expect(await backend.fetchEntitlement(), isNull);
    });
  });

  group('buying', () {
    late List<PremiumProduct> products;
    setUp(() async => products = await backend.loadProducts());

    test('a completed purchase succeeds and is acknowledged', () async {
      api.respond = (p) {
        final bought = purchase(p.id);
        api.owned = [bought];
        return [bought];
      };
      expect(await backend.buy(products[1]), PurchaseOutcome.success);
      await pumpEventQueue();
      expect(api.acknowledged, contains(PremiumProductIds.yearly));
      expect((await backend.fetchEntitlement())!.plan, PremiumPlan.yearly);
    });

    test('closing the purchase sheet cancels', () async {
      api.respond = (_) => [noProduct(PurchaseStatus.canceled)];
      expect(await backend.buy(products[0]), PurchaseOutcome.cancelled);
    });

    test('a failed payment reports an error', () async {
      api.respond = (_) => [noProduct(PurchaseStatus.error, errorMessage: 'BillingResponse.error')];
      expect(await backend.buy(products[0]), PurchaseOutcome.error);
    });

    test('buying something already owned counts as success', () async {
      api.respond = (_) => [noProduct(PurchaseStatus.error, errorMessage: 'BillingResponse.itemAlreadyOwned')];
      expect(await backend.buy(products[2]), PurchaseOutcome.success);
    });

    test('a pending payment is reported as pending', () async {
      api.respond = (p) => [purchase(p.id, state: PurchaseStateWrapper.pending)];
      expect(await backend.buy(products[2]), PurchaseOutcome.pending);
    });

    test('switching monthly to yearly replaces the subscription', () async {
      final monthly = purchase(PremiumProductIds.monthly, acknowledged: true);
      api.owned = [monthly];
      await backend.fetchEntitlement();
      api.respond = (p) => [purchase(p.id)];
      await backend.buy(products[1]);
      expect(api.replacing, same(monthly));
    });

    test('lifetime is bought alongside a subscription, not as a replacement', () async {
      api.owned = [purchase(PremiumProductIds.monthly, acknowledged: true)];
      await backend.fetchEntitlement();
      api.respond = (p) => [purchase(p.id)];
      await backend.buy(products[2]);
      expect(api.replacing, isNull);
    });

    test('purchases completed later update the app', () async {
      final changes = <Entitlement>[];
      final sub = backend.entitlementChanges.listen(changes.add);
      final bought = purchase(PremiumProductIds.yearly);
      api.owned = [bought];
      api.controller.add([bought]);
      await pumpEventQueue();
      expect(changes.single.plan, PremiumPlan.yearly);
      expect(api.acknowledged, contains(PremiumProductIds.yearly));
      await sub.cancel();
    });
  });

  group('PremiumService with Google Play', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('purchase unlocks and is remembered across restarts', () async {
      final service = PremiumService(backend, prefs);
      await service.init();
      api.respond = (p) {
        final bought = purchase(p.id);
        api.owned = [bought];
        return [bought];
      };
      expect(await service.purchase(service.productFor(PremiumPlan.yearly)!), PurchaseOutcome.success);
      expect(service.plan, PremiumPlan.yearly);

      // Next launch, offline: the cached plan keeps Premium unlocked.
      final offline = FakeBillingApi()..available = false;
      final restarted = PremiumService(GooglePlayPurchaseBackend(offline), prefs);
      await restarted.init();
      expect(restarted.plan, PremiumPlan.yearly);
      expect(restarted.storeState, StoreState.unavailable);
    });

    test('an expired subscription is removed when Google Play says so', () async {
      await prefs.setString('premium_plan', 'monthly');
      final service = PremiumService(backend, prefs);
      expect(service.isPremium, isTrue);
      await service.init();
      expect(service.isPremium, isFalse);
      expect(prefs.getString('premium_plan'), isNull);
    });

    test('restore finds an earlier lifetime purchase', () async {
      final service = PremiumService(backend, prefs);
      await service.init();
      api.owned = [purchase(PremiumProductIds.lifetime, acknowledged: true)];
      expect(await service.restore(), isTrue);
      expect(service.plan, PremiumPlan.lifetime);
    });

    test('restore reports when Google Play cannot be reached', () async {
      final service = PremiumService(backend, prefs);
      await service.init();
      api.ownedFails = true;
      expect(await service.restore(), isNull);
    });
  });
}
