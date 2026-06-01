import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_radii.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../shared/constants/lumi_type_scale.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;
  static const _stepCount = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _stepCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() {
    // Mark that onboarding has been seen so future cold-starts skip it.
    SharedPreferences.getInstance().then(
      (p) => p.setBool('onboarding_shown', true),
    );
    // Onboarding is pre-login: always send to the login page.
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: LumiColors.base,
      body: Stack(
        children: [
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _OnboardingStep(
                    gradientBegin: LumiColors.primaryFixed,
                    gradientEnd: LumiColors.glow.withValues(alpha: 0.65),
                    illustration: const _WardrobeIllustration(),
                    title: l10n.onboardingStep1Title,
                    description: l10n.onboardingStep1Desc,
                  ),
                  _OnboardingStep(
                    gradientBegin: LumiColors.glow.withValues(alpha: 0.55),
                    gradientEnd: LumiColors.primaryFixed,
                    illustration: const _AiIllustration(),
                    title: l10n.onboardingStep2Title,
                    description: l10n.onboardingStep2Desc,
                  ),
                  _OnboardingStep(
                    gradientBegin: LumiColors.primaryFixed,
                    gradientEnd: LumiColors.glow.withValues(alpha: 0.60),
                    illustration: const _CheckIllustration(),
                    title: l10n.onboardingStep3Title,
                    description: l10n.onboardingStep3Desc,
                  ),
                ],
              );
            },
          ),

          // Page indicator
          Positioned(
            bottom: botPad + LumiSpacing.xl + LumiSpacing.lg + 56,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_stepCount, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin:
                      const EdgeInsets.symmetric(horizontal: LumiSpacing.xs),
                  width: _currentPage == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? LumiColors.primary
                        : LumiColors.subtext.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(LumiRadii.sm),
                  ),
                );
              }),
            ),
          ),

          // Bottom CTA button
          Positioned(
            bottom: botPad + LumiSpacing.xl + LumiSpacing.md,
            left: LumiSpacing.lg,
            right: LumiSpacing.lg,
            child: GestureDetector(
              onTap: _next,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LumiColors.buttonGradient,
                  borderRadius: BorderRadius.circular(LumiRadii.pill),
                ),
                child: Center(
                  child: Builder(
                    builder: (ctx) => Text(
                      _currentPage < _stepCount - 1
                          ? AppLocalizations.of(ctx).onboardingNext
                          : AppLocalizations.of(ctx).onboardingStart,
                      style: const TextStyle(
                        fontSize: LumiTypeScale.titleSm,
                        fontWeight: FontWeight.w600,
                        color: LumiColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single step ───────────────────────────────────────────────────────────────

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    required this.gradientBegin,
    required this.gradientEnd,
    required this.illustration,
    required this.title,
    required this.description,
  });

  final Color gradientBegin;
  final Color gradientEnd;
  final Widget illustration;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Column(
      children: [
        // Illustration area
        Container(
          height: screenHeight * 0.48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gradientBegin, gradientEnd],
            ),
          ),
          child: Center(child: illustration),
        ),
        // Text area
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: LumiColors.surface,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(LumiRadii.xl),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
              LumiSpacing.lg + LumiSpacing.xs,
              LumiSpacing.xl,
              LumiSpacing.lg + LumiSpacing.xs,
              100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: LumiTypeScale.headlineMd,
                    fontWeight: FontWeight.w700,
                    color: LumiColors.primary,
                  ),
                ),
                const SizedBox(height: LumiSpacing.md),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: LumiTypeScale.body,
                    color: LumiColors.subtext,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Step 1: Wardrobe grid illustration ────────────────────────────────────────

