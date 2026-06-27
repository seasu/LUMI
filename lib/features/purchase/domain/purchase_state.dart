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

/// Semantic category of a purchase failure. The UI maps each kind to a
/// localized, user-friendly message — raw platform/exception text is never
/// shown to the user (Apple rejects screens that surface debug errors).
enum PurchaseErrorKind {
  /// StoreKit / platform purchase failure, or any otherwise-unclassified error.
  generic,

  /// Backend (App Store Server API) verification of the transaction failed.
  verifyFailed,

  /// Restore purchases failed.
  restoreFailed,

  /// The subscription is valid but has expired.
  subscriptionExpired,
}

/// An error occurred (product load failure, payment cancelled, verification fail).
class PurchaseError extends PurchaseState {
  const PurchaseError(this.kind, {this.debugDetail});

  /// Drives the localized message shown to the user.
  final PurchaseErrorKind kind;

  /// Raw technical detail for logging only — never displayed to the user.
  final String? debugDetail;
}
