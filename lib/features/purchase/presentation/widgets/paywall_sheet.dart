import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/debug/debug_log.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/constants/lumi_colors.dart';
import '../../../../shared/constants/lumi_radii.dart';
import '../../../../shared/constants/lumi_spacing.dart';
import '../../../../shared/constants/lumi_type_scale.dart';
import '../../../user/data/user_repository.dart' show userProfileProvider;
import '../../data/purchase_repository.dart';
import '../../domain/purchase_state.dart';
import '../providers/purchase_provider.dart';

void _log(String msg) => DebugLogService.instance.log('[paywall] $msg');

// ── Public helper ─────────────────────────────────────────────────────────────

/// Navigates to the `/paywall` GoRouter route.
///
/// The paywall is a declarative GoRouter route (opaque: false) rather than an
/// imperative showModalBottomSheet call. This prevents the black-screen bug
/// where GoRouter's refreshListenable rebuild reconciles its pages list and
/// silently removes an imperatively-pushed modal route.
void showPaywallSheet(BuildContext context) {
  _log('showPaywallSheet called — pushing /paywall via GoRouter');
  context.push('/paywall');
}

// ── Sheet widget ──────────────────────────────────────────────────────────────

class PaywallSheet extends ConsumerStatefulWidget {
  const PaywallSheet({super.key});