class _WardrobeIllustration extends StatelessWidget {
  const _WardrobeIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft background glow
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LumiColors.primary.withValues(alpha: 0.08),
            ),
          ),
          // 2×2 card grid
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniCard(icon: Icons.checkroom_outlined),
                  SizedBox(width: LumiSpacing.sm),
                  _MiniCard(icon: Icons.style_outlined),
                ],
              ),
              SizedBox(height: LumiSpacing.sm),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniCard(icon: Icons.palette_outlined),
                  SizedBox(width: LumiSpacing.sm),
                  _MiniCard(icon: Icons.watch_outlined),
                ],
              ),
            ],
          ),
          // Item-count badge
          const Positioned(
            top: 8,
            right: 8,
            child: _GradientBadge(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 11,
                    color: LumiColors.onPrimary,
                  ),
                  SizedBox(width: 3),
                  Text(
                    '247',
                    style: TextStyle(
                      fontSize: LumiTypeScale.labelSm,
                      fontWeight: FontWeight.w700,
                      color: LumiColors.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 2: AI-orb illustration ───────────────────────────────────────────────

class _AiIllustration extends StatelessWidget {
  const _AiIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 210,
            height: 210,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LumiColors.primary.withValues(alpha: 0.07),
            ),
          ),
          // Mid ring
          Container(
            width: 152,
            height: 152,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LumiColors.primary.withValues(alpha: 0.10),
            ),
          ),
          // Core orb
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LumiColors.buttonGradient,
            ),
            child: const Icon(
              Icons.auto_awesome,
              size: 46,
              color: LumiColors.onPrimary,
            ),
          ),
          // Floating category chips
          const Positioned(
            top: 24,
            right: 12,
            child: _PillChip(icon: Icons.style_outlined),
          ),
          const Positioned(
            bottom: 28,
            left: 4,
            child: _PillChip(icon: Icons.checkroom_outlined),
          ),
          const Positioned(
            top: 84,
            left: 0,
            child: _PillChip(icon: Icons.category_outlined),
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Comparison illustration ──────────────────────────────────────────

class _CheckIllustration extends StatelessWidget {
  const _CheckIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Left card — wardrobe item (slightly tilted)
          Positioned(
            left: 8,
            child: Transform.rotate(
              angle: -0.10,
              child: const _ClothingCard(icon: Icons.checkroom_outlined),
            ),
          ),
          // Right card — store item (opposite tilt)
          Positioned(
            right: 8,
            child: Transform.rotate(
              angle: 0.10,
              child: const _ClothingCard(icon: Icons.shopping_bag_outlined),
            ),
          ),
          // Compare badge (center)
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LumiColors.buttonGradient,
            ),
            child: const Icon(
              Icons.compare_arrows_rounded,
              size: 24,
              color: LumiColors.onPrimary,
            ),
          ),
          // Similarity percentage badge
          const Positioned(
            top: 6,
            right: 48,
            child: _GradientBadge(
              child: Text(
                '87%',
                style: TextStyle(
                  fontSize: LumiTypeScale.labelSm,
                  fontWeight: FontWeight.w700,
                  color: LumiColors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared illustration helpers ───────────────────────────────────────────────

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: LumiColors.surface,
        borderRadius: BorderRadius.circular(LumiRadii.md),
      ),
      child: Icon(icon, size: 38, color: LumiColors.primary),
    );
  }
}

class _PillChip extends StatelessWidget {
  const _PillChip({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LumiSpacing.sm,
        vertical: LumiSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: LumiColors.surface,
        borderRadius: BorderRadius.circular(LumiRadii.pill),
      ),
      child: Icon(icon, size: 16, color: LumiColors.primary),
    );
  }
}

class _ClothingCard extends StatelessWidget {
  const _ClothingCard({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 124,
      decoration: BoxDecoration(
        color: LumiColors.surface,
        borderRadius: BorderRadius.circular(LumiRadii.lg),
      ),
      child: Icon(icon, size: 44, color: LumiColors.primary),
    );
  }
}

class _GradientBadge extends StatelessWidget {
  const _GradientBadge({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LumiSpacing.sm,
        vertical: LumiSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: LumiColors.buttonGradient,
        borderRadius: BorderRadius.circular(LumiRadii.pill),
      ),
      child: child,
    );
  }
}
