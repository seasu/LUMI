# Component Reference — Lumi Digital Atelier

Production-ready Lumi 元件實作。複製並套用至專案。

## Table of Contents
1. [Wardrobe Card](#wardrobe-card)
2. [Filter Bar](#filter-bar)
3. [Empty State](#empty-state)
4. [Bottom Navigation](#bottom-navigation)
5. [Primary Button (Gradient Pill)](#primary-button)
6. [Secondary Button (Ghost Border)](#secondary-button)
7. [Snap FAB](#snap-fab)
8. [Lumi-Check Similarity Badge](#lumi-check-similarity-badge)
9. [Item Detail Modal](#item-detail-modal)
10. [Upload Progress Ring](#upload-progress-ring)
11. [AI Loading Orb](#ai-loading-orb)
12. [Shimmer Skeleton Card](#shimmer-skeleton-card)
13. [Wardrobe Header](#wardrobe-header)
14. [Lumi Logo Wordmark](#lumi-logo-wordmark)

---

## Wardrobe Card

2-column grid 衣物卡片。圖片填滿、下方顯示材質＋分類＋愛心 icon。

```dart
import 'package:flutter/material.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_radii.dart';

class WardrobeCard extends StatelessWidget {
  const WardrobeCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String imageUrl;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 圖片容器
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: LumiColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: LumiColors.base,
                  child: Center(
                    child: Icon(Icons.checkroom_outlined,
                        color: LumiColors.subtext, size: 32),
                  ),
                ),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return const ColoredBox(color: LumiColors.base);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          // 資訊列
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: LumiColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 9,
                        color: LumiColors.subtext,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  Icons.favorite_border,
                  size: 13,
                  color: LumiColors.subtext.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### Grid 配置

```dart
GridView.builder(
  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 10,
    mainAxisSpacing: 16,
    childAspectRatio: 0.74,
  ),
  itemCount: items.length,
  itemBuilder: (context, index) => WardrobeCard(...),
)
```

---

## Filter Bar

水平可捲動分類 Tab + 顏色圓形篩選 chip。

```dart
import 'package:flutter/material.dart';
import '../../../shared/constants/lumi_colors.dart';

class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;
  final List<Color> colors;
  final Color? selectedColor;
  final ValueChanged<Color?> onColorSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分類 Tab
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 20),
            itemBuilder: (_, i) {
              final cat = categories[i];
              final isActive = cat == selectedCategory;
              return InkWell(
                onTap: () => onCategorySelected(isActive ? null : cat),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      cat,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                        color: isActive ? LumiColors.text : LumiColors.subtext,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Underline indicator（非 pill/填色）
                    Container(
                      height: 2,
                      width: 24,
                      color: isActive ? LumiColors.primary : Colors.transparent,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // 顏色篩選圓形 chip
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: colors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final color = colors[i];
              final isActive = color == selectedColor;
              return InkWell(
                customBorder: const CircleBorder(),
                onTap: () => onColorSelected(isActive ? null : color),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    // Active：白色外框 2px
                    border: isActive
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                    // Active 時加柔和外圈
                    boxShadow: isActive
                        ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)]
                        : null,
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
```

---

## Empty State

空狀態：置中的衣架 icon + 引導文字。使用 `SizedBox.expand` + `MainAxisAlignment.center` 確保精準置中。

```dart
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.icon = Icons.dry_cleaning_outlined,
    this.title = '妳的衣櫥目前空空如也',
    this.subtitle = '點擊右上角的「加入新品」按鈕，\n開始建立妳的數位衣櫥吧！',
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 76,
            color: LumiColors.subtext.withOpacity(0.35),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: LumiColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: LumiColors.subtext,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Bottom Navigation

Glassmorphic 底部導航，3 Tab，無 elevation。

```dart
BottomNavigationBar(
  currentIndex: currentIndex,
  onTap: onTap,
  backgroundColor: LumiColors.surface.withOpacity(0.92),
  selectedItemColor: LumiColors.text,
  unselectedItemColor: LumiColors.subtext,
  selectedLabelStyle: const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  ),
  unselectedLabelStyle: const TextStyle(fontSize: 11),
  type: BottomNavigationBarType.fixed,
  elevation: 0,
  enableFeedback: false,
  items: const [
    BottomNavigationBarItem(
      icon: Icon(Icons.checkroom_outlined),
      label: '我的衣櫥',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.style_outlined),
      label: '我的穿搭',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.person_outline),
      label: '個人檔案',
    ),
  ],
)
```

---

## Primary Button

Capsule 漸層主按鈕。按壓時 scale 0.96。

```dart
class LumiPrimaryButton extends StatefulWidget {
  const LumiPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  State<LumiPrimaryButton> createState() => _LumiPrimaryButtonState();
}

class _LumiPrimaryButtonState extends State<LumiPrimaryButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (!widget.isLoading) widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            gradient: LumiColors.buttonGradient,
            borderRadius: BorderRadius.circular(LumiRadii.pill),
          ),
          child: Center(
            child: widget.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
```

---

## Secondary Button

Ghost Border capsule 次要按鈕。

```dart
OutlinedButton(
  style: OutlinedButton.styleFrom(
    side: BorderSide(color: LumiColors.subtext.withOpacity(0.2)),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(LumiRadii.pill),
    ),
    minimumSize: const Size(double.infinity, 52),
  ),
  onPressed: onTap,
  child: Text(
    label,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: LumiColors.text,
    ),
  ),
)
```

---

## Snap FAB

右下角浮動按鈕，通往似曾相識（Lumi-Check）。

```dart
class SnapFab extends StatelessWidget {
  const SnapFab({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 16,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            gradient: LumiColors.buttonGradient,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              '似',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## Lumi-Check Similarity Badge

相似度徽章：≥80% 用 `warning` 色，50–79% 用灰色。

```dart
class SimilarityBadge extends StatelessWidget {
  const SimilarityBadge({super.key, required this.similarity});

  final double similarity;

  @override
  Widget build(BuildContext context) {
    final isHigh = similarity >= 0.8;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHigh
            ? LumiColors.warning
            : LumiColors.subtext.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${(similarity * 100).toInt()}% 相似',
        style: TextStyle(
          color: isHigh ? Colors.white : LumiColors.subtext,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
```

---

## Item Detail Modal

底部滑入 Sheet 顯示衣物詳情。

```dart
void showItemDetailModal(BuildContext context, WardrobeItem item) {
  showModalBottomSheet(
    context: context,
    backgroundColor: LumiColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(LumiRadii.xl),
      ),
    ),
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(LumiSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 拖曳指示條
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: LumiColors.subtext.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: LumiSpacing.md),
              // 圖片
              ClipRRect(
                borderRadius: BorderRadius.circular(LumiRadii.lg),
                child: Image.network(item.thumbnailUrl, fit: BoxFit.cover),
              ),
              const SizedBox(height: LumiSpacing.md),
              // 分類
              Text(
                item.category,
                style: const TextStyle(
                  fontSize: LumiTypeScale.titleLg,
                  fontWeight: FontWeight.w600,
                  color: LumiColors.text,
                ),
              ),
              // ... 其他詳情欄位
            ],
          ),
        ),
      ),
    ),
  );
}
```

---

## Upload Progress Ring

上傳進度圓環，此處例外允許 `boxShadow`（橘色光暈效果）。

```dart
class UploadProgressRing extends StatelessWidget {
  const UploadProgressRing({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: LumiColors.glow.withOpacity(0.5),
                blurRadius: 24,
              ),
            ],
          ),
        ),
        SizedBox(
          width: 100,
          height: 100,
          child: CircularProgressIndicator(
            value: progress,
            color: LumiColors.primary,
            backgroundColor: LumiColors.primary.withOpacity(0.15),
            strokeWidth: 6,
          ),
        ),
        Text(
          '${(progress * 100).toInt()}%',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: LumiColors.primary,
          ),
        ),
      ],
    );
  }
}
```

---

## AI Loading Orb

暖橙光暈 Orb，替代 `CircularProgressIndicator`。

```dart
class GlowOrb extends StatefulWidget {
  const GlowOrb({super.key, this.size = 80});

  final double size;

  @override
  State<GlowOrb> createState() => _GlowOrbState();
}

class _GlowOrbState extends State<GlowOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _opacity = Tween(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: LumiColors.glow.withOpacity(_opacity.value),
        ),
      ),
    );
  }
}
```

---

## Shimmer Skeleton Card

載入佔位骨架，用於衣櫥 grid。

```dart
class ShimmerCard extends StatefulWidget {
  const ShimmerCard({super.key});

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment(-1.0 + 2 * _controller.value, 0),
                  end: Alignment(-1.0 + 2 * _controller.value + 1, 0),
                  colors: const [
                    Color(0xFFF0EBE5),
                    Color(0xFFF7F3EE),
                    Color(0xFFF0EBE5),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EBE5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EBE5),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Wardrobe Header

頁面 Header：標題 + 右側「加入新品」按鈕。

```dart
class WardrobeHeader extends StatelessWidget {
  const WardrobeHeader({super.key, required this.onAddTap});

  final VoidCallback onAddTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Text(
              '我的衣櫥',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: LumiColors.text,
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onAddTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.add, size: 18, color: LumiColors.primary),
            label: const Text(
              '加入新品',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: LumiColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Lumi Logo Wordmark

品牌字標，Dancing Script + i 上方橘色閃爍光點。

```dart
// 完整實作見 lib/shared/widgets/lumi_logo_wordmark.dart
// 關鍵特徵：
// - 字體：GoogleFonts.dancingScript, w600
// - i 上方：RadialGradient 光點（白 → glow → primaryLight → primary → 透明）
// - 動畫：TweenSequence 快閃 + 慢呼吸，2400ms repeat
// - 尺寸：fontSize 56 預設，容器 width = fontSize * 3.2
```
