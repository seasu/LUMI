import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../domain/snap_state.dart';
import 'providers/snap_provider.dart';

class SnapPage extends ConsumerStatefulWidget {
  const SnapPage({super.key});

  @override
  ConsumerState<SnapPage> createState() => _SnapPageState();
}

class _SnapPageState extends ConsumerState<SnapPage>
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
    final snapState = ref.watch(snapProvider);
    final isProcessing =
        snapState is SnapAnalyzing || snapState is SnapUploading;

    return Scaffold(
      backgroundColor: LumiColors.base,
      appBar: AppBar(
        backgroundColor: LumiColors.base,
        elevation: 0,
        leading: IconButton(
          onPressed: isProcessing ? null : () => context.pop(),
          icon: const Icon(Icons.close, color: LumiColors.text),
        ),
        title: const Text(
          'Lumi Snap',
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
          child: switch (snapState) {
            SnapIdle() => _IdleView(onSnap: _startSnap),
            SnapAnalyzing() => _GlowView(
                animation: _glowAnimation,
                label: 'AI 分析中…',
              ),
            SnapUploading() => _GlowView(
                animation: _glowAnimation,
                label: '上傳至 Google Photos…',
              ),
            SnapDone(:final category, :final colors, :final materials) =>
              _DoneView(
                category: category,
                colors: colors,
                materials: materials,
                onReset: _reset,
              ),
            SnapError(:final message) => _ErrorView(
                message: message,
                onRetry: _startSnap,
              ),
          },
        ),
      ),
    );
  }

  void _startSnap() => ref.read(snapProvider.notifier).snap();
  void _reset() => ref.read(snapProvider.notifier).reset();
}

// ── Idle ──────────────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onSnap});

  final VoidCallback onSnap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        const Text(
          '拍攝衣物照片',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: LumiColors.text,
          ),
        ),
        const SizedBox(height: LumiSpacing.sm),
        const Text(
          'AI 將自動辨識類別、顏色與材質',
          style: TextStyle(
            fontSize: 15,
            color: LumiColors.subtext,
            height: 1.5,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onSnap,
            style: FilledButton.styleFrom(
              backgroundColor: LumiColors.accent,
              foregroundColor: LumiColors.surface,
              padding: const EdgeInsets.symmetric(vertical: LumiSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text(
              '開始拍照',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(height: LumiSpacing.xl),
      ],
    );
  }
}

// ── Glow (Analyzing / Uploading) ──────────────────────────────────────────────

class _GlowView extends StatelessWidget {
  const _GlowView({required this.animation, required this.label});

  final Animation<double> animation;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LumiColors.glow
                      .withOpacity(0.3 + animation.value * 0.7),
                ),
              );
            },
          ),
          const SizedBox(height: LumiSpacing.lg),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: LumiColors.subtext,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Done ──────────────────────────────────────────────────────────────────────

class _DoneView extends StatelessWidget {
  const _DoneView({
    required this.category,
    required this.colors,
    required this.materials,
    required this.onReset,
  });

  final String category;
  final List<String> colors;
  final List<String> materials;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '入庫完成',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: LumiColors.text,
                ),
              ),
              const SizedBox(height: LumiSpacing.md),
              _InfoRow(label: '類別', value: category),
              const SizedBox(height: LumiSpacing.sm),
              _InfoRow(
                label: '材質',
                value: materials.join('、'),
              ),
              const SizedBox(height: LumiSpacing.sm),
              Row(
                children: [
                  const Text(
                    '顏色',
                    style: TextStyle(
                      fontSize: 15,
                      color: LumiColors.subtext,
                    ),
                  ),
                  const SizedBox(width: LumiSpacing.sm),
                  ...colors.map((hex) => _ColorDot(hex: hex)),
                ],
              ),
            ],
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onReset,
            style: FilledButton.styleFrom(
              backgroundColor: LumiColors.accent,
              foregroundColor: LumiColors.surface,
              padding:
                  const EdgeInsets.symmetric(vertical: LumiSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '再拍一件',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(height: LumiSpacing.xl),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: LumiColors.subtext),
        ),
        const SizedBox(width: LumiSpacing.sm),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: LumiColors.text,
          ),
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.hex});

  final String hex;

  @override
  Widget build(BuildContext context) {
    final color = _parseHex(hex);
    return Container(
      width: 20,
      height: 20,
      margin: const EdgeInsets.only(right: LumiSpacing.xs),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Color _parseHex(String hex) {
    final clean = hex.replaceAll('#', '');
    final value = int.tryParse('FF$clean', radix: 16);
    return value != null ? Color(value) : LumiColors.subtext;
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
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: LumiColors.accent,
              foregroundColor: LumiColors.surface,
              padding:
                  const EdgeInsets.symmetric(vertical: LumiSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '重試',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
