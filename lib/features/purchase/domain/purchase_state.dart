/// Sealed state for the purchase flow shown in [PaywallSheet].
sealed class PurchaseState {
  const PurchaseState();
}

/// Idle — no purchase in progress; products may or may not be loaded.
class PurchaseIdle extends PurchaseState {
  const PurchaseIdle();
}

/// Products are being fetched from the platform store.
class PurchaseLoadingProducts extends PurchaseState {
  const PurchaseLoadingProducts();
}

/// A purchase transaction is in progress (platform UI active or verifying).
class PurchaseProcessing extends PurchaseState {
  const PurchaseProcessing({required this.productId});
  final String productId;
}

/// Purchase completed and Firestore has been updated.
class PurchaseDone extends PurchaseState {
  const PurchaseDone({required this.productId, this.fromRestore = false});
  final String productId;
  final bool fromRestore;
}

/// An error occurred (product load failure, payment cancelled, verification fail).
class PurchaseError extends PurchaseState {
  const PurchaseError(this.message);
  final String message;
}
