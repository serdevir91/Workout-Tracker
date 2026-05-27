import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../monetization/app_flavor.dart';
import '../monetization/monetization_models.dart';
import '../services/ad_service.dart';
import '../services/billing_service.dart';

class MonetizationProvider extends ChangeNotifier {
  static const int freeRoutineLimit = 3;
  static const String _premiumEntitlementKey = 'premium_entitlement';
  static const bool _softOpenAllFeatures = true;

  final BillingService _billingService = BillingService.instance;

  EntitlementState _entitlementState = EntitlementState.free;
  bool _initialized = false;
  bool _isBusy = false;
  bool _productsLoaded = false;
  String? _lastError;
  List<ProductDetails> _products = [];
  List<String> _missingProductIds = [];
  AppFlavor _flavor = AppFlavor.free;

  EntitlementState get entitlementState => _entitlementState;
  bool get initialized => _initialized;
  bool get isBusy => _isBusy;
  bool get productsLoaded => _productsLoaded;
  String? get lastError => _lastError;
  List<ProductDetails> get products => List.unmodifiable(_products);
  List<String> get missingProductIds => List.unmodifiable(_missingProductIds);
  List<String> get configuredProductIds => _billingService.productIds.toList()..sort();
  AppFlavor get flavor => _flavor;
    bool get isSoftOpenMode => _softOpenAllFeatures;

  bool get isProBuild => _entitlementState == EntitlementState.proBuild;
    bool get isPremiumUnlocked => isSoftOpenMode || _entitlementState != EntitlementState.free;
    bool get adsEnabled => !isSoftOpenMode && _entitlementState == EntitlementState.free;
  bool get canCreateUnlimitedRoutines => isPremiumUnlocked;
  bool get hasAdvancedStats => isPremiumUnlocked;
  bool get hasOneRm => isPremiumUnlocked;
  bool get canShowBilling =>
      !isSoftOpenMode &&
      !kIsWeb &&
      _flavor == AppFlavor.free &&
      !isProBuild &&
      _billingService.isAvailable;

  Future<void> initialize() async {
    if (_initialized) return;
    _flavor = await AppFlavorResolver.resolve();

    if (isSoftOpenMode) {
      _productsLoaded = true;
      _initialized = true;
      notifyListeners();
      return;
    }

    if (_flavor == AppFlavor.pro) {
      _entitlementState = EntitlementState.proBuild;
      _productsLoaded = true;
      _initialized = true;
      notifyListeners();
      return;
    }

    _billingService.setPurchaseHandler(_handlePurchaseUpdates);
    await _billingService.initialize();
    await _restoreCachedEntitlement();

    if (_billingService.isAvailable) {
      await _loadProducts();
      unawaited(
        _billingService.restorePurchases().catchError((Object error, StackTrace stackTrace) {
          debugPrint('Restore purchases on init failed: $error');
        }),
      );
    } else {
      _productsLoaded = true;
    }

    if (adsEnabled) {
      await AdService.instance.initialize();
      await AdService.instance.preloadWorkoutFinishInterstitial();
    }

    _initialized = true;
    notifyListeners();
  }

  bool hasAccess(FeatureGate gate) {
    switch (gate) {
      case FeatureGate.ads:
        return !adsEnabled;
      case FeatureGate.unlimitedRoutines:
        return canCreateUnlimitedRoutines;
      case FeatureGate.advancedStats:
        return hasAdvancedStats;
      case FeatureGate.oneRm:
        return hasOneRm;
    }
  }

  Future<void> _restoreCachedEntitlement() async {
    final prefs = await SharedPreferences.getInstance();
    final hasPremium = prefs.getBool(_premiumEntitlementKey) ?? false;
    if (hasPremium) {
      _entitlementState = EntitlementState.premiumSubscriber;
    }
  }

  Future<void> _persistPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumEntitlementKey, value);
  }

  Future<void> _loadProducts() async {
    _productsLoaded = false;
    _missingProductIds = [];
    _lastError = null;
    notifyListeners();

    try {
      final response = await _billingService.loadProducts();
      _products = response.productDetails.toList()
        ..sort((a, b) => a.rawPrice.compareTo(b.rawPrice));
      _missingProductIds = response.notFoundIDs.toList()..sort();

      if (response.error != null) {
        _lastError = response.error!.message;
      } else if (_missingProductIds.isNotEmpty) {
        _lastError =
            'Google Play did not return these product IDs: ${_missingProductIds.join(', ')}';
      } else if (_products.isEmpty) {
        _lastError =
            'Google Play did not return any active subscription plans yet.';
      }
    } catch (e) {
      _products = [];
      _lastError = e.toString();
    } finally {
      _productsLoaded = true;
      notifyListeners();
    }
  }

  Future<void> refreshProducts() async {
    if (!_billingService.isAvailable || isProBuild) return;
    await _loadProducts();
  }

  Future<void> buy(ProductDetails productDetails) async {
    if (_isBusy || isProBuild || !_billingService.isAvailable) return;
    _isBusy = true;
    _lastError = null;
    notifyListeners();

    try {
      await _billingService.buySubscription(productDetails);
    } catch (e) {
      _lastError = e.toString();
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (!_billingService.isAvailable || isProBuild) return;

    _isBusy = true;
    _lastError = null;
    notifyListeners();
    try {
      await _billingService.restorePurchases();
    } catch (e) {
      _lastError = e.toString();
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> _handlePurchasedOrRestored(PurchaseDetails purchase) async {
    if (!_billingService.productIds.contains(purchase.productID)) return;
    _entitlementState = EntitlementState.premiumSubscriber;
    _isBusy = false;
    _lastError = null;
    await _persistPremium(true);
    await _billingService.completeIfNeeded(purchase);
    notifyListeners();
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    if (purchases.isEmpty) return;

    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _isBusy = true;
          notifyListeners();
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handlePurchasedOrRestored(purchase);
          break;
        case PurchaseStatus.error:
          _isBusy = false;
          _lastError = purchase.error?.message ?? 'Purchase failed';
          await _billingService.completeIfNeeded(purchase);
          notifyListeners();
          break;
        case PurchaseStatus.canceled:
          _isBusy = false;
          _lastError = 'Purchase canceled';
          notifyListeners();
          break;
      }
    }
  }

  @override
  void dispose() {
    _billingService.dispose();
    super.dispose();
  }
}
