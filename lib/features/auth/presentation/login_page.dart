import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_version.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_radii.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../shared/constants/lumi_type_scale.dart';
import '../../../shared/widgets/lumi_logo_wordmark.dart';
import 'providers/auth_provider.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(signInLoadingProvider);

    return Scaffold(
      backgroundColor: LumiColors.base,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [LumiColors.base, LumiColors.baseAlt],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  LumiColors.primary.withValues(alpha: 0.06),
                  LumiColors.surface.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  const LumiLogoWordmark(fontSize: 56),
                  const SizedBox(height: LumiSpacing.sm),
                  const Text(
                    '用 AI 點亮妳的衣櫥',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: LumiTypeScale.body,
                      fontWeight: FontWeight.w400,
                      color: LumiColors.subtext,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(flex: 5),
                  const Text(
                    appVersionLabel,
                    style: TextStyle(
                      fontSize: LumiTypeScale.labelSm,
                      color: LumiColors.subtext,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: LumiSpacing.sm),
                  _SignInButton(
                    label: '使用 Apple 帳號登入',
                    icon: const _AppleIcon(),
                    isLoading: loading == SignInMethod.apple,
                    isDisabled: loading != SignInMethod.none,
                    onTap: () => _handleSignIn(context, ref, SignInMethod.apple),
                  ),
                  const SizedBox(height: LumiSpacing.sm),
                  _SignInButton(
                    label: '使用 Google 帳號登入',
                    icon: const _GoogleIcon(),
                    isLoading: loading == SignInMethod.google,
                    isDisabled: loading != SignInMethod.none,
                    onTap: () => _handleSignIn(context, ref, SignInMethod.google),
                  ),
                  const SizedBox(height: LumiSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignIn(
    BuildContext context,
    WidgetRef ref,
    SignInMethod method,
  ) async {
    try {
      if (method == SignInMethod.apple) {
        await signInWithApple(ref);
      } else {
        await signInWithGoogle(ref);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: LumiColors.warning,
          ),
        );
      }
    }
  }
}

// ── Shared button ─────────────────────────────────────────────────────────────

class _SignInButton extends StatelessWidget {
  const _SignInButton({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.isDisabled,
    required this.onTap,
  });

  final String label;
  final Widget icon;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isDisabled && !isLoading ? 0.5 : 1.0,
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: isLoading ? null : LumiColors.buttonGradient,
            color: isLoading ? LumiColors.primary.withValues(alpha: 0.6) : null,
            borderRadius: BorderRadius.circular(LumiRadii.pill),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: LumiColors.onPrimary,
                  ),
                )
              else ...[
                icon,
                const SizedBox(width: LumiSpacing.sm),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: LumiTypeScale.body,
                    fontWeight: FontWeight.w600,
                    color: LumiColors.onPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Icons ─────────────────────────────────────────────────────────────────────

class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: LumiColors.surface,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          '',
          style: TextStyle(
            fontSize: 14,
            color: LumiColors.text,
            height: 1.1,
          ),
        ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: LumiColors.surface,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: LumiTypeScale.labelMd,
            fontWeight: FontWeight.w700,
            color: LumiColors.text,
          ),
        ),
      ),
    );
  }
}
