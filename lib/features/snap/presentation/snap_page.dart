import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_radii.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../shared/constants/lumi_type_scale.dart';
import '../../search/domain/wardrobe_filter.dart';
import '../../search/presentation/providers/search_provider.dart';
import '../domain/snap_state.dart';
import 'providers/snap_provider.dart';

class SnapPage extends ConsumerStatefulWidget {
  const SnapPage({super.key, this.autoSource});
  final ImageSource? autoSource;

  @override
  ConsumerState<SnapPage> createState() => _SnapPageState();
}

class _SnapPageState extends ConsumerState<SnapPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;
  bool _pickerTriggered = false;

  @override
  void initState() {
    super.initState();
    // Reset stale state from a previous session so the page always starts idle.
    ref.read(snapProvider.notifier).reset();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
    if (widget.autoSource != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _pickerTriggered = true;
        if (widget.autoSource == ImageSource.camera) {
          ref.read(snapProvider.notifier).takePhoto();
        } else {
          ref.read(snapProvider.notifier).pickImages();
        }
      });
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _popToWardrobeUncategorized() {
    ref.read(snapProvider.notifier).reset();
    ref.read(wardrobeFilterProvider.notifier).setCategory(
          WardrobeFilter.uncategorizedOnly,
        );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final snapState = ref.watch(snapProvider);
    final isSaving = snapState is SnapUploading;

    ref.listen<SnapState>(snapProvider, (previous, next) {
      if (next is SnapDone && mounted) {
        final messenger = ScaffoldMessenger.of(context);
        final label = next.count == 1 ? '已成功加入 1 件衣物' : '已成功加入 ${next.count} 件衣物';
        _popToWardrobeUncategorized();
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: LumiColors.onPrimary,
                  size: 18,
                ),
                const SizedBox(width: LumiSpacing.xs),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: LumiTypeScale.body,
                    fontWeight: FontWeight.w600,
                    color: LumiColors.onPrimary,
                  ),
                ),
              ],
            ),
            backgroundColor: LumiColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(LumiRadii.pill),
            ),
            margin: const EdgeInsets.fromLTRB(
              LumiSpacing.xl,
              0,
              LumiSpacing.xl,
              LumiSpacing.xl,
            ),
            duration: const Duration(seconds: 3),
            elevation: 0,
          ),
        );
      }
      // When launched with autoSource and user cancels the picker,
      // state returns to idle — pop back to avoid showing the idle UI.
      if (_pickerTriggered &&
          previous is! SnapIdle &&
          next is SnapIdle &&
          mounted) {
        context.pop();
      }
    });

    return Scaffold(
      backgroundColor: LumiColors.base,
      appBar: AppBar(
        backgroundColor: LumiColors.base,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: isSaving
            ? const SizedBox.shrink()
            : IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, color: LumiColors.text),
              ),
        title: Text(
          _appBarTitle(snapState),
          style: const TextStyle(
            fontSize: LumiTypeScale.titleSm,
            fontWeight: FontWeight.w500,
            color: LumiColors.text,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: switch (snapState) {
          // When arriving with autoSource, the source was already chosen in the
          // bottom sheet — hide the idle UI while the picker is loading.
          SnapIdle() when widget.autoSource != null => const SizedBox.shrink(),
          SnapIdle() => _IdleView(
              onCamera: () => ref.read(snapProvider.notifier).takePhoto(),
              onLibrary: () => ref.read(snapProvider.notifier).pickImages(),
            ),
          SnapPreviewing(:final files) => _PreviewView(
              files: files,
              onAddMore: () => ref.read(snapProvider.notifier).pickImages(),
              onRemove: (i) => ref.read(snapProvider.notifier).removeFile(i),
              onConfirm: () => ref.read(snapProvider.notifier).uploadAll(),
              onCancel: () => ref.read(snapProvider.notifier).reset(),
            ),
          SnapUploading(:final current, :final total) => _SavingView(
              animation: _glowAnimation,
              current: current,
              total: total,
              onCancel: () => _showCancelDialog(context),
            ),
          SnapDone() => const SizedBox.shrink(),
          SnapError(:final message) => _ErrorView(
              message: message,
              onRetry: () => ref.read(snapProvider.notifier).reset(),
            ),
        },
      ),
    );
  }

  String _appBarTitle(SnapState state) => switch (state) {
        SnapIdle() || SnapPreviewing() || SnapError() => '加入新品',
        SnapUploading() => '加入衣櫥中',
        SnapDone() => '加入完成',
      };

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: LumiColors.overlayBarrier,
      builder: (_) => _CancelDialog(
        onContinue: () => Navigator.pop(context),
        onCancel: () {
          Navigator.pop(context);
          ref.read(snapProvider.notifier).reset();
          context.pop();
        },
      ),
    );
  }
}

