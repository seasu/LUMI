import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../shared/constants/lumi_colors.dart';
import '../../../shared/constants/lumi_radii.dart';
import '../../../shared/constants/lumi_spacing.dart';
import '../../../shared/constants/lumi_type_scale.dart';
import '../domain/ootd_state.dart';
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
            initialCaption: item.caption,
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

// ── 結果 + 分享（互動式畫布）─────────────────────────────────────────────────

class _ResultView extends StatefulWidget {
  const _ResultView({
    required this.photoBytes,
    required this.onBack,
    this.initialCaption = '',
  });

  final Uint8List photoBytes;
  final VoidCallback onBack;
  final String initialCaption;

  @override
  State<_ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends State<_ResultView> {
  late final _captionController =
      TextEditingController(text: widget.initialCaption);
  final _cardKey = GlobalKey();
  final _captionFocus = FocusNode();

  // Photo transform state
  double _photoScale = 1.0;
  double _photoRotation = 0.0;
  double _baseScale = 1.0;
  double _baseRotation = 0.0;

  // Draggable text position (initialised lazily in build)
  Offset? _textPos;

  @override
  void dispose() {
    _captionController.dispose();
    _captionFocus.dispose();
    super.dispose();
  }

  void _onPhotoScaleStart(ScaleStartDetails _) {
    _baseScale = _photoScale;
    _baseRotation = _photoRotation;
  }

  void _onPhotoScaleUpdate(ScaleUpdateDetails d) {
    setState(() {
      _photoScale = (_baseScale * d.scale).clamp(0.3, 5.0);
      _photoRotation = _baseRotation + d.rotation;
    });
  }

  // Capture the RepaintBoundary as a PNG and share it
  Future<void> _shareComposed(BuildContext context) async {
    // Dismiss keyboard first so layout is stable before capturing
    _captionFocus.unfocus();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    try {
      final boundary = _cardKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('截圖初始化失敗');

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('截圖轉換失敗');

      final bytes = byteData.buffer.asUint8List();
      final tmp = await getTemporaryDirectory();
      final file = File('${tmp.path}/lumi_ootd_share.png');
      await file.writeAsBytes(bytes);

      if (!mounted) return;
      await Share.shareXFiles([XFile(file.path)], subject: '我的 Lumi 穿搭');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失敗：$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr =
        '${now.year}年${now.month.toString().padLeft(2, '0')}月${now.day.toString().padLeft(2, '0')}日';

    final screenW = MediaQuery.of(context).size.width;
    final cardW = screenW - LumiSpacing.xl * 2;
    final cardH = cardW * 4 / 3; // 3:4 portrait canvas

    // Place text in the lower third on first build
    _textPos ??= Offset(cardW * 0.1, cardH * 0.70);

    final caption = _captionController.text;

    return Scaffold(
      resizeToAvoidBottomInset: false, // keyboard overlays without moving layout
      backgroundColor: LumiColors.overlayDark,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: LumiSpacing.md),

            // ── Interactive share card ──────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: LumiSpacing.xl),
              child: RepaintBoundary(
                key: _cardKey,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(LumiRadii.xl),
                  child: SizedBox(
                    width: cardW,
                    height: cardH,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Dark background
                        const ColoredBox(color: LumiColors.overlayDark),

                        // Photo – pinch to zoom/rotate
                        Positioned.fill(
                          child: GestureDetector(
                            onScaleStart: _onPhotoScaleStart,
                            onScaleUpdate: _onPhotoScaleUpdate,
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..rotateZ(_photoRotation)
                                ..scale(_photoScale),
                              child: Image.memory(
                                widget.photoBytes,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
                        ),

                        // Lumi watermark (fixed bottom-right)
                        Positioned(
                          bottom: LumiSpacing.md,
                          right: LumiSpacing.md,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Lumi',
                                style: TextStyle(
                                  fontSize: LumiTypeScale.titleLg,
                                  fontWeight: FontWeight.w300,
                                  fontStyle: FontStyle.italic,
                                  color: LumiColors.onPrimary,
                                  shadows: [
                                    Shadow(
                                      color: LumiColors.text
                                          .withValues(alpha: 0.5),
                                      blurRadius: 6,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                dateStr,
                                style: TextStyle(
                                  fontSize: LumiTypeScale.labelSm,
                                  color: LumiColors.onPrimary
                                      .withValues(alpha: 0.72),
                                  shadows: [
                                    Shadow(
                                      color: LumiColors.text
                                          .withValues(alpha: 0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Draggable caption overlay
                        if (caption.isNotEmpty)
                          Positioned(
                            left: _textPos!.dx,
                            top: _textPos!.dy,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: (d) {
                                setState(() {
                                  _textPos = Offset(
                                    (_textPos!.dx + d.delta.dx)
                                        .clamp(0.0, cardW - 60),
                                    (_textPos!.dy + d.delta.dy)
                                        .clamp(0.0, cardH - 40),
                                  );
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: LumiSpacing.sm,
                                  vertical: LumiSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: LumiColors.overlayDark
                                      .withValues(alpha: 0.45),
                                  borderRadius:
                                      BorderRadius.circular(LumiRadii.sm),
                                ),
                                constraints:
                                    BoxConstraints(maxWidth: cardW * 0.78),
                                child: Text(
                                  caption,
                                  style: const TextStyle(
                                    fontSize: LumiTypeScale.body,
                                    color: LumiColors.onPrimary,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Caption input ───────────────────────────────────────────
            const SizedBox(height: LumiSpacing.md),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: LumiSpacing.xl),
              child: TextField(
                controller: _captionController,
                focusNode: _captionFocus,
                onChanged: (_) => setState(() {}),
                textAlign: TextAlign.center,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _captionFocus.unfocus(),
                style: TextStyle(
                  fontSize: LumiTypeScale.body,
                  color: LumiColors.onPrimary.withValues(alpha: 0.9),
                ),
                decoration: InputDecoration(
                  hintText: '在照片上加一段話...',
                  hintStyle: TextStyle(
                    fontSize: LumiTypeScale.body,
                    color: LumiColors.onPrimary.withValues(alpha: 0.45),
                  ),
                  border: InputBorder.none,
                ),
                maxLines: 2,
                minLines: 1,
              ),
            ),

            const Spacer(),

            // ── Actions ─────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: LumiSpacing.md),
              child: _PrimaryButton(
                label: '分享穿搭',
                onTap: () => _shareComposed(context),
              ),
            ),
            const SizedBox(height: LumiSpacing.sm),
            TextButton(
              onPressed: widget.onBack,
              child: Text(
                '回到我的穿搭',
                style: TextStyle(
                  fontSize: LumiTypeScale.body,
                  color: LumiColors.onPrimary.withValues(alpha: 0.56),
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
