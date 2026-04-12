import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../domain/check_state.dart';
import 'providers/check_provider.dart';

class CheckPage extends ConsumerStatefulWidget {
  const CheckPage({super.key});

  @override
  ConsumerState<CheckPage> createState() => _CheckPageState();
}

class _CheckPageState extends ConsumerState<CheckPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkProvider);
    final isAnalyzing = state is CheckAnalyzing;

    return Scaffold(
      backgroundColor: LumiColors.base,
      appBar: AppBar(
        backgroundColor: LumiColors.base,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: TextButton(
          onPressed: isAnalyzing ? null : () => context.pop(),
          child: const Text(
            '< 回衣櫥',
            style: TextStyle(
              fontSize: 14,
              color: LumiColors.primary,
            ),
          ),
        ),
        leadingWidth: 100,
        title: const Text(
          '似曾相識',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: LumiColors.text,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: switch (state) {
          CheckIdle() => _IdleView(
              onCheck: () => ref.read(checkProvider.notifier).check(),
              onCancel: () => context.pop(),
            ),
          CheckAnalyzing() => _GlowView(animation: _glowAnimation),
          CheckHighSimilarity(
            :final similarity,
            :final matchedThumbnailUrl,
            :final matchedCategory,
            :final newImageBytes,
          ) =>
            _ResultView(
              newImageBytes: Uint8List.fromList(newImageBytes),
              matchedThumbnailUrl: matchedThumbnailUrl,
              matchedCategory: matchedCategory,
              similarity: similarity,
              onReset: () => ref.read(checkProvider.notifier).reset(),
              onAdd: () {
                ref.read(checkProvider.notifier).reset();
                context.pop();
              },
            ),
          CheckMediumSimilarity(
            :final similarity,
            :final matchedCategory,
          ) =>
            _MediumView(
              similarity: similarity,
              matchedCategory: matchedCategory,
              onReset: () => ref.read(checkProvider.notifier).reset(),
            ),
          CheckNone() => _NoneView(
              onReset: () => ref.read(checkProvider.notifier).reset(),
            ),
          CheckError(:final message) => _ErrorView(
              message: message,
              onRetry: () => ref.read(checkProvider.notifier).check(),
            ),
        },
      ),
    );
  }
}

// ── Idle（入口）──────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onCheck, required this.onCancel});

  final VoidCallback onCheck;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 上半：購物情境色塊
        Container(
          height: MediaQuery.sizeOf(context).height * 0.40,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE8D5C0), Color(0xFFD4B896)],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.white,
            ),
          ),
        ),
        // 下半：白色圓角卡片
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: LumiColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Column(
              children: [
                const Text(
                  '開始比對',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: LumiColors.text,
                  ),
                ),
                const SizedBox(height: LumiSpacing.sm),
                const Text(
                  '拍下妳想買的衣物，Lumi 將立即為妳從衣櫥中\n尋找相似款式，讓妳購物更有底氣。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: LumiColors.subtext,
                    height: 1.6,
                  ),
                ),
                const Spacer(),
                // 相機插圖
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: LumiColors.glow.withOpacity(0.2),
                      ),
                    ),
                    const Icon(
                      Icons.camera_alt_outlined,
                      size: 40,
                      color: LumiColors.primary,
                    ),
                  ],
                ),
                const Spacer(),
                _PrimaryButton(label: '開始拍照', onTap: onCheck),
                const SizedBox(height: LumiSpacing.sm),
                TextButton(
                  onPressed: onCancel,
                  child: const Text(
                    '取消',
                    style: TextStyle(fontSize: 15, color: LumiColors.subtext),
                  ),
                ),
                const SizedBox(height: LumiSpacing.lg),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── AI 分析中（Glow Orb）────────────────────────────────────────────────────

class _GlowView extends StatelessWidget {
  const _GlowView({required this.animation});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: animation,
            builder: (_, __) => Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    LumiColors.glow.withOpacity(0.3 + animation.value * 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: LumiSpacing.lg),
          const Text(
            'AI 比對中...',
            style: TextStyle(
              fontSize: 15,
              color: LumiColors.subtext,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 比對結果（≥ 80%）──────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.newImageBytes,
    required this.matchedThumbnailUrl,
    required this.matchedCategory,
    required this.similarity,
    required this.onReset,
    required this.onAdd,
  });

