import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/app_version.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../shared/constants/lumi_type_scale.dart';
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
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      context.go('/login');
      return;
    }

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
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: LumiSpacing.lg),
                  child: LumiLogoWordmark(fontSize: 56),
                ),
                SizedBox(height: LumiSpacing.xl + LumiSpacing.lg), // 56 ≈ xl(32)+lg(24)
                Text(
                  'Lumi 正在為妳點亮衣櫥...',
                  style: TextStyle(
                    fontSize: LumiTypeScale.body,
                    color: LumiColors.subtext,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: LumiSpacing.md,
            right: LumiSpacing.md,
            child: Text(
              appVersionLabel,
              style: TextStyle(
                fontSize: LumiTypeScale.labelSm,
                color: LumiColors.subtext.withValues(alpha: 0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
