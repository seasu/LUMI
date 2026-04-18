import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../domain/ootd_state.dart';
import 'providers/ootd_provider.dart';

class OotdAddPage extends ConsumerStatefulWidget {
  const OotdAddPage({super.key});

  @override
  ConsumerState<OotdAddPage> createState() => _OotdAddPageState();
}

class _OotdAddPageState extends ConsumerState<OotdAddPage> {
  final _captionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Immediately open the camera/picker when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ootdAddProvider.notifier).pickPhoto();
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ootdAddProvider);

    ref.listen<OotdAddState>(ootdAddProvider, (_, next) {
      if (next is OotdAddEditing &&
          _captionController.text != next.caption) {
        _captionController.text = next.caption;
      }
    });

    return PopScope(
      canPop: state is! OotdAddSaving,
      onPopInvoked: (didPop) {
        if (didPop) ref.read(ootdAddProvider.notifier).reset();
      },
      child: switch (state) {
        OotdAddIdle() => _PickingView(
            onClose: () {
              ref.read(ootdAddProvider.notifier).reset();
              context.pop();
            },
          ),
        OotdAddEditing(:final photoBytes, :final date) => _EditView(
            photoBytes: photoBytes,
            date: date,
            captionController: _captionController,
            onCaptionChanged: (v) =>
                ref.read(ootdAddProvider.notifier).updateCaption(v),
            onRetake: () => ref.read(ootdAddProvider.notifier).retake(),
            onSave: () => ref.read(ootdAddProvider.notifier).save(),
          ),
        OotdAddSaving() => const _SavingView(),
        OotdAddResult(:final photoBytes) => _ResultView(
            photoBytes: photoBytes,
            onBack: () {
              ref.read(ootdAddProvider.notifier).reset();
              context.go('/home/outfits');
            },
          ),
        OotdAddError(:final message) => _ErrorView(
            message: message,
            onBack: () {
              ref.read(ootdAddProvider.notifier).reset();
              context.pop();
            },
          ),
      },
    );
  }
}

// ── 選取中（等待 image_picker）────────────────────────────────────────────────

class _PickingView extends StatelessWidget {
  const _PickingView({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumiColors.overlayDark,
      body: SafeArea(
        child: Stack(
          children: [
            const Center(
              child: CircularProgressIndicator(color: LumiColors.onPrimary),
            ),
            Positioned(
              top: LumiSpacing.md,
              left: LumiSpacing.xs,
              child: IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close,
                    color: LumiColors.onPrimary, size: 28),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 編輯 + 儲存 ───────────────────────────────────────────────────────────────

class _EditView extends StatelessWidget {
  const _EditView({
    required this.photoBytes,
    required this.date,
    required this.captionController,
    required this.onCaptionChanged,
    required this.onRetake,
    required this.onSave,
  });

  final Uint8List photoBytes;
  final DateTime date;
  final TextEditingController captionController;
  final ValueChanged<String> onCaptionChanged;
  final VoidCallback onRetake;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: LumiColors.base,
      appBar: AppBar(
        backgroundColor: LumiColors.base,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          children: [
            const Text(
              '今日穿搭',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: LumiColors.text,
              ),
            ),
            Text(
              dateStr,
              style: const TextStyle(fontSize: 12, color: LumiColors.subtext),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(LumiSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo card
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 420),
                decoration: BoxDecoration(
                  color: LumiColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.memory(photoBytes, fit: BoxFit.cover),
              ),
              const SizedBox(height: LumiSpacing.md),
              // Caption
              const Text(
                '穿搭備註',
                style: TextStyle(
                  fontSize: 13,
                  color: LumiColors.subtext,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: LumiSpacing.xs),
              TextField(
                controller: captionController,
                onChanged: onCaptionChanged,
                decoration: const InputDecoration(
                  hintText: '記錄今天的穿搭心情...',
                  hintStyle:
                      TextStyle(color: LumiColors.subtext, fontSize: 14),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 15, color: LumiColors.text),
                maxLines: 3,
              ),
              const SizedBox(height: LumiSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: onRetake,
                  child: const Text(
                    '重新拍攝',
                    style: TextStyle(
                      fontSize: 15,
                      color: LumiColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: LumiSpacing.sm),
              _PrimaryButton(label: '儲存穿搭', onTap: onSave),
              const SizedBox(height: LumiSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 儲存中 ────────────────────────────────────────────────────────────────────

class _SavingView extends StatelessWidget {
  const _SavingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: LumiColors.base,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: LumiColors.primary),
            SizedBox(height: LumiSpacing.md),
            Text(
              '正在儲存穿搭...',
              style: TextStyle(fontSize: 15, color: LumiColors.subtext),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 結果 + 分享 ───────────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  const _ResultView({required this.photoBytes, required this.onBack});

  final Uint8List photoBytes;
  final VoidCallback onBack;

  Future<void> _share(BuildContext context) async {
    try {
      await Share.shareXFiles(
        [
          XFile.fromData(
            photoBytes,
            mimeType: 'image/jpeg',
            name: 'lumi_ootd.jpg',
          )
        ],
        subject: '我的 Lumi 穿搭',
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('此裝置不支援分享功能')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}年${now.month.toString().padLeft(2, '0')}月${now.day.toString().padLeft(2, '0')}日';

    return Scaffold(
      backgroundColor: LumiColors.overlayDark,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Share card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.xl),
              child: Container(
                decoration: BoxDecoration(
                  color: LumiColors.surface,
                  borderRadius: BorderRadius.circular(24),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Image.memory(
                      photoBytes,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                    Positioned(
                      bottom: LumiSpacing.md,
                      right: LumiSpacing.md,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Lumi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w300,
                              fontStyle: FontStyle.italic,
                              color: LumiColors.onPrimary,
                              shadows: [
                                Shadow(
                                  color:
                                      LumiColors.text.withOpacity(0.45),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 10,
                              color: LumiColors.onPrimary.withOpacity(0.72),
                              shadows: [
                                Shadow(
                                  color:
                                      LumiColors.text.withOpacity(0.45),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: LumiSpacing.lg),
            Text(
              '分享一段話吧...',
              style: TextStyle(
                fontSize: 16,
                color: LumiColors.onPrimary.withOpacity(0.72),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: LumiSpacing.md),
              child: _PrimaryButton(
                label: '分享穿搭',
                onTap: () => _share(context),
              ),
            ),
            const SizedBox(height: LumiSpacing.sm),
            TextButton(
              onPressed: onBack,
              child: Text(
                '回到我的穿搭',
                style: TextStyle(
                  fontSize: 15,
                  color: LumiColors.onPrimary.withOpacity(0.56),
                ),
              ),
            ),
            const SizedBox(height: LumiSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ── 錯誤 ──────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onBack});
  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LumiColors.base,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(LumiSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(LumiSpacing.md),
                decoration: BoxDecoration(
                  color: LumiColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, color: LumiColors.warning, height: 1.5),
                ),
              ),
              const SizedBox(height: LumiSpacing.lg),
              _PrimaryButton(label: '返回', onTap: onBack),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared button ─────────────────────────────────────────────────────────────

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
              color: LumiColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
