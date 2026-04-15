import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/app_version.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/widgets/lumi_logo_wordmark.dart';
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
          // 歡迎頁使用柔和漸層背景，維持留白與質感層次。
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  LumiColors.base,
                  LumiColors.baseAlt,
                ],
              ),
            ),
          ),
          // 微暖色塊，讓歡迎區更聚焦。
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  LumiColors.primary.withOpacity(0.06),
                  LumiColors.surface.withOpacity(0.0),
                ],
              ),
            ),
          ),
          // 內容層
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 24, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  const LumiLogoWordmark(fontSize: 56),
                  const SizedBox(height: 12),
                  const Text(
                    '用 Google 相片點亮妳的衣櫥',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: LumiColors.subtext,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(flex: 5),
                  Text(
                    appVersionLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      color: LumiColors.subtext,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _GoogleSignInButton(isLoading: isLoading, ref: ref),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
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
          gradient: isLoading ? null : LumiColors.buttonGradient,
          color: isLoading ? LumiColors.primary.withOpacity(0.6) : null,
          borderRadius: BorderRadius.circular(9999),
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
            color: LumiColors.text,
          ),
        ),
      ),
    );
  }
}
