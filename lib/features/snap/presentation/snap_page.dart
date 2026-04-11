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
    final isUploading = snapState is SnapUploading;

    return Scaffold(
      backgroundColor: LumiColors.base,
      appBar: AppBar(
        backgroundColor: LumiColors.base,
        elevation: 0,
        leading: IconButton(
          onPressed: isUploading ? null : () => context.pop(),
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
            SnapIdle() => _IdleView(
                onPick: () => ref.read(snapProvider.notifier).pickImages(),
              ),
            SnapPreviewing(:final files) => _PreviewView(
                files: files,
                onRemove: (i) =>
                    ref.read(snapProvider.notifier).removeFile(i),
                onAddMore: () => ref.read(snapProvider.notifier).pickImages(),
                onUpload: () => ref.read(snapProvider.notifier).uploadAll(),
              ),
            SnapUploading(:final current, :final total) => _UploadingView(
                animation: _glowAnimation,
                current: current,
                total: total,
              ),
            SnapDone(:final count) => _DoneView(
                count: count,
                onBack: () => context.pop(),
                onMore: () => ref.read(snapProvider.notifier).reset(),
              ),
            SnapError(:final message) => _ErrorView(
                message: message,
                onRetry: () => ref.read(snapProvider.notifier).reset(),
              ),
          },
        ),
      ),
    );
  }
}

// ── Idle ──────────────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onPick});

  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        const Icon(
          Icons.photo_library_outlined,
          size: 64,
          color: LumiColors.glow,
        ),
        const SizedBox(height: LumiSpacing.lg),
        const Text(
          '從相簿選取照片',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w500,
            color: LumiColors.text,
          ),
        ),
        const SizedBox(height: LumiSpacing.sm),
        const Text(
          '一次最多 10 張，AI 會在背景自動分析\n上傳完成後可以關閉此頁面',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: LumiColors.subtext,
            height: 1.6,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onPick,
            style: FilledButton.styleFrom(
              backgroundColor: LumiColors.accent,
              foregroundColor: LumiColors.surface,
              padding: const EdgeInsets.symmetric(vertical: LumiSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text(
              '選取照片',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(height: LumiSpacing.xl),
      ],
    );
  }
}

// ── Preview grid ──────────────────────────────────────────────────────────────

class _PreviewView extends StatelessWidget {
  const _PreviewView({
    required this.files,
    required this.onRemove,
    required this.onAddMore,
    required this.onUpload,
  });

  final List<XFile> files;
  final void Function(int index) onRemove;
  final VoidCallback onAddMore;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final canAddMore = files.length < 10;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: LumiSpacing.md),
        Text(
          '已選 ${files.length} 張',
          style: const TextStyle(
            fontSize: 15,
            color: LumiColors.subtext,
          ),
        ),
        const SizedBox(height: LumiSpacing.sm),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: LumiSpacing.xs,
              mainAxisSpacing: LumiSpacing.xs,
              childAspectRatio: 1,
            ),
            itemCount: files.length + (canAddMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == files.length) {
                return _AddMoreTile(onTap: onAddMore);
              }
              return _PreviewTile(
                file: files[index],
                onRemove: () => onRemove(index),
              );
            },
          ),
        ),
        const SizedBox(height: LumiSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onUpload,
            style: FilledButton.styleFrom(
              backgroundColor: LumiColors.accent,
              foregroundColor: LumiColors.surface,
              padding:
                  const EdgeInsets.symmetric(vertical: LumiSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              '上傳 ${files.length} 張照片',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: LumiSpacing.xl),
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
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _bytes == null
              ? const ColoredBox(color: LumiColors.surface)
              : Image.memory(_bytes!, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: widget.onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddMoreTile extends StatelessWidget {
  const _AddMoreTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: LumiColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: LumiColors.glow,
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.add_photo_alternate_outlined,
          color: LumiColors.subtext,
          size: 28,
        ),
      ),
    );
  }
}

// ── Uploading ─────────────────────────────────────────────────────────────────

class _UploadingView extends StatelessWidget {
  const _UploadingView({
    required this.animation,
    required this.current,
    required this.total,
  });

  final Animation<double> animation;
  final int current;
  final int total;

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
          Text(
            current == 0 ? '正在取得授權…' : '上傳第 $current / $total 張…',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: LumiColors.text,
            ),
          ),
          const SizedBox(height: LumiSpacing.sm),
          Text(
            current == 0 ? '請在彈出視窗中允許 Google Photos 存取' : '請保持頁面開啟',
            style: const TextStyle(fontSize: 13, color: LumiColors.subtext),
          ),
        ],
      ),
    );
  }
}

// ── Done ──────────────────────────────────────────────────────────────────────

class _DoneView extends StatelessWidget {
  const _DoneView({
    required this.count,
    required this.onBack,
    required this.onMore,
  });

  final int count;
  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        const Icon(
          Icons.cloud_done_outlined,
          size: 64,
          color: LumiColors.accent,
        ),
        const SizedBox(height: LumiSpacing.lg),
        Text(
          '$count 張照片已加入衣櫥',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: LumiColors.text,
          ),
        ),
        const SizedBox(height: LumiSpacing.sm),
        const Text(
          'AI 正在背景分析，完成後衣櫥會自動更新\n現在可以關閉此頁面',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: LumiColors.subtext,
            height: 1.6,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onBack,
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
              '回到衣櫥',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(height: LumiSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onMore,
            style: OutlinedButton.styleFrom(
              foregroundColor: LumiColors.accent,
              side: const BorderSide(color: LumiColors.accent),
              padding:
                  const EdgeInsets.symmetric(vertical: LumiSpacing.md),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              '繼續新增',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
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
              '重新選取',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
