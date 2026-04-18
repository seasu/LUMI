import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/lumi_colors.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _TabItem(path: '/home', icon: Icons.checkroom_outlined, label: '我的衣櫥'),
    _TabItem(path: '/home/outfits', icon: Icons.style_outlined, label: '我的穿搭'),
    _TabItem(path: '/home/profile', icon: Icons.person_outline, label: '個人檔案'),
  ];

  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/home/outfits')) return 1;
    if (loc.startsWith('/home/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      backgroundColor: LumiColors.base,
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => context.go(_tabs[i].path),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        enableFeedback: false,
        items: _tabs
            .map((t) => BottomNavigationBarItem(
                  icon: Icon(t.icon),
                  label: t.label,
                ))
            .toList(),
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