  @override
  ConsumerState<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends ConsumerState<PaywallSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  bool _buildLogged = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _log('PaywallSheet initState');
    // Reset any stale PurchaseDone / PurchaseProcessing state that might have
    // been left over from a previous session. Without this the ref.listen
    // handler could fire on the very first build and auto-pop the sheet.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _log('initState post-frame: resetting purchase state');
        ref.read(purchaseProvider.notifier).reset();
      }
    });
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _log('PaywallSheet dispose');
    _glowCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final purchaseAsync = ref.watch(purchaseProvider);
    final productsAsync = ref.watch(productsProvider);

    if (!_buildLogged) {
      _buildLogged = true;
      _log(
        'PaywallSheet first build — '
        'purchaseState: ${purchaseAsync.runtimeType} '
        'value: ${purchaseAsync.valueOrNull?.runtimeType}',
      );
    }

    // React to successful purchase → close sheet and refresh quota.
    ref.listen(purchaseProvider, (prev, next) {
      _log(
        'ref.listen fired — '
        'prev: ${prev?.valueOrNull?.runtimeType} '
        'next: ${next.valueOrNull?.runtimeType} '
        'dismissed: $_dismissed',
      );
      next.whenData((state) {
        if (state is PurchaseDone && context.mounted && !_dismissed) {
          _dismissed = true;
          _log('PurchaseDone detected — invalidating profile and popping sheet');
          ref.invalidate(userProfileProvider);
          // Show snackbar BEFORE popping so context is still valid.
          _showSuccessSnackBar(context, state.productId, isRestore: state.fromRestore);
          _log('calling context.pop() via GoRouter');
          context.pop();
        }
      });
    });

    final purchaseState = purchaseAsync.valueOrNull;
    final isProcessing = purchaseState is PurchaseProcessing;
    final isRestoring = purchaseState is PurchaseProcessing &&
        purchaseState.productId == 'restore';

    return PopScope(
      canPop: !isProcessing,
      child: Container(
        decoration: const BoxDecoration(
          color: LumiColors.base,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(LumiRadii.xl),
          ),
        ),
        padding: EdgeInsets.only(
          left: LumiSpacing.lg,
          right: LumiSpacing.lg,
          top: LumiSpacing.md,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              LumiSpacing.lg,
        ),
        child: Stack(
          children: [
            // Main paywall content (always present so sheet height stays stable)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                _Handle(),
                const SizedBox(height: LumiSpacing.lg),

                // Hanger illustration
                _HangerIcon(),
                const SizedBox(height: LumiSpacing.md),

                // Title
                Builder(builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Column(
                    children: [
                      Text(
                        l10n.paywallTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: LumiTypeScale.titleLg,
                          fontWeight: FontWeight.w800,
                          color: LumiColors.text,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: LumiSpacing.xs),
                      Text(
                        l10n.paywallSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: LumiTypeScale.labelMd,
                          color: LumiColors.subtext,
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: LumiSpacing.lg),

                // Plan cards
                productsAsync.when(
                  loading: () => const _PlanCardsLoading(),
                  error: (e, _) => _PlanCardsFallback(
                    isProcessing: isProcessing,
                    glowAnim: _glowAnim,
                    onBuyExtra: () => _buy(LumiProductIds.extra100),
                    onBuyPro: () => _buy(LumiProductIds.proYearly),
                  ),
                  data: (products) {
                    final extra = products
                        .where((p) => p.id == LumiProductIds.extra100)
                        .firstOrNull;
                    final pro = products
                        .where((p) => p.id == LumiProductIds.proYearly)
                        .firstOrNull;
                    return _PlanCards(
                      extraPrice: extra?.price ?? 'NT\$99',
                      proPrice: pro?.price ?? 'NT\$199',
                      isProcessing: isProcessing,
                      glowAnim: _glowAnim,
                      onBuyExtra: () => _buy(LumiProductIds.extra100),
                      onBuyPro: () => _buy(LumiProductIds.proYearly),
                    );
                  },
                ),

                // Error banner
                if (purchaseState is PurchaseError)
                  _ErrorBanner(
                    message: purchaseState.message,
                    onDismiss: () => ref.read(purchaseProvider.notifier).reset(),
                  ),

                const SizedBox(height: LumiSpacing.md),

                // Restore Purchases (App Store compliance)
                if (!isProcessing)
                  TextButton(
                    onPressed: () {
                      _log('restore tapped');
                      ref.read(purchaseProvider.notifier).restore();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: LumiColors.subtext,
                    ),
                    child: Text(
                      AppLocalizations.of(context).paywallRestorePurchases,
                    ),
                  ),

                // Dismiss
                if (!isProcessing)
                  TextButton(
                    onPressed: () => context.pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: LumiColors.subtext,
                    ),
                    child: Text(AppLocalizations.of(context).paywallFreeContinue),
                  ),
              ],
            ),

            // Restore overlay — shown on top without changing sheet size
            if (isRestoring)
              Positioned.fill(
                child: _RestoreOverlay(glowAnim: _glowAnim),
              ),
          ],
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  void _buy(String productId) {
    _log('_buy tapped: $productId');
    ref.read(purchaseProvider.notifier).buy(productId);
  }

  void _showSuccessSnackBar(BuildContext ctx, String productId, {bool isRestore = false}) {
    final l10n = AppLocalizations.of(ctx);
    final String msg;
    if (isRestore) {
      msg = l10n.paywallRestoreSuccess;
    } else if (productId == LumiProductIds.proYearly) {
      msg = l10n.paywallSuccessPro;
    } else {
      msg = l10n.paywallSuccessExtra;
    }
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: LumiColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LumiRadii.md),
        ),
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: LumiColors.subtext.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(LumiRadii.pill),
        ),
      ),
    );
  }
}

class _HangerIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: LumiColors.primaryFixed,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.dry_cleaning_outlined,
        size: 32,
        color: LumiColors.primary,
      ),
    );
  }
}

// ── Plan cards ─────────────────────────────────────────────────────────────

class _PlanCards extends StatelessWidget {
  const _PlanCards({
    required this.extraPrice,
    required this.proPrice,
    required this.isProcessing,
    required this.glowAnim,
    required this.onBuyExtra,
    required this.onBuyPro,
  });

