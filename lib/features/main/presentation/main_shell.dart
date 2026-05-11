import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_radii.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../shared/constants/lumi_type_scale.dart';
import '../../search/presentation/providers/search_provider.dart';

const _tabs = [
  _TabItem(path: '/home', icon: Icons.checkroom_outlined, label: '我的衣櫥'),
  _TabItem(path: '/home/outfits', icon: Icons.style_outlined, label: '我的穿搭'),
  _TabItem(path: '/home/profile', icon: Icons.person_outline, label: '個人檔案'),
];

class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/home/outfits')) return 1;
    if (loc.startsWith('/home/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      backgroundColor: LumiColors.base,
      body: child,
      bottomNavigationBar: _LumiBottomNav(
        currentIndex: currentIndex,
        onTap: (i) {
          if (i == 0) {
            ref.read(wardrobeFilterProvider.notifier).setCategory(null);
          }
          context.go(_tabs[i].path);
        },
      ),
    );
  }
}

// ── Floating Glassmorphic Nav ─────────────────────────────────────────────────

class _LumiBottomNav extends StatelessWidget {
  const _LumiBottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.viewPaddingOf(context).bottom;

    return SizedBox(
      height: 64 + LumiSpacing.md + safeBottom,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          LumiSpacing.md,
          0,
          LumiSpacing.md,
          LumiSpacing.md + safeBottom,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(LumiRadii.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: LumiColors.base.withValues(alpha: 0.70),
                borderRadius: BorderRadius.circular(LumiRadii.xl),
                border: Border.all(
                  color: LumiColors.subtext.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                  _tabs.length,
                  (i) => _NavButton(
                    icon: _tabs[i].icon,
                    label: _tabs[i].label,
                    isActive: i == currentIndex,
                    onTap: () => onTap(i),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  // primaryFixed circular glow behind active icon
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isActive
                          ? LumiColors.primaryFixed
                          : LumiColors.primaryFixed.withValues(alpha: 0),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(
                    icon,
                    size: 22,
                    color: isActive ? LumiColors.text : LumiColors.subtext,
                  ),
                ],
              ),
              const SizedBox(height: LumiSpacing.xs),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                style: TextStyle(
                  fontSize: LumiTypeScale.labelSm,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? LumiColors.text : LumiColors.subtext,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.path,
    required this.icon,
    required this.label,
  });

  final String path;
  final IconData icon;
  final String label;
}
