import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/debug/debug_log.dart';
import '../../../snap/data/cloud_functions_service.dart'
    show cloudFunctionsServiceProvider;
import '../../data/purchase_repository.dart';
import '../../domain/purchase_state.dart';

void _log(String msg) => DebugLogService.instance.log('[iap] $msg');

// ── Providers ─────────────────────────────────────────────────────────────────

final purchaseRepositoryProvider = Provider<PurchaseRepository>(
  (_) => PurchaseRepository(),
);

/// Cached list of available [ProductDetails] fetched from the store.
final productsProvider = FutureProvider<List<ProductDetails>>((ref) async {
  final repo = ref.read(purchaseRepositoryProvider);
  final available = await repo.isAvailable();
  if (!available) return [];
  return repo.loadProducts();
});

final purchaseProvider =
    AsyncNotifierProvider<PurchaseNotifier, PurchaseState>(
  PurchaseNotifier.new,
);

// ── Notifier ──────────────────────────────────────────────────────────────────

class PurchaseNotifier extends AsyncNotifier<PurchaseState> {
  StreamSubscription<List<PurchaseDetails>>? _sub;

  @override
  Future<PurchaseState> build() async {
    final repo = ref.read(purchaseRepositoryProvider);
    _sub?.cancel();
    _sub = repo.purchaseStream.listen(_onPurchaseUpdate);
    ref.onDispose(() => _sub?.cancel());
    return const PurchaseIdle();
  }

  // ── Public actions ─────────────────────────────────────────────────────────

  /// Initiates the platform purchase UI for [productId].
  Future<void> buy(String productId) async {
    state = const AsyncData(PurchaseProcessing(productId: ''));
    try {
      final products = await ref.read(productsProvider.future);
      final product = products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception('Product not found: $productId'),
      );
      _log('buy → ${product.id} (${product.price})');
      state = AsyncData(PurchaseProcessing(productId: productId));
      await ref.read(purchaseRepositoryProvider).buy(product);
      // Actual result arrives via purchaseStream → _onPurchaseUpdate
    } catch (e) {
      _log('buy ✗ $e');
      state = AsyncData(PurchaseError(e.toString()));
    }
  }

  /// Restores previous purchases (required by App Store review guidelines).
  Future<void> restore() async {
    _log('restore');
    state = const AsyncData(PurchaseProcessing(productId: 'restore'));
    await ref.read(purchaseRepositoryProvider).restore();
  }

  void reset() => state = const AsyncData(PurchaseIdle());

  // ── Purchase stream handler ────────────────────────────────────────────────

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      _log('update: id=${p.productID} status=${p.status}');
      switch (p.status) {
        case PurchaseStatus.pending:
          state = AsyncData(PurchaseProcessing(productId: p.productID));
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _handleSuccess(p);
        case PurchaseStatus.error:
          final msg = p.error?.message ?? 'Purchase failed';
          _log('error: $msg');
          state = AsyncData(PurchaseError(msg));
          if (p.pendingCompletePurchase) {
            await ref.read(purchaseRepositoryProvider).complete(p);
          }
        case PurchaseStatus.canceled:
          _log('cancelled: ${p.productID}');
          state = const AsyncData(PurchaseIdle());
          if (p.pendingCompletePurchase) {
            await ref.read(purchaseRepositoryProvider).complete(p);
          }
      }
    }
  }

  Future<void> _handleSuccess(PurchaseDetails details) async {
    final productId = details.productID;
    _log('success: $productId — verifying with backend');
    state = AsyncData(PurchaseProcessing(productId: productId));

    try {
      final vData =
          PurchaseRepository.extractVerificationData(details);
      final service = ref.read(cloudFunctionsServiceProvider);
      await service.verifyPurchase(
        productId: productId,
        receiptData: vData.receiptData,
        purchaseToken: vData.purchaseToken,
      );

      // Acknowledge delivery to the platform.
      if (details.pendingCompletePurchase) {
        await ref.read(purchaseRepositoryProvider).complete(details);
      }

      _log('success: $productId — Firestore updated');
      state = AsyncData(PurchaseDone(productId: productId));
    } catch (e) {
      _log('verify ✗ $e');
      state = AsyncData(PurchaseError('購買驗證失敗，請聯絡客服。\n$e'));
      if (details.pendingCompletePurchase) {
        await ref.read(purchaseRepositoryProvider).complete(details);
      }
    }
  }
}