  final String extraPrice;
  final String proPrice;
  final bool isProcessing;
  final Animation<double> glowAnim;
  final VoidCallback onBuyExtra;
  final VoidCallback onBuyPro;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Pro annual (shown first — decoy effect; "best value")
        Builder(builder: (context) {
          final l10n = AppLocalizations.of(context);
          return _PlanCard(
            highlighted: true,
            badge: l10n.paywallProBadge,
            title: l10n.paywallProName,
            description: l10n.paywallProDesc,
            priceLabel: proPrice,
            priceSub: l10n.paywallProPriceSub,
            isProcessing: isProcessing,
            glowAnim: glowAnim,
            onBuy: onBuyPro,
          );
        }),
        const SizedBox(height: LumiSpacing.md),
        // Extra pack
        Builder(builder: (context) {
          final l10n = AppLocalizations.of(context);
          return _PlanCard(
            highlighted: false,
            badge: null,
            title: l10n.paywallExtraName,
            description: l10n.paywallExtraDesc,
            priceLabel: extraPrice,
            priceSub: l10n.paywallExtraPriceSub,
            isProcessing: isProcessing,
            glowAnim: glowAnim,
            onBuy: onBuyExtra,
          );
        }),
      ],
    );
  }
}

class _PlanCardsFallback extends StatelessWidget {
  const _PlanCardsFallback({
    required this.isProcessing,
    required this.glowAnim,
    required this.onBuyExtra,
    required this.onBuyPro,
  });

  final bool isProcessing;
  final Animation<double> glowAnim;
  final VoidCallback onBuyExtra;
  final VoidCallback onBuyPro;

  @override
  Widget build(BuildContext context) {
    return _PlanCards(
      extraPrice: 'NT\$99',
      proPrice: 'NT\$199',
      isProcessing: isProcessing,
      glowAnim: glowAnim,
      onBuyExtra: onBuyExtra,
      onBuyPro: onBuyPro,
    );
  }
}

class _PlanCardsLoading extends StatelessWidget {
  const _PlanCardsLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _shimmerCard(tall: true),
        const SizedBox(height: LumiSpacing.md),
        _shimmerCard(tall: false),
      ],
    );
  }

  Widget _shimmerCard({required bool tall}) {
    return Container(
      height: tall ? 132 : 108,
      decoration: BoxDecoration(
        color: LumiColors.baseAlt,
        borderRadius: BorderRadius.circular(LumiRadii.lg),
      ),
    );
  }
}

// ── Individual plan card ───────────────────────────────────────────────────

class _PlanCard extends StatefulWidget {
  const _PlanCard({
    required this.highlighted,
    required this.badge,
    required this.title,
    required this.description,
    required this.priceLabel,
    required this.priceSub,
    required this.isProcessing,
    required this.glowAnim,
    required this.onBuy,
  });

  final bool highlighted;
  final String? badge;
  final String title;
  final String description;
  final String priceLabel;
  final String priceSub;
  final bool isProcessing;
  final Animation<double> glowAnim;
  final VoidCallback onBuy;

  @override
  State<_PlanCard> createState() => _PlanCardState();
}

