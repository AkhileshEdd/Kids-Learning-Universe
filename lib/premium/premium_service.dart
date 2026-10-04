import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The premium plans offered in the grown-ups area.
enum PremiumPlan { monthly, yearly, lifetime }

/// Store product IDs. Create products with these exact IDs in the Google Play
/// Console: two subscriptions (monthly, yearly) and one one-time product
/// (lifetime). See README → "Setting up Google Play Billing".
class PremiumProductIds {
  PremiumProductIds._();
  static const monthly = 'klu_premium_monthly';
  static const yearly = 'klu_premium_yearly';
  static const lifetime = 'klu_premium_lifetime';

  /// Suggested base plan IDs inside the two subscriptions.
  static const monthlyBasePlan = 'monthly';
  static const yearlyBasePlan = 'yearly';

  static const all = {monthly, yearly, lifetime};

  static String of(PremiumPlan plan) => switch (plan) {
        PremiumPlan.monthly => monthly,
        PremiumPlan.yearly => yearly,
        PremiumPlan.lifetime => lifetime,
      };

  static PremiumPlan? planOf(String productId) => switch (productId) {
        monthly => PremiumPlan.monthly,
        yearly => PremiumPlan.yearly,
        lifetime => PremiumPlan.lifetime,
        _ => null,
      };
}

/// Android application ID, used for the "manage subscription" link.
const kAndroidPackageName = 'com.akhileshedd.kidslearninguniverse';

class PremiumProduct {
  const PremiumProduct({
    required this.plan,
    required this.id,
    required this.title,
    required this.price,
    required this.period,
    this.rawPrice,
    this.currencyCode,
    this.offer,
    this.badge,
  });

  final PremiumPlan plan;
  final String id;
  final String title;

  /// Localized price from Google Play, e.g. "₹199.00". For subscriptions this
  /// is the regular renewal price, even when a free trial is offered.
  final String price;

  /// "/ month", "/ year" or "one time".
  final String period;
  final double? rawPrice;
  final String? currencyCode;

  /// Introductory offer from Google Play, e.g. "7-day free trial".
  final String? offer;
  final String? badge;

  bool get isSubscription => plan != PremiumPlan.lifetime;
  bool get hasFreeTrial => offer?.contains('free') ?? false;

  PremiumProduct copyWith({String? badge}) => PremiumProduct(
        plan: plan,
        id: id,
        title: title,
        price: price,
        period: period,
        rawPrice: rawPrice,
        currencyCode: currencyCode,
        offer: offer,
        badge: badge ?? this.badge,
      );
}

/// What the family owns. [plan] is null when they don't have Premium.
class Entitlement {
  const Entitlement(this.plan);
  static const none = Entitlement(null);

  final PremiumPlan? plan;
  bool get isPremium => plan != null;

  /// The best of several owned plans (lifetime beats yearly beats monthly).
  static Entitlement best(Iterable<PremiumPlan> plans) {
    PremiumPlan? best;
    for (final p in plans) {
      if (best == null || p.index > best.index) best = p;
    }
    return Entitlement(best);
  }
}

enum PurchaseOutcome { success, cancelled, pending, error, unavailable }

/// Connection to a store: Google Play Billing in the app, or a simulated
/// store for previews, tests and `--dart-define=TEST_STORE=true` builds.
abstract class PurchaseBackend {
  /// True when purchases are simulated and nothing is charged.
  bool get isTestMode;

  /// Entitlement changes the store reports on its own, e.g. a pending
  /// purchase that went through, or a purchase made outside the paywall.
  Stream<Entitlement> get entitlementChanges;

  /// Connects to the store. Returns false if it is unavailable.
  Future<bool> connect();

  /// The plans with prices from the store (empty if unavailable).
  Future<List<PremiumProduct>> loadProducts();

  /// Starts the purchase flow for [product]. Completes when the store has
  /// confirmed, cancelled or failed the purchase.
  Future<PurchaseOutcome> buy(PremiumProduct product);

  /// Asks the store what the family owns. Returns null if the store can't be
  /// reached, so the cached entitlement is kept (e.g. when offline).
  Future<Entitlement?> fetchEntitlement();

