import 'dart:async';
import 'dart:io' show Platform;

import 'package:in_app_purchase/in_app_purchase.dart';

/// Product IDs must match exactly what is configured in App Store Connect
/// and Google Play Console.
abstract final class LumiProductIds {
  /// One-time consumable: adds 100 AI analysis credits.
  static const extra100 = 'lumi_extra_100';

  /// Auto-renewable annual subscription: unlimited AI analysis.
  static const proYearly = 'lumi_pro_yearly';

  static const all = {extra100, proYearly};
}

/// Low-level wrapper around [InAppPurchase].
///
/// Responsibilities:
///   - Initialise the plugin and verify store availability.
///   - Load product details from App Store / Play Store.
///   - Initiate buy flows.
///   - Expose the raw purchase update stream for higher layers to interpret.
class PurchaseRepository {
  PurchaseRepository() : _iap = InAppPurchase.instance;

  final InAppPurchase _iap;

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  /// Returns true if the underlying platform store is reachable.
  Future<bool> isAvailable() => _iap.isAvailable();

  /// Fetches [ProductDetails] for all Lumi SKUs from the platform.
  ///
  /// Returns an empty list if the store is unavailable or none of the IDs
  /// match (e.g. not yet created in App Store Connect / Play Console).
  Future<List<ProductDetails>> loadProducts() async {
    final response = await _iap.queryProductDetails(LumiProductIds.all);
    if (response.error != null) {
      throw Exception('Product load error: ${response.error!.message}');
    }
    return response.productDetails;
  }

  /// Initiates the native purchase UI for [productId].
  ///
  /// The result arrives asynchronously via [purchaseStream]; this method
  /// returns immediately after enqueueing the request.
  Future<void> buy(ProductDetails product) async {
    final PurchaseParam param = PurchaseParam(productDetails: product);

    if (product.id == LumiProductIds.extra100) {
      // Consumable — must use buyConsumable so Android allows repurchase.
      await _iap.buyConsumable(purchaseParam: param);
    } else {
      await _iap.buyNonConsumable(purchaseParam: param);
    }
  }

  /// Restores previous purchases (required by App Store guidelines).
  Future<void> restore() => _iap.restorePurchases();

  /// Signals to the platform that the purchase has been delivered.
  /// Must be called after every successful purchase to avoid re-delivery.
  Future<void> complete(PurchaseDetails details) =>
      _iap.completePurchase(details);

  /// Extracts the platform-appropriate verification data from [details]:
  /// - iOS     → StoreKit transactionIdentifier (`purchaseID`)
  /// - Android → purchase token (`serverVerificationData`)
  static ({String? transactionId, String? purchaseToken}) extractVerificationData(
    PurchaseDetails details,
  ) {
    if (Platform.isIOS) {
      return (
        transactionId: details.purchaseID,
        purchaseToken: null,
      );
    } else {
      return (
        transactionId: null,
        purchaseToken: details.verificationData.serverVerificationData,
      );
    }
  }
}
