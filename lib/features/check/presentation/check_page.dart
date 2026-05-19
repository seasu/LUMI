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
            _CompareView(
              newImageBytes: Uint8List.fromList(newImageBytes),
              topMatches: topMatches,
              isHighSimilarity: true,
              onReset: () => ref.read(checkProvider.notifier).reset(),
              onAdd: () {
                ref.read(checkProvider.notifier).reset();
                context.push('/snap');
              },
            ),
          CheckMediumSimilarity(
            :final topMatches,
            :final newImageBytes,
          ) =>
            _CompareView(
              newImageBytes: Uint8List.fromList(newImageBytes),
              topMatches: topMatches,
              isHighSimilarity: false,
              onReset: () => ref.read(checkProvider.notifier).reset(),
              onAdd: () {
                ref.read(checkProvider.notifier).reset();
                context.push('/snap');
              },
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

// ── 比對結果（≥50%）：側並側照片比較 ──────────────────────────────────────────

class _CompareView extends StatelessWidget {
  const _CompareView({
    required this.newImageBytes,
    required this.topMatches,
    required this.isHighSimilarity,
    required this.onReset,
    required this.onAdd,
  });

  final Uint8List newImageBytes;
  final List<MatchedClothingItem> topMatches;
  final bool isHighSimilarity;
  final VoidCallback onReset;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final bestMatch = topMatches.first;
    final pct = (bestMatch.similarity * 100).toStringAsFixed(0);
    final secondaryMatches =
        topMatches.length > 1 ? topMatches.sublist(1) : <MatchedClothingItem>[];

    final accentColor = isHighSimilarity ? LumiColors.warning : LumiColors.primary;
    final bannerText = isHighSimilarity
        ? '衣櫥已有 $pct% 相似款，確認再入手！'
        : '衣櫥有 $pct% 相似款，可以再比較看看。';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        LumiSpacing.md,
        LumiSpacing.md,
        LumiSpacing.md,
        LumiSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 側並側照片比較 ──────────────────────────────────────────────
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - LumiSpacing.sm) / 2;
              final cardHeight = cardWidth * 4 / 3;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NewPhotoCard(
                    imageBytes: newImageBytes,
                    width: cardWidth,
                    height: cardHeight,
                  ),
                  const SizedBox(width: LumiSpacing.sm),
                  _BestMatchCard(
                    item: bestMatch,
                    width: cardWidth,
                    height: cardHeight,
                    pct: pct,
                    accentColor: accentColor,
                  ),
                ],
              );
            },
          ),

          // ── 其他相似衣物縮圖 ────────────────────────────────────────────
          if (secondaryMatches.isNotEmpty) ...[
            const SizedBox(height: LumiSpacing.md),
            const Text(
              '其他相似衣物',
              style: TextStyle(
                fontSize: LumiTypeScale.labelMd,
                color: LumiColors.subtext,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: LumiSpacing.sm),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: secondaryMatches.length,
                separatorBuilder: (_, __) => const SizedBox(width: LumiSpacing.sm),
                itemBuilder: (_, i) =>
                    _SecondaryMatchThumbnail(item: secondaryMatches[i]),
              ),
            ),
          ],

          const SizedBox(height: LumiSpacing.md),

          // ── 摘要提示橫幅 ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: LumiSpacing.md,
              vertical: LumiSpacing.sm + 2,
            ),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(LumiRadii.lg),
            ),
            child: Text(
              bannerText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: LumiTypeScale.labelMd,
                color: accentColor,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: LumiSpacing.lg),

          // ── 操作按鈕 ────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LumiColors.text,
                    side: const BorderSide(color: LumiColors.subtext),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(LumiRadii.pill),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: LumiSpacing.md),
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
        ],
      ),
    );
  }
}

// ── 新品照片卡（左側）────────────────────────────────────────────────────────

class _NewPhotoCard extends StatelessWidget {
  const _NewPhotoCard({
    required this.imageBytes,
    required this.width,
    required this.height,
  });

  final Uint8List imageBytes;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '想買的',
            style: TextStyle(
              fontSize: LumiTypeScale.labelMd,
              color: LumiColors.subtext,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: LumiSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(LumiRadii.lg),
            child: SizedBox(
              width: width,
              height: height,
              child: Image.memory(imageBytes, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 最相似衣物卡（右側，含漸層遮罩與徽章）────────────────────────────────────

class _BestMatchCard extends StatelessWidget {
  const _BestMatchCard({
    required this.item,
    required this.width,
    required this.height,
    required this.pct,
    required this.accentColor,
  });

  final MatchedClothingItem item;
  final double width;
  final double height;
  final String pct;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '衣櫥最相似',
            style: TextStyle(
              fontSize: LumiTypeScale.labelMd,
              color: LumiColors.subtext,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: LumiSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(LumiRadii.lg),
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _SimilarCardImage(localFileName: item.localFileName),
                  // Bottom scrim
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            LumiColors.text.withValues(alpha: 0.65),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Category label
                  if (item.category.isNotEmpty)
                    Positioned(
                      bottom: LumiSpacing.sm,
                      left: LumiSpacing.sm,
                      right: LumiSpacing.sm,
                      child: Text(
                        item.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: LumiTypeScale.labelSm,
                          fontWeight: FontWeight.w600,
                          color: LumiColors.onPrimary,
                        ),
                      ),
                    ),
                  // Similarity badge (top-right)
                  Positioned(
                    top: LumiSpacing.sm,
                    right: LumiSpacing.sm,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: LumiSpacing.sm,
                        vertical: LumiSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(LumiRadii.pill),
                      ),
                      child: Text(
                        '$pct% 相似',
                        style: const TextStyle(
                          fontSize: LumiTypeScale.labelSm,
                          fontWeight: FontWeight.w700,
                          color: LumiColors.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 次要相似衣物縮圖 ──────────────────────────────────────────────────────────

class _SecondaryMatchThumbnail extends StatelessWidget {
  const _SecondaryMatchThumbnail({required this.item});

  final MatchedClothingItem item;

  @override
  Widget build(BuildContext context) {
    final pct = (item.similarity * 100).toStringAsFixed(0);
    return SizedBox(
      width: 66,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(LumiRadii.md),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _SimilarCardImage(localFileName: item.localFileName),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 3),
                color: LumiColors.text.withValues(alpha: 0.55),
                child: Text(
                  '$pct%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: LumiTypeScale.labelSm,
                    fontWeight: FontWeight.w700,
                    color: LumiColors.onPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 衣物圖片載入（本機檔案）──────────────────────────────────────────────────

class _SimilarCardImage extends StatelessWidget {
  const _SimilarCardImage({required this.localFileName});

  final String? localFileName;

  @override
  Widget build(BuildContext context) {
    if (localFileName == null || localFileName!.isEmpty) {
      return const ColoredBox(
        color: LumiColors.surface,
        child: Center(
          child: Icon(Icons.checkroom_outlined, color: LumiColors.subtext, size: 36),
        ),
      );
    }
    return FutureBuilder<File?>(
      future: LocalImageStorage.getFile(localFileName),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) {
          return const ColoredBox(
            color: LumiColors.surface,
            child: Center(
              child: Icon(Icons.checkroom_outlined, color: LumiColors.subtext, size: 36),
            ),
          );
        }
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: LumiColors.surface,
            child: Center(
              child: Icon(Icons.checkroom_outlined, color: LumiColors.subtext, size: 36),
            ),
          ),
        );
      },
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
