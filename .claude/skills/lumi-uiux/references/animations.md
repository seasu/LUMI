# Animation Recipes — Lumi Digital Atelier

Lumi 風格動畫食譜。所有動畫追求「被感覺到但不喧賓奪主」——柔和、有機、溫暖。

## Table of Contents
1. [Glow Orb Pulse（AI 處理）](#glow-orb-pulse)
2. [Sparkle Wordmark（品牌光點）](#sparkle-wordmark)
3. [Upload Progress Glow（上傳光暈）](#upload-progress-glow)
4. [Shimmer Skeleton（載入骨架）](#shimmer-skeleton)
5. [Button Press Scale（按鈕回饋）](#button-press-scale)
6. [Modal Slide Up（底部 Sheet）](#modal-slide-up)
7. [Staggered Grid Entry（卡片進場）](#staggered-grid-entry)
8. [Success Checkmark（完成打勾）](#success-checkmark)
9. [Similarity Alert Pulse（警示脈衝）](#similarity-alert-pulse)
10. [Page Transition（頁面轉場）](#page-transition)

---

## Glow Orb Pulse

AI 處理中的暖橙光暈。opacity 0.3 → 1.0 循環，`Curves.easeInOut`。
**禁止使用 `CircularProgressIndicator` 替代此動畫。**

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

### 搭配文字使用

```dart
Column(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    const GlowOrb(size: 80),
    const SizedBox(height: 24),
    Text(
      'AI 分析中...',
      style: TextStyle(
        fontSize: LumiTypeScale.body,
        color: LumiColors.subtext,
      ),
    ),
  ],
)
```

---

## Sparkle Wordmark

Lumi 品牌字標上方的閃爍光點。TweenSequence 實現快閃 + 慢呼吸雙節奏。

```dart
// 動畫結構：2400ms 週期
// Phase 1（快閃）：0→1.0→0.25，佔 30% 時間
// Phase 2（慢呼吸）：0.25→0.75→0.35，佔 70% 時間

late final _sparkleSizeAnimation = TweenSequence<double>([
  TweenSequenceItem(
    tween: Tween(begin: 0.0, end: 1.0)
        .chain(CurveTween(curve: Curves.easeOutCubic)),
    weight: 15,
  ),
  TweenSequenceItem(
    tween: Tween(begin: 1.0, end: 0.25)
        .chain(CurveTween(curve: Curves.easeInCubic)),
    weight: 15,
  ),
  TweenSequenceItem(
    tween: Tween(begin: 0.25, end: 0.75)
        .chain(CurveTween(curve: Curves.easeInOut)),
    weight: 35,
  ),
  TweenSequenceItem(
    tween: Tween(begin: 0.75, end: 0.35)
        .chain(CurveTween(curve: Curves.easeInOut)),
    weight: 35,
  ),
]).animate(_sparkleController);

// 光點渲染：RadialGradient
Container(
  width: 18 + (t * 8),
  height: 18 + (t * 8),
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    gradient: RadialGradient(
      colors: [
        Colors.white.withOpacity(0.95),
        LumiColors.glow.withOpacity(0.92),
        LumiColors.primaryLight.withOpacity(0.65 + g * 0.25),
        LumiColors.primary.withOpacity(0.22 + g * 0.2),
        Colors.transparent,
      ],
      stops: const [0.0, 0.22, 0.5, 0.72, 1.0],
    ),
  ),
)
```

---

## Upload Progress Glow

上傳進度圓環外圈橘色光暈。此處例外允許 `boxShadow`。

```dart
// 光暈容器
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
)

// 進度環
CircularProgressIndicator(
  value: progress,
  color: LumiColors.primary,
  backgroundColor: LumiColors.primary.withOpacity(0.15),
  strokeWidth: 6,
)
```

### 完成動畫

上傳完成時：glow 擴散 + 橘色勾勾淡入。

```dart
// 擴散：AnimatedContainer width 120 → 160，opacity 0.5 → 0
// 勾勾：Icon(Icons.check_circle, color: LumiColors.primary, size: 64)
// 搭配 ScaleTransition（0.5 → 1.0, Curves.easeOutBack）
```

---

## Shimmer Skeleton

暖色調 shimmer，匹配 `LumiColors.base` 背景。
**禁止使用冷灰色（#EEE）shimmer，必須用暖色。**

```dart
// Shimmer 色帶
final shimmerColors = [
  const Color(0xFFF0EBE5),  // 暖灰棕-淺
  const Color(0xFFF7F3EE),  // 暖灰棕-更淺
  const Color(0xFFF0EBE5),
];

// 動畫 gradient
LinearGradient(
  begin: Alignment(-1.0 + 2 * _controller.value, 0),
  end: Alignment(-1.0 + 2 * _controller.value + 1, 0),
  colors: shimmerColors,
)

// 週期：1500ms repeat
// 應用：圓角 20 的卡片 + 下方兩條短文字佔位條
```

---

## Button Press Scale

Capsule 按鈕的觸覺回饋。

```dart
// 參數
final duration = Duration(milliseconds: 120);
final scaleDown = 0.96;  // Quiet Luxury 風格——微妙，不誇張

// Controller
_controller = AnimationController(vsync: this, duration: duration);
_scale = Tween(begin: 1.0, end: scaleDown).animate(
  CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
);

// 手勢
GestureDetector(
  onTapDown: (_) => _controller.forward(),
  onTapUp: (_) {
    _controller.reverse();
    onTap();
  },
  onTapCancel: () => _controller.reverse(),
  child: AnimatedBuilder(
    animation: _scale,
    builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
    child: buttonContent,
  ),
)
```

---

## Modal Slide Up

底部 Sheet 滑入效果。

```dart
showModalBottomSheet(
  context: context,
  backgroundColor: LumiColors.surface,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(LumiRadii.xl),  // 24
    ),
  ),
  isScrollControlled: true,
  builder: (context) => DraggableScrollableSheet(
    initialChildSize: 0.7,
    minChildSize: 0.4,
    maxChildSize: 0.95,
    expand: false,
    builder: (_, scrollController) => ...,
  ),
);
```

---

## Staggered Grid Entry

衣物卡片交錯進場。每張卡片延遲 `index * 60ms`。

```dart
class StaggeredCardEntry extends StatefulWidget {
  const StaggeredCardEntry({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  State<StaggeredCardEntry> createState() => _StaggeredCardEntryState();
}

class _StaggeredCardEntryState extends State<StaggeredCardEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    final delay = (widget.index * 0.08).clamp(0.0, 0.6);
    final interval = Interval(delay, 1.0, curve: Curves.easeOutCubic);

    _opacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: interval),
    );
    _slide = Tween(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: interval),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
```

---

## Success Checkmark

上傳/分析完成的打勾動畫。

```dart
class SuccessCheckmark extends StatefulWidget {
  const SuccessCheckmark({super.key});

  @override
  State<SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glowRadius;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scale = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _glowRadius = Tween(begin: 0.0, end: 40.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
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
      builder: (_, __) => Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: LumiColors.glow.withOpacity(
                0.5 * (1.0 - _controller.value),
              ),
              blurRadius: _glowRadius.value,
            ),
          ],
        ),
        child: Transform.scale(
          scale: _scale.value,
          child: const Icon(
            Icons.check_circle,
            color: LumiColors.primary,
            size: 64,
          ),
        ),
      ),
    );
  }
}
```

---

## Similarity Alert Pulse

Lumi-Check 高相似度 Badge 的微弱脈衝提示。

```dart
// 僅在 similarity >= 0.8 時啟用
// scale 1.0 → 1.05，opacity 0.8 → 1.0
// 週期 1200ms，Curves.easeInOut
// 色彩：LumiColors.warning

late final _pulse = Tween(begin: 1.0, end: 1.05).animate(
  CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
);

Transform.scale(
  scale: _pulse.value,
  child: SimilarityBadge(similarity: 0.92),
)
```

---

## Page Transition

水平滑入，用於 Onboarding 頁面間切換。

```dart
class LumiSlideTransition extends PageRouteBuilder {
  final Widget page;

  LumiSlideTransition({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, __, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return SlideTransition(
              position: Tween(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(curved),
              child: FadeTransition(
                opacity: Tween(begin: 0.3, end: 1.0).animate(curved),
                child: child,
              ),
            );
          },
        );
}
```

---

## Animation Design Principles

Lumi 動畫的三大原則：

1. **Warm & Organic**：使用 `easeInOut`、`easeOutCubic`、`easeOutBack`。禁止線性或彈跳曲線。
2. **Subtle, Not Flashy**：scale 變化不超過 ±10%，opacity 漸變不快於 300ms。
3. **Purpose-Driven**：每個動畫必須傳達資訊（載入中、完成、警示），不做純裝飾性動畫。

### 推薦 Curve
| 用途 | Curve |
|------|-------|
| 標準過渡 | `Curves.easeInOut` |
| 進場 | `Curves.easeOutCubic` |
| 離場 | `Curves.easeInCubic` |
| 彈出效果（完成勾、Badge） | `Curves.easeOutBack` |
| 光暈呼吸 | `Curves.easeInOut` |

### 禁止
- `Curves.bounceOut` — 太活潑，不符合 Quiet Luxury
- `Curves.linear` — 機械感，不有機
- 超過 2 秒的單一動畫（光暈循環除外）
- 畫面同時超過 3 個獨立動畫（效能＋視覺干擾）
