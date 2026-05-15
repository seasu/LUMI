import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_radii.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../shared/constants/lumi_type_scale.dart';
import '../domain/ootd_state.dart';
import 'ootd_share_page.dart';
import 'providers/ootd_provider.dart';

class OotdAddPage extends ConsumerStatefulWidget {
  const OotdAddPage({super.key, this.source = ImageSource.camera});

  final ImageSource source;

  @override
  ConsumerState<OotdAddPage> createState() => _OotdAddPageState();
}

class _OotdAddPageState extends ConsumerState<OotdAddPage> {
  final _captionController = TextEditingController();
  // Persistent FocusNode prevents TextField from losing focus on state rebuilds
  final _captionFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ootdAddProvider.notifier).reset();
      ref.read(ootdAddProvider.notifier).pickPhoto(source: widget.source);
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    _captionFocus.dispose();
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
      onPopInvokedWithResult: (didPop, _) {
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
            captionFocusNode: _captionFocus,
            onCaptionChanged: (v) =>
                ref.read(ootdAddProvider.notifier).updateCaption(v),
            onRetake: () => ref.read(ootdAddProvider.notifier).retake(),
            onSave: () => ref.read(ootdAddProvider.notifier).save(),
          ),
        OotdAddSaving() => const _SavingView(),
        OotdAddResult(:final photoBytes, :final item) => _ResultView(
            photoBytes: photoBytes,
            caption: item.caption,
            date: item.date,
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
    required this.captionFocusNode,
    required this.onCaptionChanged,
    required this.onRetake,
    required this.onSave,
  });

  final Uint8List photoBytes;
  final DateTime date;
  final TextEditingController captionController;
  final FocusNode captionFocusNode;
  final ValueChanged<String> onCaptionChanged;
  final VoidCallback onRetake;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    // Cap photo at 50% of screen height so long images don't push content off
    final maxPhotoHeight = MediaQuery.of(context).size.height * 0.5;

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
                fontSize: LumiTypeScale.titleSm,
                fontWeight: FontWeight.w700,
                color: LumiColors.text,
              ),
            ),
            Text(
              dateStr,
              style: const TextStyle(
                  fontSize: LumiTypeScale.labelSm, color: LumiColors.subtext),
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
              // Photo card – explicit SizedBox keeps height bounded
              SizedBox(
                width: double.infinity,
                height: maxPhotoHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: LumiColors.surface,
                    borderRadius: BorderRadius.circular(LumiRadii.xl),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.memory(photoBytes, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: LumiSpacing.md),
              const Text(
                '穿搭備註',
                style: TextStyle(
                  fontSize: LumiTypeScale.labelMd,
                  color: LumiColors.subtext,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: LumiSpacing.xs),
              TextField(
                controller: captionController,
                focusNode: captionFocusNode,
                onChanged: onCaptionChanged,
                decoration: const InputDecoration(
                  hintText: '記錄今天的穿搭心情...',
                  hintStyle: TextStyle(
                      color: LumiColors.subtext,
                      fontSize: LumiTypeScale.labelMd),
                  border: InputBorder.none,
                ),
                style: const TextStyle(
                    fontSize: LumiTypeScale.body, color: LumiColors.text),
                maxLines: 3,
              ),
              const SizedBox(height: LumiSpacing.lg),
              Center(
                child: TextButton(
                  onPressed: onRetake,
                  child: const Text(
                    '重新拍攝',
                    style: TextStyle(
                      fontSize: LumiTypeScale.body,
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
              style: TextStyle(
                  fontSize: LumiTypeScale.body, color: LumiColors.subtext),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 結果：儲存成功預覽 ────────────────────────────────────────────────────────

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.photoBytes,
    required this.caption,
    required this.date,
    required this.onBack,
  });

  final Uint8List photoBytes;
  final String caption;
  final DateTime date;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${date.year}年${date.month.toString().padLeft(2, '0')}月${date.day.toString().padLeft(2, '0')}日';

    final screenW = MediaQuery.of(context).size.width;
    final cardW = screenW - LumiSpacing.xl * 2;
    final cardH = cardW * 4 / 3;

    return Scaffold(
      backgroundColor: LumiColors.base,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LumiSpacing.lg,
                LumiSpacing.md,
                LumiSpacing.lg,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      gradient: LumiColors.buttonGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 18,
                      color: LumiColors.onPrimary,
                    ),
                  ),
                  const SizedBox(width: LumiSpacing.sm),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '穿搭已儲存',
                          style: TextStyle(
                            fontSize: LumiTypeScale.titleLg,
                            fontWeight: FontWeight.w700,
                            color: LumiColors.text,
                          ),
                        ),
                        Text(
                          '今日風格記錄完成',
                          style: TextStyle(
                            fontSize: LumiTypeScale.labelSm,
                            color: LumiColors.subtext,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Date chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: LumiSpacing.sm,
                      vertical: LumiSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: LumiColors.primaryFixed,
                      borderRadius: BorderRadius.circular(LumiRadii.pill),
                    ),
                    child: Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: LumiTypeScale.labelSm,
                        color: LumiColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: LumiSpacing.md),

            // ── Card preview ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: LumiSpacing.xl),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(LumiRadii.xl),
                      child: SizedBox(
                        width: cardW,
                        height: cardH,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(
                              photoBytes,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: Container(
                                height: cardH * 0.38,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      LumiColors.text.withValues(alpha: 0.0),
                                      LumiColors.text.withValues(alpha: 0.52),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (caption.isNotEmpty)
                              Positioned(
                                left: LumiSpacing.md,
                                right: LumiSpacing.md,
                                bottom: LumiSpacing.xl + LumiSpacing.md,
                                child: Text(
                                  caption,
                                  style: const TextStyle(
                                    fontSize: LumiTypeScale.body,
                                    color: LumiColors.onPrimary,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            Positioned(
                              bottom: LumiSpacing.md,
                              right: LumiSpacing.md,
                              child: Text(
                                'Lumi',
                                style: TextStyle(
                                  fontSize: LumiTypeScale.titleSm,
                                  fontWeight: FontWeight.w300,
                                  fontStyle: FontStyle.italic,
                                  color: LumiColors.onPrimary
                                      .withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: LumiSpacing.lg),
                  ],
                ),
              ),
            ),

            // ── Actions ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LumiSpacing.md,
                0,
                LumiSpacing.md,
                LumiSpacing.md,
              ),
              child: Column(
                children: [
                  _PrimaryButton(
                    label: '分享穿搭',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => OotdSharePage(
                          photoBytes: photoBytes,
                          caption: caption,
                          date: date,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: LumiSpacing.xs),
                  TextButton(
                    onPressed: onBack,
                    child: const Text(
                      '完成，回到穿搭記錄',
                      style: TextStyle(
                        fontSize: LumiTypeScale.body,
                        color: LumiColors.subtext,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                  color: LumiColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(LumiRadii.lg),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: LumiTypeScale.labelMd,
                      color: LumiColors.warning,
                      height: 1.5),
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
