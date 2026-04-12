import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
    final snapState = ref.watch(snapProvider);
    final isUploading = snapState is SnapUploading;

    return Scaffold(
      backgroundColor: LumiColors.base,
      appBar: AppBar(
        backgroundColor: LumiColors.base,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: isUploading
            ? const SizedBox.shrink()
            : IconButton(
                onPressed: () => context.pop(),
                icon: const Icon(Icons.close, color: LumiColors.text),
              ),
        title: Text(
          _appBarTitle(snapState),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: LumiColors.text,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: switch (snapState) {
          SnapIdle() => _ConfirmView(
              files: const [],
              onPick: () => ref.read(snapProvider.notifier).pickImages(),
            ),
          SnapPreviewing(:final files) => _ConfirmView(
              files: files,
              onPick: () => ref.read(snapProvider.notifier).pickImages(),
              onUpload: () => ref.read(snapProvider.notifier).uploadAll(),
              onCancel: () => ref.read(snapProvider.notifier).reset(),
            ),
          SnapUploading(:final current, :final total) => _UploadingView(
              animation: _glowAnimation,
              current: current,
              total: total,
              onCancel: () => _showCancelDialog(context),
            ),
          SnapDone(:final count) => _DoneView(
              count: count,
              onBack: () {
                ref.read(snapProvider.notifier).reset();
                context.pop();
              },
            ),
          SnapError(:final message) => _ErrorView(
              message: message,
              onRetry: () => ref.read(snapProvider.notifier).reset(),
            ),
        },
      ),
    );
  }

  String _appBarTitle(SnapState state) => switch (state) {
        SnapIdle() || SnapPreviewing() || SnapError() => '確認上傳',
        SnapUploading() => '確認上傳',
        SnapDone() => '上傳完成',
      };

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
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

// ── 確認上傳（含預覽 Grid）────────────────────────────────────────────────────

class _ConfirmView extends StatelessWidget {
  const _ConfirmView({
    required this.files,
    required this.onPick,
    this.onUpload,
    this.onCancel,
  });

  final List<XFile> files;
  final VoidCallback onPick;
  final VoidCallback? onUpload;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final hasFiles = files.isNotEmpty;

    if (!hasFiles) {
      // 空狀態：引導選取
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.md),
        child: Column(
          children: [
            const Spacer(),
            const Icon(
              Icons.photo_library_outlined,
              size: 64,
              color: LumiColors.glow,
            ),
            const SizedBox(height: LumiSpacing.md),
            const Text(
              '選取要加入衣櫥的照片',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: LumiColors.text,
              ),
            ),
            const SizedBox(height: LumiSpacing.sm),
            const Text(
              '一次最多 20 張，AI 會在背景自動分類',
              style: TextStyle(fontSize: 14, color: LumiColors.subtext),
            ),
            const Spacer(),
            _PrimaryButton(label: '選取照片', onTap: onPick),
            const SizedBox(height: LumiSpacing.xl),
          ],
        ),
      );
    }

    // 有照片：Grid 預覽 + 上傳按鈕
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
            itemCount: files.length,
            itemBuilder: (_, i) => _PreviewTile(file: files[i]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            LumiSpacing.md,
            LumiSpacing.sm,
            LumiSpacing.md,
            LumiSpacing.xs,
          ),
          child: _PrimaryButton(
            label: '開始上傳',
            onTap: onUpload,
          ),
        ),
        TextButton(
          onPressed: onCancel,
          child: const Text(
            '取消',
            style: TextStyle(
              fontSize: 15,
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
  const _PreviewTile({required this.file});
  final XFile file;

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
      borderRadius: BorderRadius.circular(8),
      child: _bytes == null
          ? const ColoredBox(color: LumiColors.surface)
          : Image.memory(_bytes!, fit: BoxFit.cover),
    );
  }
}

// ── 上傳中（圓形進度 + 光暈）─────────────────────────────────────────────────

class _UploadingView extends StatelessWidget {
  const _UploadingView({
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
          // 圓形進度條 + 光暈
          AnimatedBuilder(
            animation: animation,
            builder: (_, __) {
              return SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 光暈層
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: LumiColors.glow.withOpacity(
                              0.25 + animation.value * 0.35,
                            ),
                            blurRadius: 32,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    // 進度環
                    CircularProgressIndicator(
                      value: current == 0 ? null : progress,
                      color: LumiColors.primary,
                      backgroundColor:
                          LumiColors.primary.withOpacity(0.12),
                      strokeWidth: 6,
                    ),
                    // 百分比文字
                    if (current > 0)
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 22,
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
          Text(
            current == 0 ? '正在取得授權...' : '正在為妳上傳衣物...',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: LumiColors.text,
            ),
          ),
          const SizedBox(height: LumiSpacing.sm),
          Text(
            current == 0
                ? '請在彈出視窗中允許 Google 相片存取'
                : '第 $current / $total 張，上傳完成前請不要關閉此畫面',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: LumiColors.subtext,
            ),
          ),
          const SizedBox(height: LumiSpacing.xl),
          TextButton(
            onPressed: onCancel,
            child: const Text(
              '取消',
              style: TextStyle(fontSize: 15, color: LumiColors.subtext),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 上傳完成 ──────────────────────────────────────────────────────────────────

class _DoneView extends StatelessWidget {
  const _DoneView({required this.count, required this.onBack});

  final int count;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.md),
      child: Column(
        children: [
          const Spacer(flex: 2),
          // 橘色大勾 + 光暈
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LumiColors.glow.withOpacity(0.15),
              boxShadow: [
                BoxShadow(
                  color: LumiColors.glow.withOpacity(0.3),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 56,
              color: LumiColors.primary,
            ),
          ),
          const SizedBox(height: LumiSpacing.lg),
          const Text(
            '上傳完成！',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: LumiColors.text,
            ),
          ),
          const SizedBox(height: LumiSpacing.sm),
          Text(
            '我們已經上傳完成 $count 張照片！',
            style: const TextStyle(
              fontSize: 15,
              color: LumiColors.text,
            ),
          ),
          const SizedBox(height: LumiSpacing.sm),
          const Text(
            'AI 正在背景為妳進行智慧分類，妳可以先逛逛衣櫥。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: LumiColors.subtext, height: 1.5),
          ),
          const Spacer(flex: 3),
          _PrimaryButton(label: '回到衣櫥', onTap: onBack),
          const SizedBox(height: LumiSpacing.xl),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            LumiSpacing.lg, LumiSpacing.lg, LumiSpacing.lg, LumiSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '確定要中斷上傳嗎？',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: LumiColors.text,
              ),
            ),
            const SizedBox(height: LumiSpacing.sm),
            const Text(
              '已上傳的照片將會保留，未完成的照片不會加入衣櫥。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
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
                      side: const BorderSide(color: LumiColors.subtext),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(
                          vertical: LumiSpacing.md),
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
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Text(
                          '繼續上傳',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
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
          color: onTap == null ? LumiColors.primary.withOpacity(0.4) : null,
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
