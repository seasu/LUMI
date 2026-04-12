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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < 2) {
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
                gradientColors: [Color(0xFFE8D5C0), Color(0xFFD4B896)],
                icon: Icons.photo_library_outlined,
                title: '零摩擦數位化衣櫥',
                description: 'LUMI 與 Google 相片自動同步，妳無需手動上傳任何內容。',
                isLast: false,
              ),
              _OnboardingStep(
                gradientColors: [Color(0xFFF0D8C0), Color(0xFFE0C090)],
                icon: Icons.auto_awesome_outlined,
                title: 'AI 智慧分析',
                description: 'Lumi 透過 Gemini AI 自動辨識顏色、材質與款式，讓搜尋變得毫不費力。',
                isLast: false,
              ),
              _OnboardingStep(
                gradientColors: [Color(0xFFF5E0C8), Color(0xFFEAC8A0)],
                icon: Icons.compare_arrows_rounded,
                title: '聰明消費不重複',
                description: '「似曾相識」讓妳在購物現場即時比對衣櫥，避免買到重複款式。',
                isLast: true,
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
              children: List.generate(3, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? LumiColors.primary
                        : LumiColors.subtext.withOpacity(0.3),
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
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Text(
                    _currentPage < 2 ? '下一步' : '開始使用',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
    required this.isLast,
  });

  final List<Color> gradientColors;
  final IconData icon;
  final String title;
  final String description;
  final bool isLast;

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
            child: Icon(
              icon,
              size: 80,
              color: Colors.white.withOpacity(0.9),
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
                    fontSize: 28,
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
