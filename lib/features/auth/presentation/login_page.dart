import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/lumi_colors.dart';
import 'providers/auth_provider.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(signInLoadingProvider);

    return Scaffold(
      backgroundColor: LumiColors.base,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 暖色漸層背景（模擬衣櫥情境）
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF0E6D8),
                  Color(0xFFE8D5C0),
                  Color(0xFFF5EDE0),
                ],
              ),
            ),
          ),
          // 半透明覆層讓文字更易讀
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.08),
                ],
              ),
            ),
          ),
          // 內容層
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  _LumiLogo(),
                  const SizedBox(height: 16),
                  const Text(
                    '用 Google 相片點亮妳的衣櫥',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF3A2010),
                      height: 1.5,
                    ),
                  ),
                  const Spacer(flex: 4),
                  _GoogleSignInButton(isLoading: isLoading, ref: ref),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo ──────────────────────────────────────────────────────────────────────

class _LumiLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 草書風格 Logo 文字
        const Text(
          'Lumi',
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w300,
            color: Color(0xFF3A2010),
            fontStyle: FontStyle.italic,
            letterSpacing: 2,
          ),
        ),
        // 橘橙 sparkle
        Positioned(
          top: 4,
          right: 0,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                colors: [LumiColors.primaryLight, Colors.transparent],
              ),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Google Sign-In Button ─────────────────────────────────────────────────────

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({required this.isLoading, required this.ref});

  final bool isLoading;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading
          ? null
          : () async {
              try {
                await signInWithGoogle(ref);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                      backgroundColor: LumiColors.warning,
                    ),
                  );
                }
              }
            },
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: isLoading
              ? null
              : LumiColors.buttonGradient,
          color: isLoading ? LumiColors.primary.withOpacity(0.6) : null,
          borderRadius: BorderRadius.circular(28),
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
                  color: Colors.white,
                ),
              )
            else ...[
              const _GoogleIcon(),
              const SizedBox(width: 12),
              const Text(
                '使用 Google 帳號登入',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ],
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
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4285F4),
          ),
        ),
      ),
    );
  }
}
