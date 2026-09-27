import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The premium plans offered in the grown-ups area.
enum PremiumPlan { monthly, yearly, lifetime }

/// Store product IDs. Create products with these exact IDs in the Google Play
/// Console (subscriptions for monthly/yearly, a one-time product for lifetime).
class PremiumProductIds {
  PremiumProductIds._();
  static const monthly = 'klu_premium_monthly';
  static const yearly = 'klu_premium_yearly';
  static const lifetime = 'klu_premium_lifetime';

  static String of(PremiumPlan plan) => switch (plan) {
        PremiumPlan.monthly => monthly,
        PremiumPlan.yearly => yearly,
        PremiumPlan.lifetime => lifetime,
      };
}

class PremiumProduct {
  const PremiumProduct({
    required this.plan,
    required this.id,
    required this.title,
    required this.price,
    required this.period,
    this.badge,
  });

  final PremiumPlan plan;
  final String id;
  final String title;

  /// Localised price string from the store, e.g. "₹199".
  final String price;

  /// "/ month", "/ year", "one time".
  final String period;
  final String? badge;
}

enum PurchaseOutcome { success, cancelled, pending, error, unavailable }

/// Connection to a store (Google Play Billing, App Store, or a test double).
///
/// To go live, implement this with the `in_app_purchase` plugin and pass it to
/// [PremiumService] in `main.dart`. Nothing else in the app has to change.
abstract class PurchaseBackend {
  /// True when purchases are simulated and nothing is charged.
  bool get isTestMode;

  Future<List<PremiumProduct>> loadProducts();

  /// Starts the purchase flow for [product].
  Future<PurchaseOutcome> buy(PremiumProduct product);

  /// Returns true if the user already owns premium (restore purchases).
  Future<bool> restore();

  /// Re-checks ownership at startup (e.g. subscription expired/renewed).
  /// Returns null if the store can't be reached so the cached value is kept.
  Future<bool?> verifyEntitlement();
}

/// Simulated store used until Google Play Billing is connected. Purchases
/// succeed instantly and nothing is charged.
class TestPurchaseBackend implements PurchaseBackend {
  TestPurchaseBackend(this._prefs);

  final SharedPreferences _prefs;
  static const _ownedKey = 'test_store_owned';

  @override
  bool get isTestMode => true;

  @override
  Future<List<PremiumProduct>> loadProducts() async => const [
        PremiumProduct(
          plan: PremiumPlan.monthly,
          id: PremiumProductIds.monthly,
          title: 'Monthly',
          price: '₹199',
          period: '/ month',
        ),
        PremiumProduct(
          plan: PremiumPlan.yearly,
          id: PremiumProductIds.yearly,
          title: 'Yearly',
          price: '₹999',
          period: '/ year',
          badge: 'Best value',
        ),
        PremiumProduct(
          plan: PremiumPlan.lifetime,
          id: PremiumProductIds.lifetime,
          title: 'Lifetime',
          price: '₹2,499',
          period: 'one time',
        ),
      ];

  @override
  Future<PurchaseOutcome> buy(PremiumProduct product) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await _prefs.setBool(_ownedKey, true);
    return PurchaseOutcome.success;
  }

  @override
  Future<bool> restore() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return _prefs.getBool(_ownedKey) ?? false;
  }

  @override
  Future<bool?> verifyEntitlement() async => _prefs.getBool(_ownedKey) ?? false;

  /// Test helper: forget the simulated purchase.
  Future<void> reset() => _prefs.remove(_ownedKey);
}

/// Holds the premium entitlement for the whole app.
class PremiumService extends ChangeNotifier {
  PremiumService(this._backend, this._prefs);

  final PurchaseBackend _backend;
  final SharedPreferences _prefs;
  static const _cacheKey = 'premium_active';

  bool _isPremium = false;
  bool _busy = false;
  List<PremiumProduct> _products = const [];

  bool get isPremium => _isPremium;
  bool get busy => _busy;
  bool get isTestMode => _backend.isTestMode;
  List<PremiumProduct> get products => _products;

  Future<void> init() async {
    _isPremium = _prefs.getBool(_cacheKey) ?? false;
    try {
      final verified = await _backend.verifyEntitlement();
      if (verified != null) await _setPremium(verified, notify: false);
      _products = await _backend.loadProducts();
    } catch (e) {
      debugPrint('Premium init failed: $e');
    }
  }

  Future<void> _setPremium(bool value, {bool notify = true}) async {
    _isPremium = value;
    await _prefs.setBool(_cacheKey, value);
    if (notify) notifyListeners();
  }

  Future<PurchaseOutcome> purchase(PremiumProduct product) async {
    if (_busy) return PurchaseOutcome.pending;
    _busy = true;
    notifyListeners();
    try {
      final outcome = await _backend.buy(product);
      if (outcome == PurchaseOutcome.success) await _setPremium(true, notify: false);
      return outcome;
    } catch (e) {
      debugPrint('Purchase failed: $e');
      return PurchaseOutcome.error;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> restore() async {
    _busy = true;
    notifyListeners();
    try {
      final owned = await _backend.restore();
      if (owned) await _setPremium(true, notify: false);
      return owned;
    } catch (e) {
      debugPrint('Restore failed: $e');
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Test mode only: turn premium off again to try the free experience.
  Future<void> resetTestPurchase() async {
    final backend = _backend;
    if (backend is TestPurchaseBackend) await backend.reset();
    await _setPremium(false);
  }
}
