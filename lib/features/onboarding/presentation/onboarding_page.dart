import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../../user/data/user_repository.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
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

  Future<void> _finish() async {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      await ref.read(userRepositoryProvider).markOnboardingComplete(user.uid);
    }
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumiColors.base,
      body: Stack(
        children: [
          PageView(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            children: const [
              _OnboardingStep(
                gradientColors: [LumiColors.baseAlt, LumiColors.base],
                icon: Icons.photo_library_outlined,
                title: '零摩擦數位化衣櫥',
                description: 'LUMI 與 Google 相片自動同步，妳無需手動上傳任何內容。',
              ),
              _OnboardingStep(
                gradientColors: [LumiColors.base, LumiColors.baseAlt],
                icon: Icons.auto_awesome_outlined,
                title: 'AI 智慧分析',
                description: 'Lumi 透過 Gemini AI 自動辨識顏色、材質與款式，讓搜尋變得毫不費力。',
              ),
              _OnboardingStep(
                gradientColors: [LumiColors.baseAlt, LumiColors.base],
                icon: Icons.compare_arrows_rounded,
                title: '聰明消費不重複',
                description: '「似曾相識」讓妳在購物現場即時比對衣櫥，避免買到重複款式。',
              ),
            ],
          ),
          // 頁面指示器
          Positioned(
            bottom: 160,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_stepCount, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? LumiColors.primary
                        : LumiColors.subtext.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
          // 底部按鈕
          Positioned(
            bottom: 48,
            left: 24,
            right: 24,
            child: GestureDetector(
              onTap: _next,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LumiColors.buttonGradient,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Center(
                  child: Text(
                    _currentPage < _stepCount - 1 ? '下一步' : '開始使用',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: LumiColors.onPrimary,
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

// ── 單一步驟 ──────────────────────────────────────────────────────────────────

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    required this.gradientColors,
    required this.icon,
    required this.title,
    required this.description,
  });

  final List<Color> gradientColors;
  final IconData icon;
  final String title;
  final String description;
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Column(
      children: [
        // 上半部：情境漸層圖區
        Container(
          height: screenHeight * 0.48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Center(
            child: Container(
              width: 108,
              height: 108,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    LumiColors.glow.withValues(alpha: 0.35),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Icon(
                icon,
                size: 52,
                color: LumiColors.primary,
              ),
            ),
          ),
        ),
        // 下半部：白色圓角卡片
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: LumiColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: LumiColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
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
