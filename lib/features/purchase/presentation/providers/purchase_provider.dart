import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart' show PlatformException;
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

  // iOS StoreKit re-delivers unfinished transactions when purchaseStream is
  // subscribed. Without this flag those stale deliveries would trigger
  // PurchaseDone and close the paywall sheet before the user taps anything.
  bool _purchaseInitiated = false;

  // Tracks user intent (Buy vs Restore) for UX messaging only.
  // Does NOT affect backend verification — every transaction is verified the
  // same way via the App Store Server API.
  bool _isRestoreAction = false;

  @override
  Future<PurchaseState> build() async {
    _log('PurchaseNotifier build — subscribing to purchaseStream');
    _purchaseInitiated = false;
    _isRestoreAction = false;
    final repo = ref.read(purchaseRepositoryProvider);
    _sub?.cancel();
    _sub = repo.purchaseStream.listen(_onPurchaseUpdate);
    ref.onDispose(() {
      _log('PurchaseNotifier dispose');
      _sub?.cancel();
    });
    _log('PurchaseNotifier build complete → PurchaseIdle');
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
      _purchaseInitiated = true;
      _isRestoreAction = false;
      await ref.read(purchaseRepositoryProvider).buy(product);
      // Actual result arrives via purchaseStream → _onPurchaseUpdate
    } catch (e) {
      _log('buy ✗ $e');
      _purchaseInitiated = false;
      // StoreKit2 throws this when the user dismisses the payment sheet.
      // Treat as silent cancel — no error banner, just return to idle.
      if (e is PlatformException && e.code == 'storekit2_purchase_cancelled') {
        state = const AsyncData(PurchaseIdle());
        return;
      }
      state = AsyncData(PurchaseError(e.toString()));
    }
  }

  /// Restores previous purchases (required by App Store review guidelines).
  Future<void> restore() async {
    _log('restore');
    _purchaseInitiated = true;
    _isRestoreAction = true;
    state = const AsyncData(PurchaseProcessing(productId: 'restore'));
    await ref.read(purchaseRepositoryProvider).restore();
    // iOS fires paymentQueueRestoreCompletedTransactionsFinished after all
    // restored transactions have been delivered (or immediately when there are
    // none). The plugin may emit an empty list, which _onPurchaseUpdate ignores.
    // If no state change occurs within 25 s, fall back to idle so the sheet
    // doesn't stay stuck forever (covers "nothing to restore" and timeout cases).
    await Future.delayed(const Duration(seconds: 25));
    if (state.valueOrNull is PurchaseProcessing) {
      _log('restore: no result after 25 s — resetting to idle');
      _purchaseInitiated = false;
      _isRestoreAction = false;
      state = const AsyncData(PurchaseIdle());
    }
  }

  void reset() {
    _purchaseInitiated = false;
    _isRestoreAction = false;
    state = const AsyncData(PurchaseIdle());
  }

  // ── Purchase stream handler ────────────────────────────────────────────────

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    // iOS emits an empty list when restore completes with no transactions.
    // Treat this as "nothing to restore" and unblock the loading state.
    if (purchases.isEmpty && _isRestoreAction && _purchaseInitiated) {
      _log('restore complete: no previous purchases found (empty stream event)');
      _purchaseInitiated = false;
      _isRestoreAction = false;
      state = const AsyncData(PurchaseIdle());
      return;
    }
    for (final p in purchases) {
      _log('update: id=${p.productID} status=${p.status} initiated=$_purchaseInitiated');
      switch (p.status) {
        case PurchaseStatus.pending:
          state = AsyncData(PurchaseProcessing(productId: p.productID));
        case PurchaseStatus.purchased:
          if (_purchaseInitiated) {
            await _handleSuccess(p);
          } else {
            // iOS re-delivered an unfinished transaction from a prior session.
            // Firestore was already updated by the original purchase; complete
            // the transaction to clear the StoreKit queue silently.
            _log('stale re-delivery: ${p.productID} — completing without re-verify');
            if (p.pendingCompletePurchase) {
              await ref.read(purchaseRepositoryProvider).complete(p);
            }
          }
        case PurchaseStatus.restored:
          if (_purchaseInitiated) {
            // Both buy() and restore() may deliver PurchaseStatus.restored when
            // the user already owns the product. The App Store Server API verifies
            // every transactionId the same way — no special handling needed.
            await _handleSuccess(p);
          } else {
            // Stale restore re-delivery on purchaseStream subscribe. Silently complete.
            _log('stale restore re-delivery: ${p.productID} — completing without re-verify');
            if (p.pendingCompletePurchase) {
              await ref.read(purchaseRepositoryProvider).complete(p);
            }
          }
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
    _log('${_isRestoreAction ? 'restore' : 'purchase'}: $productId — verifying with backend');
    state = AsyncData(PurchaseProcessing(productId: productId));

    try {
      final vData = PurchaseRepository.extractVerificationData(details);
      final service = ref.read(cloudFunctionsServiceProvider);
      await service.verifyPurchase(
        productId: productId,
        transactionId: vData.transactionId,
        purchaseToken: vData.purchaseToken,
      );

      if (details.pendingCompletePurchase) {
        await ref.read(purchaseRepositoryProvider).complete(details);
      }

      _log('${_isRestoreAction ? 'restore' : 'purchase'}: $productId — Firestore updated');
      state = AsyncData(PurchaseDone(productId: productId, fromRestore: _isRestoreAction));
    } catch (e) {
      _log('${_isRestoreAction ? 'restore' : 'verify'} ✗ $e');
      if (details.pendingCompletePurchase) {
        await ref.read(purchaseRepositoryProvider).complete(details);
      }
      if (e is FirebaseFunctionsException && e.code == 'failed-precondition') {
        state = const AsyncData(PurchaseError('訂閱已過期，請重新訂閱以繼續使用 Pro 功能。'));
        return;
      }
      if (_isRestoreAction) {
        state = AsyncData(PurchaseError('恢復購買失敗，請稍後再試或聯絡客服。\n$e'));
      } else {
        state = AsyncData(PurchaseError('購買驗證失敗，請聯絡客服。\n$e'));
      }
    }
  }
}
