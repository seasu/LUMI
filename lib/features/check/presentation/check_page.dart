import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/storage/local_image_storage.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_radii.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../shared/constants/lumi_type_scale.dart';
import '../../../features/snap/data/cloud_functions_service.dart';
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
    final canGoBackToIdle = state is! CheckIdle && state is! CheckAnalyzing;

    return Scaffold(
      backgroundColor: LumiColors.base,
      appBar: AppBar(
        backgroundColor: LumiColors.base,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: TextButton(
          onPressed: isAnalyzing
              ? null
              : () {
                  if (canGoBackToIdle) {
                    ref.read(checkProvider.notifier).reset();
                  } else {
                    context.pop();
                  }
                },
          child: Text(
            canGoBackToIdle ? '< 上一步' : '< 回衣櫥',
            style: const TextStyle(
              fontSize: LumiTypeScale.labelMd,
              color: LumiColors.primary,
            ),
          ),
        ),
        leadingWidth: 100,
        title: const Text(
          '似曾相識',
          style: TextStyle(
            fontSize: LumiTypeScale.titleSm,
            fontWeight: FontWeight.w700,
            color: LumiColors.text,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: switch (state) {
          CheckIdle() => _IdleView(
              onCamera: () => ref.read(checkProvider.notifier).check(),
              onGallery: () => ref
                  .read(checkProvider.notifier)
                  .check(source: ImageSource.gallery),
              onCancel: () => context.pop(),
            ),
          CheckAnalyzing() => _GlowView(animation: _glowAnimation),
          CheckHighSimilarity(
            :final topMatches,
            :final newImageBytes,
          ) =>
            _ResultView(
              newImageBytes: Uint8List.fromList(newImageBytes),
              topMatches: topMatches,
              onReset: () => ref.read(checkProvider.notifier).reset(),
              onAdd: () {
                ref.read(checkProvider.notifier).reset();
                context.push('/snap');
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
  const _IdleView({
    required this.onCamera,
    required this.onGallery,
    required this.onCancel,
  });

  final VoidCallback onCamera;
  final VoidCallback onGallery;
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
              colors: [LumiColors.baseAlt, LumiColors.base],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 76,
              color: LumiColors.primary,
            ),
          ),
        ),
        // 下半：白色圓角卡片
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: LumiColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(LumiRadii.xl)),
            ),
            padding: const EdgeInsets.fromLTRB(LumiSpacing.lg, LumiSpacing.lg + LumiSpacing.xs, LumiSpacing.lg, 0),
            child: Column(
              children: [
                const Text(
                  '開始比對',
                  style: TextStyle(
                    fontSize: LumiTypeScale.titleLg,
                    fontWeight: FontWeight.w700,
                    color: LumiColors.text,
                  ),
                ),
                const SizedBox(height: LumiSpacing.sm),
                const Text(
                  '拍下妳想買的衣物，Lumi 將立即為妳從衣櫥中\n尋找相似款式，讓妳購物更有底氣。',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: LumiTypeScale.labelMd,
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
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: LumiColors.glow.withValues(alpha: 0.22),
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
                _PrimaryButton(label: '開始拍照', onTap: onCamera),
                const SizedBox(height: LumiSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: onGallery,
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('從相簿選取'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LumiColors.primary,
                      side: BorderSide(
                          color: LumiColors.primary.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(LumiRadii.pill),
                      ),
                      textStyle: const TextStyle(
                        fontSize: LumiTypeScale.labelMd,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: LumiSpacing.xs),
                TextButton(
                  onPressed: onCancel,
                  child: const Text(
                    '取消',
                    style: TextStyle(fontSize: LumiTypeScale.body, color: LumiColors.subtext),
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
                    LumiColors.glow.withValues(alpha: 0.3 + animation.value * 0.7),
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
              fontSize: LumiTypeScale.body,
              color: LumiColors.subtext,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 比對結果（≥ 80%）：水平輪播 ───────────────────────────────────────────────

class _ResultView extends StatefulWidget {
  const _ResultView({
    required this.newImageBytes,
    required this.topMatches,
    required this.onReset,
    required this.onAdd,
  });

  final Uint8List newImageBytes;
  final List<MatchedClothingItem> topMatches;
  final VoidCallback onReset;
  final VoidCallback onAdd;

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> {
  late final PageController _pageController;
  // Start on the highest-similarity item (index 0 after sort)
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.68,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentItem = widget.topMatches[_currentPage];
    final currentPct = (currentItem.similarity * 100).toStringAsFixed(0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: LumiSpacing.md),
          // 新品照片
          _NewItemCard(imageBytes: widget.newImageBytes),
          const SizedBox(height: LumiSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.sm + LumiSpacing.xs, vertical: LumiSpacing.xs),
            decoration: BoxDecoration(
              color: LumiColors.warning.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(LumiRadii.pill),
            ),
            child: Text(
              '$currentPct% 相似',
              style: const TextStyle(
                fontSize: LumiTypeScale.labelSm,
                fontWeight: FontWeight.w700,
                color: LumiColors.warning,
              ),
            ),
          ),
          const SizedBox(height: LumiSpacing.sm),
          // 相似衣物水平輪播
          SizedBox(
            height: 240,
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.topMatches.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (context, index) {
                final item = widget.topMatches[index];
                final isCenter = index == _currentPage;
                return _SimilarCard(
                  item: item,
                  isHighlighted: isCenter,
                );
              },
            ),
          ),
          const SizedBox(height: LumiSpacing.sm),
          // 頁面指示點
          if (widget.topMatches.length > 1)
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.topMatches.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: LumiSpacing.xs),
                    width: active ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(LumiRadii.pill),
                      color: active
                          ? LumiColors.primary
                          : LumiColors.subtext.withValues(alpha: 0.3),
                    ),
                  );
                }),
              ),
            ),
          const Spacer(),
          // 雙按鈕
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onReset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LumiColors.text,
                    side: const BorderSide(color: LumiColors.subtext),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(LumiRadii.pill)),
                    padding:
                        const EdgeInsets.symmetric(vertical: LumiSpacing.md),
                  ),
                  child: const Text('已經有了'),
                ),
              ),
              const SizedBox(width: LumiSpacing.sm),
              Expanded(
                child: _PrimaryButton(label: '加入新品', onTap: widget.onAdd),
              ),
            ],
          ),
          const SizedBox(height: LumiSpacing.lg),
        ],
      ),
    );
  }
}