// ── Idle（入口，選擇來源）──────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onCamera, required this.onLibrary});

  final VoidCallback onCamera;
  final VoidCallback onLibrary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.md),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // Glow orb icon
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: LumiColors.glow.withValues(alpha: 0.18),
                ),
              ),
              const Icon(
                Icons.dry_cleaning_outlined,
                size: 44,
                color: LumiColors.primary,
              ),
            ],
          ),
          const SizedBox(height: LumiSpacing.lg),
          const Text(
            '選擇加入方式',
            style: TextStyle(
              fontSize: LumiTypeScale.titleLg,
              fontWeight: FontWeight.w700,
              color: LumiColors.text,
            ),
          ),
          const SizedBox(height: LumiSpacing.sm),
          const Text(
            '一次最多 10 張，AI 會在背景自動分類',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: LumiTypeScale.labelMd,
              color: LumiColors.subtext,
            ),
          ),
          const Spacer(flex: 3),
          // 主要操作：拍照 + 相簿
          Row(
            children: [
              Expanded(
                child: _SourceButton(
                  icon: Icons.camera_alt_outlined,
                  label: '拍照',
                  onTap: onCamera,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: LumiSpacing.sm),
              Expanded(
                child: _SourceButton(
                  icon: Icons.photo_library_outlined,
                  label: '從相簿選取',
                  onTap: onLibrary,
                  isPrimary: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: LumiSpacing.xl),
        ],
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LumiRadii.pill),
      child: isPrimary
          ? Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LumiColors.buttonGradient,
                borderRadius: BorderRadius.circular(LumiRadii.pill),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: LumiColors.onPrimary, size: 20),
                  const SizedBox(width: LumiSpacing.xs),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: LumiTypeScale.body,
                      fontWeight: FontWeight.w600,
                      color: LumiColors.onPrimary,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(LumiRadii.pill),
                border: Border.all(
                  color: LumiColors.subtext.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: LumiColors.text, size: 20),
                  const SizedBox(width: LumiSpacing.xs),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: LumiTypeScale.body,
                      fontWeight: FontWeight.w600,
                      color: LumiColors.text,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ── 預覽（帶刪除 X + 新增 + 按鈕）──────────────────────────────────────────────

class _PreviewView extends StatelessWidget {
  const _PreviewView({
    required this.files,
    required this.onAddMore,
    required this.onRemove,
    required this.onConfirm,
    required this.onCancel,
  });

  final List<XFile> files;
  final VoidCallback onAddMore;
  final void Function(int index) onRemove;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  static const _maxPhotos = 10;

  @override
  Widget build(BuildContext context) {
    final canAddMore = files.length < _maxPhotos;

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(
              LumiSpacing.md,
              LumiSpacing.sm,
              LumiSpacing.md,
              LumiSpacing.sm,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: LumiSpacing.xs,
              mainAxisSpacing: LumiSpacing.xs,
              childAspectRatio: 1,
            ),
            // +1 tile for "add more" when not at max
            itemCount: canAddMore ? files.length + 1 : files.length,
            itemBuilder: (_, i) {
              if (i == files.length) {
                return _AddMoreTile(onTap: onAddMore);
              }
              return _PreviewTile(
                file: files[i],
                onRemove: () => onRemove(i),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.md),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '已選取 ${files.length} / $_maxPhotos 張',
              style: const TextStyle(
                fontSize: LumiTypeScale.labelMd,
                color: LumiColors.subtext,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LumiSpacing.md,
            LumiSpacing.sm,
            LumiSpacing.md,
            LumiSpacing.xs,
          ),
          child: _PrimaryButton(label: '加入衣櫥', onTap: onConfirm),
        ),
        TextButton(
          onPressed: onCancel,
          child: const Text(
            '取消',
            style: TextStyle(
              fontSize: LumiTypeScale.body,
              color: LumiColors.subtext,
            ),
          ),
        ),
        const SizedBox(height: LumiSpacing.md),
      ],
    );
  }
}

class _PreviewTile extends StatefulWidget {
  const _PreviewTile({required this.file, required this.onRemove});
  final XFile file;
  final VoidCallback onRemove;

  @override
  State<_PreviewTile> createState() => _PreviewTileState();
}