class _PlanCardState extends State<_PlanCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.isProcessing ? null : widget.onBuy,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          decoration: BoxDecoration(
            color: LumiColors.surface,
            borderRadius: BorderRadius.circular(LumiRadii.lg),
            border: widget.highlighted
                ? Border.all(
                    color: LumiColors.primary.withValues(alpha: 0.4),
                    width: 1.5,
                  )
                : Border.all(
                    color: LumiColors.subtext.withValues(alpha: 0.15),
                  ),
          ),
          padding: const EdgeInsets.all(LumiSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Info column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row + badge
                    Row(
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: LumiTypeScale.titleSm,
                            fontWeight: FontWeight.w700,
                            color: LumiColors.text,
                          ),
                        ),
                        if (widget.badge != null) ...[
                          const SizedBox(width: LumiSpacing.sm),
                          _Badge(label: widget.badge!),
                        ],
                      ],
                    ),
                    const SizedBox(height: LumiSpacing.xs),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: LumiTypeScale.labelMd,
                        color: LumiColors.subtext,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: LumiSpacing.md),

              // Price + button column
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: widget.priceLabel,
                          style: const TextStyle(
                            fontSize: LumiTypeScale.titleSm,
                            fontWeight: FontWeight.w800,
                            color: LumiColors.primary,
                          ),
                        ),
                        TextSpan(
                          text: widget.priceSub,
                          style: const TextStyle(
                            fontSize: LumiTypeScale.labelSm,
                            color: LumiColors.subtext,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: LumiSpacing.sm),
                  _BuyButton(
                    highlighted: widget.highlighted,
                    isProcessing: widget.isProcessing,
                    glowAnim: widget.glowAnim,
                    onTap: null, // outer _PlanCard GestureDetector handles all taps
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Buy button with Glow Orb loading state ────────────────────────────────

class _BuyButton extends StatelessWidget {
  const _BuyButton({
    required this.highlighted,
    required this.isProcessing,
    required this.glowAnim,
    required this.onTap,
  });

  final bool highlighted;
  final bool isProcessing;
  final Animation<double> glowAnim;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (isProcessing) {
      return _GlowOrb(anim: glowAnim);
    }

    if (highlighted) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: LumiSpacing.md,
            vertical: LumiSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: LumiColors.buttonGradient,
            borderRadius: BorderRadius.circular(LumiRadii.pill),
          ),
          child: Text(
            AppLocalizations.of(context).paywallBuyPro,
            style: const TextStyle(
              fontSize: LumiTypeScale.labelMd,
              fontWeight: FontWeight.w600,
              color: LumiColors.onPrimary,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LumiSpacing.md,
          vertical: LumiSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: LumiColors.primaryFixed,
          borderRadius: BorderRadius.circular(LumiRadii.pill),
        ),
        child: Text(
          AppLocalizations.of(context).paywallBuyExtra,
          style: const TextStyle(
            fontSize: LumiTypeScale.labelMd,
            fontWeight: FontWeight.w600,
            color: LumiColors.primary,
          ),
        ),
      ),
    );
  }
}

// ── Glow Orb (replaces spinner during purchase) ───────────────────────────

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.anim});

  final Animation<double> anim;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: LumiColors.glow.withValues(alpha: anim.value),
            boxShadow: [
              BoxShadow(
                color: LumiColors.primaryLight
                    .withValues(alpha: anim.value * 0.5),
                blurRadius: 16 * anim.value,
                spreadRadius: 2 * anim.value,
              ),
            ],
          ),
          child: Center(
            child: Transform.rotate(
              angle: anim.value * 2 * math.pi,
              child: const Icon(
                Icons.auto_awesome,
                size: 18,
                color: LumiColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Badge ("最划算") ────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LumiSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        gradient: LumiColors.buttonGradient,
        borderRadius: BorderRadius.circular(LumiRadii.pill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: LumiTypeScale.labelSm,
          fontWeight: FontWeight.w600,
          color: LumiColors.onPrimary,
        ),
      ),
    );
  }
}

// ── Error banner ───────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: LumiSpacing.md),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: LumiSpacing.md,
          vertical: LumiSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: LumiColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(LumiRadii.md),
          border: Border.all(
            color: LumiColors.warning.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline,
              size: 18,
              color: LumiColors.warning,
            ),
            const SizedBox(width: LumiSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: LumiTypeScale.labelMd,
                  color: LumiColors.warning,
                ),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(
                Icons.close,
                size: 16,
                color: LumiColors.warning,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Restore-in-progress overlay ───────────────────────────────────────────────
//
// Replaces the full sheet content while restorePurchases() is running so the
// user gets unambiguous feedback that something is happening.

class _RestoreOverlay extends StatelessWidget {
  const _RestoreOverlay({required this.glowAnim});

  final Animation<double> glowAnim;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Solid background so the purchase-options content underneath is hidden.
    return Container(
      decoration: const BoxDecoration(
        color: LumiColors.base,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(LumiRadii.xl),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _GlowOrb(anim: glowAnim),
          const SizedBox(height: LumiSpacing.lg),
          Text(
            l10n.paywallRestoringPurchases,
            style: const TextStyle(
              fontSize: LumiTypeScale.titleSm,
              fontWeight: FontWeight.w600,
              color: LumiColors.text,
            ),
          ),
        ],
      ),
    );
  }
}
