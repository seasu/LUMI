import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../shared/constants/app_version.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../shared/constants/lumi_type_scale.dart';
import '../../../shared/widgets/lumi_logo_wordmark.dart';
import 'providers/auth_provider.dart';

// Persisted key: true once the user has swiped through onboarding at least once.
const _kOnboardingShown = 'onboarding_shown';

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
      // Not logged in — show onboarding intro the very first time, login after.
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final shown = prefs.getBool(_kOnboardingShown) ?? false;
      context.go(shown ? '/login' : '/onboarding');
      return;
    }

    // Logged in → go straight to the main app.
    if (mounted) context.go('/home');
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
                SizedBox(height: LumiSpacing.xl + LumiSpacing.lg),
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