class _PreviewTileState extends State<_PreviewTile> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    widget.file.readAsBytes().then((b) {
      if (mounted) setState(() => _bytes = b);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(LumiRadii.md),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _bytes == null
              ? const ColoredBox(color: LumiColors.surface)
              : Image.memory(_bytes!, fit: BoxFit.cover),
          // X remove button — top-right corner
          Positioned(
            top: LumiSpacing.xs,
            right: LumiSpacing.xs,
            child: GestureDetector(
              onTap: widget.onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: LumiColors.text.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: LumiColors.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddMoreTile extends StatelessWidget {
  const _AddMoreTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(LumiRadii.md),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(LumiRadii.md),
          color: LumiColors.surface,
          border: Border.all(
            color: LumiColors.subtext.withValues(alpha: 0.18),
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 28, color: LumiColors.primary),
            SizedBox(height: LumiSpacing.xs),
            Text(
              '新增',
              style: TextStyle(
                fontSize: LumiTypeScale.labelSm,
                color: LumiColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 加入中（圓形進度 + 光暈）─────────────────────────────────────────────────

class _SavingView extends StatelessWidget {
  const _SavingView({
    required this.animation,
    required this.current,
    required this.total,
    required this.onCancel,
  });

  final Animation<double> animation;
  final int current;
  final int total;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : current / total;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: animation,
            builder: (_, __) {
              return SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: LumiColors.glow.withValues(
                              alpha: 0.25 + animation.value * 0.35,
                            ),
                            blurRadius: 32,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 116,
                      height: 116,
                      child: CircularProgressIndicator(
                        value: progress,
                        color: LumiColors.primary,
                        backgroundColor:
                            LumiColors.primary.withValues(alpha: 0.12),
                        strokeWidth: 6,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: LumiTypeScale.titleLg,
                        fontWeight: FontWeight.w600,
                        color: LumiColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: LumiSpacing.lg),
          const Text(
            '正在加入衣櫥...',
            style: TextStyle(
              fontSize: LumiTypeScale.titleSm,
              fontWeight: FontWeight.w500,
              color: LumiColors.text,
            ),
          ),
          const SizedBox(height: LumiSpacing.sm),
          Text(
            '第 $current / $total 張，完成前請不要關閉此畫面',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: LumiTypeScale.labelMd,
              color: LumiColors.subtext,
            ),
          ),
          const SizedBox(height: LumiSpacing.xl),
          TextButton(
            onPressed: onCancel,
            child: const Text(
              '取消',
              style: TextStyle(
                fontSize: LumiTypeScale.body,
                color: LumiColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 錯誤狀態 ──────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.md),
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
          _PrimaryButton(label: '重新選取', onTap: onRetry),
          const Spacer(),
        ],
      ),
    );
  }
}

// ── 中斷確認 Dialog ───────────────────────────────────────────────────────────

class _CancelDialog extends StatelessWidget {
  const _CancelDialog({
    required this.onContinue,
    required this.onCancel,
  });

  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: LumiColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(LumiRadii.xl),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          LumiSpacing.lg,
          LumiSpacing.lg,
          LumiSpacing.lg,
          LumiSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '確定要中斷嗎？',
              style: TextStyle(
                fontSize: LumiTypeScale.titleSm,
                fontWeight: FontWeight.w600,
                color: LumiColors.text,
              ),
            ),
            const SizedBox(height: LumiSpacing.sm),
            const Text(
              '已加入衣櫥的照片將會保留，\n尚未完成的照片不會加入。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: LumiTypeScale.labelMd,
                color: LumiColors.subtext,
                height: 1.5,
              ),
            ),
            const SizedBox(height: LumiSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LumiColors.subtext,
                      side: BorderSide(
                        color: LumiColors.subtext.withValues(alpha: 0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(LumiRadii.pill),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: LumiSpacing.md,
                      ),
                    ),
                    child: const Text('中斷並退出'),
                  ),
                ),
                const SizedBox(width: LumiSpacing.sm),
                Expanded(
                  child: GestureDetector(
                    onTap: onContinue,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LumiColors.buttonGradient,
                        borderRadius: BorderRadius.circular(LumiRadii.pill),
                      ),
                      child: const Center(
                        child: Text(
                          '繼續加入',
                          style: TextStyle(
                            fontSize: LumiTypeScale.body,
                            fontWeight: FontWeight.w600,
                            color: LumiColors.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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
          gradient: onTap != null ? LumiColors.buttonGradient : null,
          color:
              onTap == null ? LumiColors.primary.withValues(alpha: 0.4) : null,
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
