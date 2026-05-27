import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class BillingService {
  BillingService._();

  static final BillingService instance = BillingService._();

  static const String monthlyProductId = String.fromEnvironment(
    'PLAY_MONTHLY_PRODUCT_ID',
    defaultValue: 'premium_monthly',
  );
  static const String yearlyProductId = String.fromEnvironment(
    'PLAY_YEARLY_PRODUCT_ID',
    defaultValue: 'premium_yearly',
  );

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  Set<String> get productIds => {monthlyProductId, yearlyProductId};

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  Future<void> initialize() async {
    _isAvailable = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS) &&
        await _iap.isAvailable();
  }

  Future<ProductDetailsResponse> loadProducts() {
    return _iap.queryProductDetails(productIds);
  }

  Future<void> buySubscription(ProductDetails productDetails) {
    final purchaseParam = PurchaseParam(productDetails: productDetails);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> restorePurchases() {
    return _iap.restorePurchases();
  }

  Future<void> completeIfNeeded(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  void setPurchaseHandler(void Function(List<PurchaseDetails>) onUpdate) {
    _purchaseSubscription?.cancel();
    _purchaseSubscription = purchaseStream.listen(onUpdate);
  }

  void dispose() {
    _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
  }
}
