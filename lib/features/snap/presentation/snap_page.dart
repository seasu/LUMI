import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_radii.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../shared/constants/lumi_type_scale.dart';
import '../../purchase/presentation/widgets/paywall_sheet.dart';
import '../../search/domain/wardrobe_filter.dart';
import '../../search/presentation/providers/search_provider.dart';
import '../../user/data/user_repository.dart' show userProfileProvider;
import '../domain/snap_state.dart';
import 'providers/snap_provider.dart';

class SnapPage extends ConsumerStatefulWidget {
  const SnapPage({super.key, this.autoSource});
  final ImageSource? autoSource;

  @override
  ConsumerState<SnapPage> createState() => _SnapPageState();
}

class _SnapPageState extends ConsumerState<SnapPage> {
  bool _pickerTriggered = false;

  @override
  void initState() {
    super.initState();
    // Reset stale state from a previous session so the page always starts idle.
    ref.read(snapProvider.notifier).reset();
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
    final isSaving = snapState is SnapUploading; // hides back button while saving locally
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final remainingQuota = profile?.remainingQuota;
    final isPro = profile?.plan == 'pro';

    ref.listen<SnapState>(snapProvider, (previous, next) {
      if (next is SnapError && next.message == 'quota_exceeded' && mounted) {
        // Reset snap state then show paywall
        ref.read(snapProvider.notifier).reset();
        showPaywallSheet(context);
        return;
      }
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
              remainingQuota: remainingQuota,
              isPro: isPro,
              onUpgrade: () => showPaywallSheet(context),
            ),
          SnapUploading() => const SizedBox.shrink(),
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
    this.remainingQuota,
    this.isPro = false,
    this.onUpgrade,
  });

  final List<XFile> files;
  final VoidCallback onAddMore;
  final void Function(int index) onRemove;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final int? remainingQuota;
  final bool isPro;
  final VoidCallback? onUpgrade;

  static const _maxPhotos = 10;
  static const _quotaWarningThreshold = 5;

  @override
  Widget build(BuildContext context) {
    final canAddMore = files.length < _maxPhotos;
    final showQuotaBanner = !isPro &&
        remainingQuota != null &&
        remainingQuota! <= _quotaWarningThreshold;

    return Column(
      children: [
        // Quota warning banner
        if (showQuotaBanner)
          _QuotaBanner(
            remaining: remainingQuota!,
            onUpgrade: onUpgrade,
          ),
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

// ── 配額警示 Banner ────────────────────────────────────────────────────────────

class _QuotaBanner extends StatelessWidget {
  const _QuotaBanner({required this.remaining, this.onUpgrade});

  final int remaining;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onUpgrade,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          LumiSpacing.md,
          LumiSpacing.sm,
          LumiSpacing.md,
          0,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: LumiSpacing.md,
          vertical: LumiSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: LumiColors.warning.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(LumiRadii.md),
          border: Border.all(
            color: LumiColors.warning.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: LumiColors.warning,
            ),
            const SizedBox(width: LumiSpacing.sm),
            Expanded(
              child: Text(
                remaining == 0
                    ? 'AI 分析配額已用完，加入後無法分析'
                    : 'AI 分析剩餘 $remaining 件，即將用完',
                style: const TextStyle(
                  fontSize: LumiTypeScale.labelMd,
                  color: LumiColors.warning,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onUpgrade != null) ...[
              const SizedBox(width: LumiSpacing.sm),
              const Text(
                '升級 →',
                style: TextStyle(
                  fontSize: LumiTypeScale.labelMd,
                  color: LumiColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
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
