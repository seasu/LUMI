import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
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

  // iOS StoreKit automatically re-delivers any unfinished transactions the
  // moment purchaseStream is subscribed. Without this flag those stale
  // deliveries would trigger PurchaseDone and cause the paywall sheet to
  // auto-pop before the user has tapped anything.
  bool _purchaseInitiated = false;

  // Tracks whether the user explicitly tapped "Restore Purchases" vs "Buy".
  // StoreKit may return PurchaseStatus.restored even for a buy() call (e.g. in
  // sandbox or when a transaction was pending from a prior session); using this
  // flag keeps the two paths distinct so errors are handled correctly.
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
  }

  void reset() {
    _purchaseInitiated = false;
    _isRestoreAction = false;
    state = const AsyncData(PurchaseIdle());
  }

  // ── Purchase stream handler ────────────────────────────────────────────────

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      _log('update: id=${p.productID} status=${p.status} initiated=$_purchaseInitiated');
      switch (p.status) {
        case PurchaseStatus.pending:
          state = AsyncData(PurchaseProcessing(productId: p.productID));
        case PurchaseStatus.purchased:
          if (_purchaseInitiated) {
            await _handleSuccess(p, isRestore: false);
          } else {
            // iOS re-delivered an unfinished transaction from a prior session.
            // Firestore was already updated by the original purchase; just
            // complete the transaction to clear the StoreKit queue silently.
            _log('stale re-delivery: ${p.productID} — completing without re-verify');
            if (p.pendingCompletePurchase) {
              await ref.read(purchaseRepositoryProvider).complete(p);
            }
          }
        case PurchaseStatus.restored:
          if (_purchaseInitiated) {
            // Use _isRestoreAction (not the StoreKit status) to decide the path.
            // buy() sets _isRestoreAction=false; restore() sets it to true.
            // StoreKit can return "restored" for a buy() call (pending sandbox
            // transaction), so we must not blindly treat it as a restore.
            await _handleSuccess(p, isRestore: _isRestoreAction);
          } else {
            // iOS re-delivers restored transactions when subscribing to purchaseStream
            // (same as purchased stale re-delivery). Firestore was already updated by
            // the original purchase; silently complete to clear the StoreKit queue.
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

  Future<void> _handleSuccess(
    PurchaseDetails details, {
    bool isRestore = false,
  }) async {
    final productId = details.productID;
    _log('${isRestore ? 'restore' : 'purchase'}: $productId — verifying with backend');
    state = AsyncData(PurchaseProcessing(productId: productId));

    try {
      final vData = PurchaseRepository.extractVerificationData(details);
      final service = ref.read(cloudFunctionsServiceProvider);
      await service.verifyPurchase(
        productId: productId,
        receiptData: vData.receiptData,
        purchaseToken: vData.purchaseToken,
        isRestore: isRestore,
      );

      if (details.pendingCompletePurchase) {
        await ref.read(purchaseRepositoryProvider).complete(details);
      }

      _log('${isRestore ? 'restore' : 'purchase'}: $productId — Firestore updated');
      state = AsyncData(PurchaseDone(productId: productId));
    } catch (e) {
      _log('${isRestore ? 'restore' : 'verify'} ✗ $e');
      if (details.pendingCompletePurchase) {
        await ref.read(purchaseRepositoryProvider).complete(details);
      }
      // Subscription expired — surface a specific message.
      if (e is FirebaseFunctionsException && e.code == 'failed-precondition') {
        state = const AsyncData(PurchaseError('訂閱已過期，請重新訂閱以繼續使用 Pro 功能。'));
        return;
      }
      if (isRestore) {
        state = AsyncData(PurchaseError('恢復購買失敗，請稍後再試或聯絡客服。\n$e'));
      } else {
        state = AsyncData(PurchaseError('購買驗證失敗，請聯絡客服。\n$e'));
      }
    }
  }
}