class _NewItemCard extends StatelessWidget {
  const _NewItemCard({required this.imageBytes});
  final Uint8List imageBytes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '新品',
          style: TextStyle(
            fontSize: LumiTypeScale.labelMd,
            color: LumiColors.subtext,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: LumiSpacing.xs),
        Container(
          height: 180,
          decoration: BoxDecoration(
            color: LumiColors.surface,
            borderRadius: BorderRadius.circular(LumiRadii.lg),
          ),
          clipBehavior: Clip.antiAlias,
          child: SizedBox.expand(
            child: Image.memory(imageBytes, fit: BoxFit.cover),
          ),
        ),
      ],
    );
  }
}

class _SimilarCard extends StatelessWidget {
  const _SimilarCard({
    required this.item,
    required this.isHighlighted,
  });

  final MatchedClothingItem item;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final pct = (item.similarity * 100).toStringAsFixed(0);
    final colorLabel =
        item.colors.isNotEmpty ? item.colors.first : '—';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: LumiSpacing.sm, vertical: LumiSpacing.xs),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(LumiRadii.lg),
        border: isHighlighted
            ? Border.all(color: LumiColors.primary, width: 2.5)
            : Border.all(color: Colors.transparent, width: 2.5),
        color: LumiColors.surface,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 衣物圖片
              Expanded(
                child: _SimilarCardImage(localFileName: item.localFileName),
              ),
              // 衣物資訊
              Padding(
                padding: const EdgeInsets.all(LumiSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '類別：${item.category.isEmpty ? "—" : item.category}',
                      style: const TextStyle(
                        fontSize: LumiTypeScale.labelSm,
                        color: LumiColors.subtext,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '顏色：$colorLabel',
                      style: const TextStyle(
                        fontSize: LumiTypeScale.labelSm,
                        color: LumiColors.subtext,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 相似度徽章（右上角）
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.sm, vertical: LumiSpacing.xs),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? LumiColors.warning
                    : LumiColors.subtext.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(LumiRadii.pill),
              ),
              child: Text(
                '$pct%\n相似',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: LumiTypeScale.labelSm,
                  fontWeight: FontWeight.w700,
                  color: LumiColors.onPrimary,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SimilarCardImage extends StatelessWidget {
  const _SimilarCardImage({required this.localFileName});

  final String? localFileName;

  @override
  Widget build(BuildContext context) {
    if (localFileName == null || localFileName!.isEmpty) {
      return const Center(
        child: Icon(Icons.checkroom_outlined, color: LumiColors.subtext, size: 36),
      );
    }
    return FutureBuilder<File?>(
      future: LocalImageStorage.getFile(localFileName),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) {
          return const Center(
            child: Icon(Icons.checkroom_outlined, color: LumiColors.subtext, size: 36),
          );
        }
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.checkroom_outlined, color: LumiColors.subtext, size: 36),
          ),
        );
      },
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
              borderRadius: BorderRadius.circular(LumiRadii.xl),
            ),
            child: Column(
              children: [
                const Icon(Icons.info_outline,
                    size: 32, color: LumiColors.subtext),
                const SizedBox(height: LumiSpacing.md),
                const Text(
                  '可能相似',
                  style: TextStyle(
                    fontSize: LumiTypeScale.titleLg,
                    fontWeight: FontWeight.w600,
                    color: LumiColors.text,
                  ),
                ),
                const SizedBox(height: LumiSpacing.sm),
                Text(
                  '衣櫥中有 $pct% 相似的$matchedCategory，\n可以再比較看看。',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: LumiTypeScale.labelMd,
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
              fontSize: LumiTypeScale.titleLg,
              fontWeight: FontWeight.w600,
              color: LumiColors.text,
            ),
          ),
          const SizedBox(height: LumiSpacing.sm),
          const Text(
            '這件衣物在妳的衣櫥裡找不到相似款，\n可以安心入手！',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: LumiTypeScale.labelMd, color: LumiColors.subtext, height: 1.6),
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
              color: LumiColors.warning.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(LumiRadii.lg),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: LumiTypeScale.labelMd,
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
          borderRadius: BorderRadius.circular(LumiRadii.pill),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: LumiTypeScale.titleSm,
              fontWeight: FontWeight.w600,
              color: LumiColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