  /// Where grown-ups can cancel or change a subscription.
  Uri manageSubscriptionsUri(PremiumPlan? plan) {
    final sku = plan == null || plan == PremiumPlan.lifetime ? '' : 'sku=${PremiumProductIds.of(plan)}&';
    return Uri.parse('https://play.google.com/store/account/subscriptions?${sku}package=$kAndroidPackageName');
  }

  void dispose() {}
}

/// Simulated store: purchases succeed instantly and nothing is charged.
class TestPurchaseBackend extends PurchaseBackend {
  TestPurchaseBackend(this._prefs);

  final SharedPreferences _prefs;
  final _changes = StreamController<Entitlement>.broadcast();
  static const _ownedKey = 'test_store_plan';

  @override
  bool get isTestMode => true;

  @override
  Stream<Entitlement> get entitlementChanges => _changes.stream;

  @override
  Future<bool> connect() async => true;

  @override
  Future<List<PremiumProduct>> loadProducts() async => const [
        PremiumProduct(
          plan: PremiumPlan.monthly,
          id: PremiumProductIds.monthly,
          title: 'Monthly',
          price: '₹199',
          rawPrice: 199,
          currencyCode: 'INR',
          period: '/ month',
        ),
        PremiumProduct(
          plan: PremiumPlan.yearly,
          id: PremiumProductIds.yearly,
          title: 'Yearly',
          price: '₹999',
          rawPrice: 999,
          currencyCode: 'INR',
          period: '/ year',
        ),
        PremiumProduct(
          plan: PremiumPlan.lifetime,
          id: PremiumProductIds.lifetime,
          title: 'Lifetime',
          price: '₹2,499',
          rawPrice: 2499,
          currencyCode: 'INR',
          period: 'one time',
        ),
      ];

  PremiumPlan? get _owned {
    final name = _prefs.getString(_ownedKey);
    return PremiumPlan.values.where((p) => p.name == name).firstOrNull;
  }

  @override
  Future<PurchaseOutcome> buy(PremiumProduct product) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    // Switching subscriptions replaces the old one; lifetime is forever.
    if (_owned != PremiumPlan.lifetime) await _prefs.setString(_ownedKey, product.plan.name);
    _changes.add(Entitlement(_owned));
    return PurchaseOutcome.success;
  }

  @override
  Future<Entitlement?> fetchEntitlement() async => Entitlement(_owned);

  /// Test helper: forget the simulated purchase.
  Future<void> reset() async {
    await _prefs.remove(_ownedKey);
    _changes.add(Entitlement.none);
  }

  @override
  void dispose() => _changes.close();
}

enum StoreState { connecting, ready, unavailable }

/// Holds the Premium entitlement for the whole app.
class PremiumService extends ChangeNotifier {
  /// Reads the cached entitlement right away so the app starts unlocked
  /// offline; call [init] to connect to the store.
  PremiumService(this._backend, this._prefs) {
    final cached = _prefs.getString(_planKey);
    _plan = PremiumPlan.values.where((p) => p.name == cached).firstOrNull;
    // Builds before plan tracking cached only a flag.
    if (_plan == null && (_prefs.getBool(_legacyKey) ?? false)) _plan = PremiumPlan.yearly;
  }

  final PurchaseBackend _backend;
  final SharedPreferences _prefs;
  static const _planKey = 'premium_plan';
  static const _legacyKey = 'premium_active';

  PremiumPlan? _plan;
  bool _busy = false;
  StoreState _state = StoreState.connecting;
  List<PremiumProduct> _products = const [];
  StreamSubscription<Entitlement>? _sub;
  DateTime? _lastRefresh;

  bool get isPremium => _plan != null;
  PremiumPlan? get plan => _plan;
  bool get busy => _busy;
  bool get isTestMode => _backend.isTestMode;
  StoreState get storeState => _state;
  List<PremiumProduct> get products => _products;
  bool get hasSubscription => _plan == PremiumPlan.monthly || _plan == PremiumPlan.yearly;

  PremiumProduct? productFor(PremiumPlan plan) => _products.where((p) => p.plan == plan).firstOrNull;

