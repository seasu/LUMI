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
  const CheckPage({super.key, this.autoSource});

  final ImageSource? autoSource;

  @override
  ConsumerState<CheckPage> createState() => _CheckPageState();
}

class _CheckPageState extends ConsumerState<CheckPage> {
  @override
  void initState() {
    super.initState();
    if (widget.autoSource != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(checkProvider.notifier)
            .check(source: widget.autoSource!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checkProvider);
    final isAnalyzing = state is CheckAnalyzing;

    // 分析中：移除 AppBar，讓照片全幅覆蓋整個畫面
    final appBar = isAnalyzing
        ? null
        : AppBar(
            backgroundColor: LumiColors.base,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: TextButton(
              onPressed: () => context.pop(),
              child: const Text(
                '< 回衣櫥',
                style: TextStyle(
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
          );

    final Widget body = switch (state) {
      // 短暫過渡：autoSource 觸發後立即轉 CheckAnalyzing，不顯示任何 UI
      CheckIdle() => const SizedBox.expand(),

      // 分析中：全幅照片背景，無 SafeArea 限制
      CheckAnalyzing(:final imageBytes) => _GlowView(
          imageBytes: Uint8List.fromList(imageBytes),
        ),

      // 結果：完成後 pop 回衣櫥
      CheckHighSimilarity(:final topMatches, :final newImageBytes) => SafeArea(
          child: _CompareView(
            newImageBytes: Uint8List.fromList(newImageBytes),
            topMatches: topMatches,
            isHighSimilarity: true,
            onReset: () => context.pop(),
            onAdd: () {
              context.pop();
              context.push('/snap');
            },
          ),
        ),
      CheckMediumSimilarity(:final topMatches, :final newImageBytes) =>
        SafeArea(
          child: _CompareView(
            newImageBytes: Uint8List.fromList(newImageBytes),
            topMatches: topMatches,
            isHighSimilarity: false,
            onReset: () => context.pop(),
            onAdd: () {
              context.pop();
              context.push('/snap');
            },
          ),
        ),
      CheckNone() => SafeArea(
          child: _NoneView(onDone: () => context.pop()),
        ),
      CheckError(:final message) => SafeArea(
          child: _ErrorView(
            message: message,
            onRetry: () => ref.read(checkProvider.notifier).check(
                  source: widget.autoSource ?? ImageSource.camera,
                ),
          ),
        ),
    };

    return Scaffold(
      backgroundColor: LumiColors.base,
      extendBodyBehindAppBar: isAnalyzing,
      appBar: appBar,
      body: body,
    );
  }
}

// ── AI 分析中：照片背景 + Sonar 脈衝動畫 ────────────────────────────────────

class _GlowView extends StatefulWidget {
  const _GlowView({required this.imageBytes});
  final Uint8List imageBytes;

  @override
  State<_GlowView> createState() => _GlowViewState();
}

class _GlowViewState extends State<_GlowView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    duration: const Duration(milliseconds: 2200),
    vsync: this,
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final botPad = MediaQuery.of(context).padding.bottom;
    final hasPhoto = widget.imageBytes.isNotEmpty;

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── 照片背景 ──────────────────────────────────────────────────────
        if (hasPhoto)
          Image.memory(widget.imageBytes, fit: BoxFit.cover)
        else
          const ColoredBox(color: LumiColors.base),

        // ── 半透明暗色遮罩 ─────────────────────────────────────────────────
        Container(color: LumiColors.text.withValues(alpha: 0.52)),

        // ── Sonar 脈衝（3 圈交錯，1 控制器） ──────────────────────────────
        Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              final v = _ctrl.value;
              return SizedBox(
                width: 220,
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _SonarRing(value: v),
                    _SonarRing(value: (v + 1 / 3) % 1.0),
                    _SonarRing(value: (v + 2 / 3) % 1.0),
                    // 核心光點
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: LumiColors.glow,
                        boxShadow: [
                          BoxShadow(
                            color: LumiColors.glow.withValues(alpha: 0.55),
                            blurRadius: 18,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // ── 底部漸層 scrim + 文字 ──────────────────────────────────────────
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              LumiSpacing.lg,
              LumiSpacing.xl * 2,
              LumiSpacing.lg,
              botPad + LumiSpacing.xl,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  LumiColors.text.withValues(alpha: 0.72),
                  Colors.transparent,
                ],
              ),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AI 比對中',
                  style: TextStyle(
                    fontSize: LumiTypeScale.titleLg,
                    fontWeight: FontWeight.w700,
                    color: LumiColors.onPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: LumiSpacing.sm),
                Text(
                  '正在從衣櫥中尋找相似款式...',
                  style: TextStyle(
                    fontSize: LumiTypeScale.labelMd,
                    color: LumiColors.onPrimary,
                    height: 1.5,
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

class _SonarRing extends StatelessWidget {
  const _SonarRing({required this.value});
  final double value; // 0.0 → 1.0，循環

  @override
  Widget build(BuildContext context) {
    final diameter = value * 200;
    final opacity = (0.70 * (1 - value)).clamp(0.0, 0.70);
    return SizedBox(
      width: diameter,
      height: diameter,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: LumiColors.glow.withValues(alpha: opacity),
            width: 2,
          ),
        ),
      ),
    );
  }
}

// ── 比對結果（≥50%）：上新品 / 下衣櫥相似可滑動 ──────────────────────────────

class _CompareView extends StatefulWidget {
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
  State<_CompareView> createState() => _CompareViewState();
}

class _CompareViewState extends State<_CompareView> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.sizeOf(context).height;
    final newItemH = (screenH * 0.24).clamp(160.0, 210.0);
    final matchH = (screenH * 0.32).clamp(220.0, 290.0);

    final topPct =
        (widget.topMatches.first.similarity * 100).toStringAsFixed(0);
    final accentColor =
        widget.isHighSimilarity ? LumiColors.warning : LumiColors.primary;
    final bannerText = widget.isHighSimilarity
        ? '衣櫥已有 $topPct% 相似款，確認再入手！'
        : '衣櫥有 $topPct% 相似款，可以再比較看看。';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 上：新品照片 ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LumiSpacing.md, LumiSpacing.md, LumiSpacing.md, 0,
          ),
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
                  width: double.infinity,
                  height: newItemH,
                  child: Image.memory(
                    widget.newImageBytes,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: LumiSpacing.md),

        // ── 下：標籤 + 頁碼 ────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '衣櫥最相似',
                style: TextStyle(
                  fontSize: LumiTypeScale.labelMd,
                  color: LumiColors.subtext,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (widget.topMatches.length > 1)
                Text(
                  '${_currentPage + 1} / ${widget.topMatches.length}',
                  style: const TextStyle(
                    fontSize: LumiTypeScale.labelMd,
                    color: LumiColors.subtext,
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: LumiSpacing.sm),

        // ── 下：相似衣物可左右滑動卡片 ─────────────────────────────────────
        SizedBox(
          height: matchH,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.topMatches.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) {
              final item = widget.topMatches[i];
              final itemPct =
                  (item.similarity * 100).toStringAsFixed(0);
              final badgeColor = item.similarity >= 0.8
                  ? LumiColors.warning
                  : LumiColors.primary;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LumiSpacing.md,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(LumiRadii.lg),
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
                          height: 88,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                LumiColors.text.withValues(alpha: 0.70),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Category label
                      if (item.category.isNotEmpty)
                        Positioned(
                          bottom: LumiSpacing.md,
                          left: LumiSpacing.md,
                          right: 80,
                          child: Text(
                            item.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: LumiTypeScale.titleSm,
                              fontWeight: FontWeight.w700,
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
                            color: badgeColor,
                            borderRadius:
                                BorderRadius.circular(LumiRadii.pill),
                          ),
                          child: Text(
                            '$itemPct% 相似',
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
            },
          ),
        ),

        // ── 分頁指示點 ───────────────────────────────────────────────────────
        if (widget.topMatches.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: LumiSpacing.sm),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.topMatches.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(LumiRadii.pill),
                      color: active
                          ? LumiColors.primary
                          : LumiColors.subtext.withValues(alpha: 0.30),
                    ),
                  );
                }),
              ),
            ),
          ),

        const Spacer(),

        // ── 摘要橫幅 + 雙按鈕 ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LumiSpacing.md, 0, LumiSpacing.md, LumiSpacing.lg,
          ),
          child: Column(
            children: [
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
              const SizedBox(height: LumiSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onReset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: LumiColors.text,
                        side: const BorderSide(color: LumiColors.subtext),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(LumiRadii.pill),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: LumiSpacing.md,
                        ),
                      ),
                      child: const Text('已經有了'),
                    ),
                  ),
                  const SizedBox(width: LumiSpacing.sm),
                  Expanded(
                    child: _PrimaryButton(
                      label: '加入新品',
                      onTap: widget.onAdd,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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
          child: Icon(
            Icons.checkroom_outlined,
            color: LumiColors.subtext,
            size: 36,
          ),
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
              child: Icon(
                Icons.checkroom_outlined,
                color: LumiColors.subtext,
                size: 36,
              ),
            ),
          );
        }
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const ColoredBox(
            color: LumiColors.surface,
            child: Center(
              child: Icon(
                Icons.checkroom_outlined,
                color: LumiColors.subtext,
                size: 36,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── 無相似 ────────────────────────────────────────────────────────────────────

class _NoneView extends StatelessWidget {
  const _NoneView({required this.onDone});
  final VoidCallback onDone;

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
              fontSize: LumiTypeScale.labelMd,
              color: LumiColors.subtext,
              height: 1.6,
            ),
          ),
          const Spacer(),
          _PrimaryButton(label: '返回衣櫥', onTap: onDone),
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