  final Uint8List newImageBytes;
  final String matchedThumbnailUrl;
  final String matchedCategory;
  final double similarity;
  final VoidCallback onReset;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final pct = (similarity * 100).toStringAsFixed(0);
    final isHigh = similarity >= 0.8;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.md),
      child: Column(
        children: [
          const SizedBox(height: LumiSpacing.md),
          // 新品照片
          _ImageCard(
            label: '新品',
            child: Image.memory(newImageBytes, fit: BoxFit.cover),
          ),
          const SizedBox(height: LumiSpacing.md),
          // 比對結果橫向列
          Row(
            children: [
              Expanded(
                child: _SimilarCard(
                  similarity: similarity,
                  isHighlighted: isHigh,
                  child: Image.network(
                    matchedThumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.checkroom_outlined,
                      color: LumiColors.subtext,
                    ),
                  ),
                  category: matchedCategory,
                  pct: pct,
                ),
              ),
            ],
          ),
          const Spacer(),
          // 雙按鈕
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LumiColors.text,
                    side: const BorderSide(color: LumiColors.subtext),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28)),
                    padding: const EdgeInsets.symmetric(
                        vertical: LumiSpacing.md),
                  ),
                  child: const Text('已經有了'),
                ),
              ),
              const SizedBox(width: LumiSpacing.sm),
              Expanded(
                child: _PrimaryButton(label: '加入新品', onTap: onAdd),
              ),
            ],
          ),
          const SizedBox(height: LumiSpacing.lg),
        ],
      ),
    );
  }
}

class _ImageCard extends StatelessWidget {
  const _ImageCard({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: LumiColors.subtext,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: LumiSpacing.xs),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: LumiColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox.expand(child: child),
        ),
      ],
    );
  }
}

class _SimilarCard extends StatelessWidget {
  const _SimilarCard({
    required this.similarity,
    required this.isHighlighted,
    required this.child,
    required this.category,
    required this.pct,
  });

  final double similarity;
  final bool isHighlighted;
  final Widget child;
  final String category;
  final String pct;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted
            ? Border.all(color: LumiColors.primary, width: 2.5)
            : null,
        color: LumiColors.surface,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          AspectRatio(aspectRatio: 1, child: child),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: LumiSpacing.sm, vertical: LumiSpacing.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '類別：$category',
                  style: const TextStyle(
                      fontSize: 11, color: LumiColors.subtext),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: LumiSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: isHighlighted
                        ? LumiColors.warning
                        : LumiColors.subtext.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$pct% 相似',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isHighlighted
                          ? Colors.white
                          : LumiColors.subtext,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 中等相似（50–79%）────────────────────────────────────────────────────────

class _MediumView extends StatelessWidget {
  const _MediumView({
    required this.similarity,
    required this.matchedCategory,
    required this.onReset,
  });

  final double similarity;
  final String matchedCategory;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final pct = (similarity * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.all(LumiSpacing.md),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(LumiSpacing.lg),
            decoration: BoxDecoration(
              color: LumiColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                const Icon(Icons.info_outline,
                    size: 32, color: LumiColors.subtext),
                const SizedBox(height: LumiSpacing.md),
                const Text(
                  '可能相似',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: LumiColors.text,
                  ),
                ),
                const SizedBox(height: LumiSpacing.sm),
                Text(
                  '衣櫥中有 $pct% 相似的$matchedCategory，\n可以再比較看看。',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: LumiColors.subtext,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          _PrimaryButton(label: '再比一件', onTap: onReset),
          const SizedBox(height: LumiSpacing.xl),
        ],
      ),
    );
  }
}

// ── 無相似 ────────────────────────────────────────────────────────────────────

class _NoneView extends StatelessWidget {
  const _NoneView({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(LumiSpacing.md),
      child: Column(
        children: [
          const Spacer(),
          const Icon(Icons.check_circle_outline,
              size: 64, color: LumiColors.primary),
          const SizedBox(height: LumiSpacing.md),
          const Text(
            '衣櫥中無相似款式',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: LumiColors.text,
            ),
          ),
          const SizedBox(height: LumiSpacing.sm),
          const Text(
            '這件衣物在妳的衣櫥裡找不到相似款，\n可以安心入手！',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14, color: LumiColors.subtext, height: 1.6),
          ),
          const Spacer(),
          _PrimaryButton(label: '再比一件', onTap: onReset),
          const SizedBox(height: LumiSpacing.xl),
        ],
      ),
    );
  }
}

// ── 錯誤 ──────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(LumiSpacing.md),
      child: Column(
        children: [
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(LumiSpacing.md),
            decoration: BoxDecoration(
              color: LumiColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: LumiColors.warning,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: LumiSpacing.lg),
          _PrimaryButton(label: '重試', onTap: onRetry),
          const Spacer(),
        ],
      ),
    );
  }
}

// ── 共用主按鈕 ────────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LumiColors.buttonGradient,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
