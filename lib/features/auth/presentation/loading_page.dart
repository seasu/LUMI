import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_version.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../shared/widgets/lumi_logo_wordmark.dart';
import '../../user/data/user_repository.dart';
import 'providers/auth_provider.dart';

class LoadingPage extends ConsumerStatefulWidget {
  const LoadingPage({super.key});

  @override
  ConsumerState<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends ConsumerState<LoadingPage> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    // 最短顯示時間（品牌動畫）
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      context.go('/login');
      return;
    }

    // 檢查 Onboarding 是否完成
    final profile = await ref
        .read(userRepositoryProvider)
        .watchProfile(user.uid)
        .first;

    if (!mounted) return;

    if (profile == null || !profile.onboardingCompleted) {
      context.go('/onboarding');
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumiColors.base,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: LumiSpacing.lg),
                  child: LumiLogoWordmark(fontSize: 56),
                ),
                const SizedBox(height: 56),
                // 說明文字
                const Text(
                  'Lumi 正在為妳點亮衣櫥...',
                  style: TextStyle(
                    fontSize: 15,
                    color: LumiColors.subtext,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Text(
              appVersionLabel,
              style: TextStyle(
                fontSize: 11,
                color: LumiColors.subtext.withOpacity(0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