  Uri get manageSubscriptionsUri => _backend.manageSubscriptionsUri(_plan);

  /// Connects to the store, checks what the family owns and loads prices.
  Future<void> init() async {
    _sub ??= _backend.entitlementChanges.listen((e) => _apply(e));
    await _connect();
  }

  Future<void> _connect() async {
    _state = StoreState.connecting;
    notifyListeners();
    var connected = false;
    try {
      connected = await _backend.connect();
      if (connected) {
        final owned = await _backend.fetchEntitlement();
        if (owned != null) await _apply(owned, notify: false);
        _products = _withBadges(await _backend.loadProducts());
      }
    } catch (e) {
      debugPrint('Store connection failed: $e');
    }
    _lastRefresh = DateTime.now();
    _state = connected && _products.isNotEmpty ? StoreState.ready : StoreState.unavailable;
    notifyListeners();
  }

  /// Retries loading plans (paywall "Try again").
  Future<void> retry() => _connect();

  /// Re-checks the entitlement, e.g. when the app comes back to the
  /// foreground (a subscription may have been cancelled or renewed).
  Future<void> refresh({Duration minInterval = const Duration(minutes: 10)}) async {
    final last = _lastRefresh;
    if (_busy || (last != null && DateTime.now().difference(last) < minInterval)) return;
    _lastRefresh = DateTime.now();
    try {
      final owned = await _backend.fetchEntitlement();
      if (owned != null) await _apply(owned);
    } catch (e) {
      debugPrint('Entitlement refresh failed: $e');
    }
  }

  Future<void> _apply(Entitlement e, {bool notify = true}) async {
    if (e.plan != _plan) {
      _plan = e.plan;
      if (_plan == null) {
        await _prefs.remove(_planKey);
      } else {
        await _prefs.setString(_planKey, _plan!.name);
      }
      await _prefs.remove(_legacyKey);
    }
    if (notify) notifyListeners();
  }

  /// Labels the yearly plan with how much it saves over paying monthly.
  static List<PremiumProduct> _withBadges(List<PremiumProduct> products) {
    final monthly = products.where((p) => p.plan == PremiumPlan.monthly).firstOrNull;
    return [
      for (final p in products)
        if (p.plan == PremiumPlan.yearly)
          p.copyWith(badge: _savingsBadge(monthly, p))
        else
          p,
    ];
  }

  static String _savingsBadge(PremiumProduct? monthly, PremiumProduct yearly) {
    final m = monthly?.rawPrice, y = yearly.rawPrice;
    if (m != null && y != null && m > 0 && monthly!.currencyCode == yearly.currencyCode) {
      final saving = ((1 - y / (m * 12)) * 100).round();
      if (saving >= 5) return 'Save $saving%';
    }
    return 'Best value';
  }

  Future<PurchaseOutcome> purchase(PremiumProduct product) async {
    if (_busy) return PurchaseOutcome.pending;
    if (_plan == PremiumPlan.lifetime) return PurchaseOutcome.success;
    _busy = true;
    notifyListeners();
    try {
      final outcome = await _backend.buy(product);
      if (outcome == PurchaseOutcome.success) {
        final owned = await _backend.fetchEntitlement();
        // If the store is slow to report the new purchase, trust the
        // confirmed purchase until the next check.
        final best = Entitlement.best([product.plan, ?owned?.plan]);
        await _apply(best, notify: false);
      }
      return outcome;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return PurchaseOutcome.error;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Asks the store again for past purchases. Returns null if the store
  /// couldn't be reached, otherwise whether Premium is active.
  Future<bool?> restore() async {
    _busy = true;
    notifyListeners();
    try {
      if (_state != StoreState.ready) await _backend.connect();
      final owned = await _backend.fetchEntitlement();
      if (owned == null) return null;
      await _apply(owned, notify: false);
      return owned.isPremium;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Test mode only: turn Premium off again to try the free experience.
  Future<void> resetTestPurchase() async {
    final backend = _backend;
    if (backend is TestPurchaseBackend) await backend.reset();
    await _apply(Entitlement.none);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _backend.dispose();
    super.dispose();
  }
}
