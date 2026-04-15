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
                  _LumiLogo(),
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

// ── Logo ──────────────────────────────────────────────────────────────────────

class _LumiLogo extends StatefulWidget {
  @override
  State<_LumiLogo> createState() => _LumiLogoState();
}

class _LumiLogoState extends State<_LumiLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sparkleController;
  late final Animation<double> _sparkleSizeAnimation;
  late final Animation<double> _sparkleGlowAnimation;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _sparkleSizeAnimation = TweenSequence<double>([
      // 快閃：快速放大再收回
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.25).chain(
          CurveTween(curve: Curves.easeInCubic),
        ),
        weight: 15,
      ),
      // 慢呼吸：長時間柔和起伏
      TweenSequenceItem(
        tween: Tween(begin: 0.25, end: 0.75).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.75, end: 0.35).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 35,
      ),
    ]).animate(_sparkleController);
    _sparkleGlowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.35), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 0.72), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.72, end: 0.4), weight: 35),
    ]).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 英文字草寫風格 Logo
        const Text(
          'Lumi',
          style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: LumiColors.text,
            fontStyle: FontStyle.italic,
            letterSpacing: 0.3,
            fontFamily: 'cursive',
          ),
        ),
        // i 上方閃爍橘光
        Positioned(
          top: 6,
          right: 8,
          child: AnimatedBuilder(
            animation: _sparkleController,
            builder: (_, __) {
              final t = _sparkleSizeAnimation.value;
              final g = _sparkleGlowAnimation.value;
              return Container(
                width: 18 + (t * 8),
                height: 18 + (t * 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.7 + g * 0.28),
                      LumiColors.glow.withOpacity(0.55 + g * 0.38),
                      LumiColors.primaryLight.withOpacity(0.4 + g * 0.42),
                      LumiColors.primary.withOpacity(0.15 + g * 0.3),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.22, 0.5, 0.72, 1.0],
                  ),
                ),
              );
            },
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
