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
      duration: const Duration(milliseconds: 1200),
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
        leading: IconButton(
          onPressed: isAnalyzing ? null : () => context.pop(),
          icon: const Icon(Icons.close, color: LumiColors.text),
        ),
        title: const Text(
          'Lumi-Check',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: LumiColors.text,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.md),
          child: switch (state) {
            CheckIdle() => _IdleView(
                onCheck: () => ref.read(checkProvider.notifier).check(),
              ),
            CheckAnalyzing() => _GlowView(animation: _glowAnimation),
            CheckHighSimilarity(
              :final similarity,
              :final matchedThumbnailUrl,
              :final matchedCategory,
              :final newImageBytes,
            ) =>
              _HighSimilarityView(
                similarity: similarity,
                matchedThumbnailUrl: matchedThumbnailUrl,
                matchedCategory: matchedCategory,
                newImageBytes: Uint8List.fromList(newImageBytes),
                onReset: () => ref.read(checkProvider.notifier).reset(),
              ),
            CheckMediumSimilarity(
              :final similarity,
              :final matchedCategory,
            ) =>
              _MediumSimilarityView(
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
      ),
    );
  }
}

// ── Idle ──────────────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onCheck});

  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        const Text(
          '購物前先查重',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: LumiColors.text,
          ),
        ),
        const SizedBox(height: LumiSpacing.sm),
        const Text(
          '拍下你想買的衣物，\nLumi 會比對你的衣櫥是否已有相似款。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: LumiColors.subtext,
            height: 1.5,
          ),
        ),
        const Spacer(),
        _ActionButton(label: '拍照比對', onPressed: onCheck),
        const SizedBox(height: LumiSpacing.xl),
      ],
    );
  }
}

// ── Glow ──────────────────────────────────────────────────────────────────────

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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: LumiColors.glow
                    .withOpacity(0.3 + animation.value * 0.7),
              ),
            ),
          ),
          const SizedBox(height: LumiSpacing.lg),
          const Text(
            'AI 比對中…',
            style: TextStyle(fontSize: 15, color: LumiColors.subtext),
          ),
        ],
      ),
    );
  }
}

// ── High similarity (≥ 80%) ───────────────────────────────────────────────────

class _HighSimilarityView extends StatelessWidget {
  const _HighSimilarityView({
    required this.similarity,
    required this.matchedThumbnailUrl,
    required this.matchedCategory,
    required this.newImageBytes,
    required this.onReset,
  });

  final double similarity;
  final String matchedThumbnailUrl;
  final String matchedCategory;
  final Uint8List newImageBytes;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final pct = (similarity * 100).toStringAsFixed(0);

    return Column(
      children: [
        const SizedBox(height: LumiSpacing.md),
        // Warning banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: LumiSpacing.md,
            vertical: LumiSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                LumiColors.warning.withOpacity(0.15),
                LumiColors.warning.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: LumiColors.warning, size: 20),
              const SizedBox(width: LumiSpacing.sm),
              Expanded(
                child: Text(
                  '衣櫥中有 $pct% 相似的$matchedCategory',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: LumiColors.warning,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LumiSpacing.md),
        // Side-by-side comparison
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _CompareCard(
                  label: '你想買的',
                  child: Image.memory(newImageBytes, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: LumiSpacing.sm),
              Expanded(
                child: _CompareCard(
                  label: '衣櫥裡的',
                  child: Image.network(
                    matchedThumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.image_not_supported_outlined,
                      color: LumiColors.subtext,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: LumiSpacing.md),
        _ActionButton(label: '再比一件', onPressed: onReset),
        const SizedBox(height: LumiSpacing.xl),
      ],
    );
  }
}

class _CompareCard extends StatelessWidget {
  const _CompareCard({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: LumiColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Expanded(child: child),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: LumiSpacing.sm),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: LumiColors.subtext,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Medium similarity (50–79%) ────────────────────────────────────────────────

class _MediumSimilarityView extends StatelessWidget {
  const _MediumSimilarityView({
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

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(LumiSpacing.lg),
          decoration: BoxDecoration(
            color: LumiColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Text(
                '可能相似',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: LumiColors.text,
                ),
              ),
              const SizedBox(height: LumiSpacing.sm),
              Text(
                '衣櫥中有 $pct% 相似的$matchedCategory，\n可以再比較看看。',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: LumiColors.subtext,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        _ActionButton(label: '再比一件', onPressed: onReset),
        const SizedBox(height: LumiSpacing.xl),
      ],
    );
  }
}

// ── None (< 50%) ──────────────────────────────────────────────────────────────

class _NoneView extends StatelessWidget {
  const _NoneView({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        const Text(
          '衣櫥中無相似款式',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: LumiColors.text,
          ),
        ),
        const SizedBox(height: LumiSpacing.sm),
        const Text(
          '這件衣物在你的衣櫥裡找不到相似款。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: LumiColors.subtext,
            height: 1.5,
          ),
        ),
        const Spacer(),
        _ActionButton(label: '再比一件', onPressed: onReset),
        const SizedBox(height: LumiSpacing.xl),
      ],
    );
  }
}

// ── Error ─────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
              fontSize: 15,
              color: LumiColors.warning,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: LumiSpacing.lg),
        _ActionButton(label: '重試', onPressed: onRetry),
        const Spacer(),
      ],
    );
  }
}

// ── Shared button ─────────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: LumiColors.accent,
          foregroundColor: LumiColors.surface,
          padding: const EdgeInsets.symmetric(vertical: LumiSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
